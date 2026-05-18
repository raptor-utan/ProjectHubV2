use std::collections::{BTreeMap, HashMap};

use serde_json::{Number, Value};
use sqlx::mysql::MySqlRow;
use sqlx::{FromRow, MySql, MySqlPool, QueryBuilder};

use crate::database_models::models::TableReadModel;
use crate::models::{ApiSpecification, QueryOptions, SearchMode, TablePostRequest, UpsertResult};
use crate::settings::constants::TABLE_NAME_QUERY_PARAM;

#[derive(Debug)]
pub enum TableApiError {
    TableNameMismatch { expected: String, actual: String },
    InvalidColumn(String),
    InvalidRequest(String),
    QueryFailed(sqlx::Error),
}

impl TableApiError {
    pub fn message(&self) -> String {
        match self {
            Self::TableNameMismatch { expected, actual } => {
                format!("table_name が一致しません。expected={expected}, actual={actual}")
            }
            Self::InvalidColumn(column) => {
                format!("許可されていないカラムです: {column}")
            }
            Self::InvalidRequest(message) => message.clone(),
            Self::QueryFailed(error) => {
                format!("データベース操作に失敗しました: {error}")
            }
        }
    }
}

fn is_safe_identifier(identifier: &str) -> bool {
    let mut chars = identifier.chars();
    match chars.next() {
        Some(first) if first.is_ascii_alphabetic() || first == '_' => {}
        _ => return false,
    }

    chars.all(|character| character.is_ascii_alphanumeric() || character == '_')
}

fn allowed_columns<'a>(api_spec: &'a ApiSpecification, table_name: &str) -> Vec<&'a str> {
    api_spec
        .table_endpoints
        .iter()
        .find(|endpoint| endpoint.table_name == table_name)
        .map(|endpoint| {
            endpoint
                .columns
                .iter()
                .map(|column| column.name.as_str())
                .collect::<Vec<_>>()
        })
        .unwrap_or_default()
}

fn ensure_allowed_column(allowed_columns: &[&str], column: &str) -> Result<(), TableApiError> {
    if !is_safe_identifier(column) || !allowed_columns.iter().any(|name| name == &column) {
        return Err(TableApiError::InvalidColumn(column.to_string()));
    }

    Ok(())
}

fn ensure_supported_value(value: &Value, field_name: &str) -> Result<(), TableApiError> {
    match value {
        Value::Null | Value::String(_) | Value::Bool(_) | Value::Number(_) => Ok(()),
        Value::Array(_) | Value::Object(_) => Err(TableApiError::InvalidRequest(format!(
            "{field_name} には文字列・数値・真偽値・null のみ指定できます。"
        ))),
    }
}

fn push_json_value(
    builder: &mut QueryBuilder<'_, MySql>,
    value: &Value,
) -> Result<(), TableApiError> {
    match value {
        Value::Null => {
            builder.push("NULL");
        }
        Value::String(text) => {
            builder.push_bind(text.clone());
        }
        Value::Bool(flag) => {
            builder.push_bind(*flag);
        }
        Value::Number(number) => {
            push_number_value(builder, number)?;
        }
        Value::Array(_) | Value::Object(_) => {
            return Err(TableApiError::InvalidRequest(
                "配列またはオブジェクトは SQL 値として使用できません。".to_string(),
            ));
        }
    }

    Ok(())
}

fn push_number_value(
    builder: &mut QueryBuilder<'_, MySql>,
    number: &Number,
) -> Result<(), TableApiError> {
    if let Some(value) = number.as_i64() {
        builder.push_bind(value);
        return Ok(());
    }

    if let Some(value) = number.as_u64() {
        builder.push_bind(value);
        return Ok(());
    }

    if let Some(value) = number.as_f64() {
        builder.push_bind(value);
        return Ok(());
    }

    Err(TableApiError::InvalidRequest(
        "数値の解釈に失敗しました。".to_string(),
    ))
}

fn append_selector_conditions(
    builder: &mut QueryBuilder<'_, MySql>,
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
) -> Result<(), TableApiError> {
    let mut is_first = true;

    for (column, value) in selector {
        if is_first {
            builder.push(" WHERE ");
            is_first = false;
        } else {
            builder.push(" ");
            builder.push(search_mode.sql_operator());
            builder.push(" ");
        }

        builder.push("`");
        builder.push(column.as_str());
        builder.push("` ");

        match value {
            Value::Null => {
                builder.push("IS NULL");
            }
            Value::String(text) if text.contains('%') => {
                builder.push("LIKE ");
                builder.push_bind(text.clone());
            }
            _ => {
                builder.push("= ");
                push_json_value(builder, value)?;
            }
        }
    }

    Ok(())
}

fn append_order_by_and_limit(
    builder: &mut QueryBuilder<'_, MySql>,
    options: &QueryOptions,
    force_limit: Option<u64>,
) {
    if let Some(order_by) = &options.order_by {
        builder.push(" ORDER BY `");
        builder.push(order_by.as_str());
        builder.push("` DESC");
    }

    if let Some(limit) = force_limit.or(options.limit) {
        builder.push(" LIMIT ");
        builder.push(limit.to_string());
    }
}

fn normalize_selector(params: &HashMap<String, String>) -> BTreeMap<String, Value> {
    let mut selector = BTreeMap::new();

    for (column, value) in params {
        if column == TABLE_NAME_QUERY_PARAM || value.is_empty() {
            continue;
        }

        selector.insert(column.clone(), Value::String(value.clone()));
    }

    selector
}

fn build_insert_values(request: &TablePostRequest) -> BTreeMap<String, Value> {
    let mut insert_values = request.selector.clone();

    if let Some(values) = &request.values {
        for (column, value) in values {
            insert_values.insert(column.clone(), value.clone());
        }
    }

    insert_values
}

pub fn validate_filter_columns(
    api_spec: &ApiSpecification,
    table_name: &str,
    params: &HashMap<String, String>,
) -> Result<(), TableApiError> {
    let allowed_columns = allowed_columns(api_spec, table_name);

    for column in params.keys() {
        if column == TABLE_NAME_QUERY_PARAM {
            continue;
        }

        ensure_allowed_column(&allowed_columns, column)?;
    }

    Ok(())
}

pub fn validate_post_request(
    api_spec: &ApiSpecification,
    table_name: &str,
    request: &TablePostRequest,
) -> Result<(), TableApiError> {
    if let Some(actual_table_name) = request.table_name.as_deref() {
        if actual_table_name != table_name {
            return Err(TableApiError::TableNameMismatch {
                expected: table_name.to_string(),
                actual: actual_table_name.to_string(),
            });
        }
    }

    let allowed_columns = allowed_columns(api_spec, table_name);
    for (column, value) in &request.selector {
        ensure_allowed_column(&allowed_columns, column)?;
        ensure_supported_value(value, column)?;
    }

    if let Some(values) = &request.values {
        for (column, value) in values {
            ensure_allowed_column(&allowed_columns, column)?;
            ensure_supported_value(value, column)?;
        }
    }

    if let Some(order_by) = &request.options.order_by {
        ensure_allowed_column(&allowed_columns, order_by)?;
    }

    if request.options.limit == Some(0) {
        return Err(TableApiError::InvalidRequest(
            "options.limit には 1 以上の値を指定してください。".to_string(),
        ));
    }

    Ok(())
}

pub async fn fetch_table_rows<R>(
    pool: &MySqlPool,
    params: &HashMap<String, String>,
) -> Result<Vec<R>, TableApiError>
where
    R: TableReadModel + for<'row> FromRow<'row, MySqlRow> + Send + Unpin + 'static,
{
    if let Some(table_name) = params.get(TABLE_NAME_QUERY_PARAM) {
        if table_name != R::TABLE_NAME {
            return Err(TableApiError::TableNameMismatch {
                expected: R::TABLE_NAME.to_string(),
                actual: table_name.clone(),
            });
        }
    }

    let selector = normalize_selector(params);
    fetch_table_rows_from_selector::<R>(pool, &selector, SearchMode::And, &QueryOptions::default())
        .await
}

pub async fn fetch_table_rows_from_selector<R>(
    pool: &MySqlPool,
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
    options: &QueryOptions,
) -> Result<Vec<R>, TableApiError>
where
    R: TableReadModel + for<'row> FromRow<'row, MySqlRow> + Send + Unpin + 'static,
{
    let mut query_builder =
        QueryBuilder::<MySql>::new(format!("SELECT * FROM `{}`", R::TABLE_NAME));
    append_selector_conditions(&mut query_builder, selector, search_mode)?;
    append_order_by_and_limit(&mut query_builder, options, None);

    query_builder
        .build_query_as::<R>()
        .fetch_all(pool)
        .await
        .map_err(TableApiError::QueryFailed)
}

pub async fn upsert_table_row<R>(
    pool: &MySqlPool,
    request: &TablePostRequest,
) -> Result<UpsertResult, TableApiError>
where
    R: TableReadModel + Send + Unpin + 'static,
{
    let insert_values = build_insert_values(request);
    if insert_values.is_empty() {
        return Err(TableApiError::InvalidRequest(
            "selector または values のどちらかには少なくとも 1 つ値を指定してください。"
                .to_string(),
        ));
    }

    if request.selector.is_empty() {
        let created_id = insert_table_row(pool, R::TABLE_NAME, &insert_values).await?;
        return Ok(UpsertResult {
            result: "insert",
            created_id,
        });
    }

    if row_exists(
        pool,
        R::TABLE_NAME,
        &request.selector,
        request.search_mode,
        &request.options,
    )
    .await?
    {
        if let Some(values) = request.values.as_ref() {
            if !values.is_empty() {
                update_first_matching_row(
                    pool,
                    R::TABLE_NAME,
                    &request.selector,
                    request.search_mode,
                    &request.options,
                    values,
                )
                .await?;
            }
        }

        return Ok(UpsertResult {
            result: "update",
            created_id: None,
        });
    }

    let created_id = insert_table_row(pool, R::TABLE_NAME, &insert_values).await?;
    Ok(UpsertResult {
        result: "insert",
        created_id,
    })
}

async fn row_exists(
    pool: &MySqlPool,
    table_name: &str,
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
    options: &QueryOptions,
) -> Result<bool, TableApiError> {
    let mut query_builder = QueryBuilder::<MySql>::new(format!("SELECT 1 FROM `{table_name}`"));
    append_selector_conditions(&mut query_builder, selector, search_mode)?;
    append_order_by_and_limit(&mut query_builder, options, Some(1));

    query_builder
        .build()
        .fetch_optional(pool)
        .await
        .map(|row| row.is_some())
        .map_err(TableApiError::QueryFailed)
}

async fn update_first_matching_row(
    pool: &MySqlPool,
    table_name: &str,
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
    options: &QueryOptions,
    values: &BTreeMap<String, Value>,
) -> Result<(), TableApiError> {
    let mut query_builder = QueryBuilder::<MySql>::new(format!("UPDATE `{table_name}` SET "));
    let mut is_first = true;

    for (column, value) in values {
        if is_first {
            is_first = false;
        } else {
            query_builder.push(", ");
        }

        query_builder.push("`");
        query_builder.push(column.as_str());
        query_builder.push("` = ");
        push_json_value(&mut query_builder, value)?;
    }

    append_selector_conditions(&mut query_builder, selector, search_mode)?;
    append_order_by_and_limit(&mut query_builder, options, Some(1));

    query_builder
        .build()
        .execute(pool)
        .await
        .map(|_| ())
        .map_err(TableApiError::QueryFailed)
}

async fn insert_table_row(
    pool: &MySqlPool,
    table_name: &str,
    values: &BTreeMap<String, Value>,
) -> Result<Option<u64>, TableApiError> {
    let mut query_builder = QueryBuilder::<MySql>::new(format!("INSERT INTO `{table_name}` ("));
    let mut is_first = true;

    for column in values.keys() {
        if is_first {
            is_first = false;
        } else {
            query_builder.push(", ");
        }

        query_builder.push("`");
        query_builder.push(column.as_str());
        query_builder.push("`");
    }

    query_builder.push(") VALUES (");

    let mut is_first = true;
    for value in values.values() {
        if is_first {
            is_first = false;
        } else {
            query_builder.push(", ");
        }

        push_json_value(&mut query_builder, value)?;
    }

    query_builder.push(")");

    query_builder
        .build()
        .execute(pool)
        .await
        .map(|result| {
            let last_insert_id = result.last_insert_id();
            if last_insert_id == 0 {
                None
            } else {
                Some(last_insert_id)
            }
        })
        .map_err(TableApiError::QueryFailed)
}

#[cfg(test)]
mod tests {
    use std::collections::{BTreeMap, HashMap};

    use serde_json::{Value, json};

    use super::{TableApiError, normalize_selector, validate_post_request};
    use crate::models::{
        ApiSpecification, QueryOptions, RequestFieldSpec, ResponseSpec, SearchMode,
        SupportEndpointSpec, TableColumnSpec, TableEndpointSpec, TableGetApiSpec, TablePostApiSpec,
        TablePostRequest,
    };

    fn build_api_spec() -> ApiSpecification {
        ApiSpecification {
            title: "test".to_string(),
            version: "1.0.0".to_string(),
            generated_at: "2026-05-18T00:00:00+09:00".to_string(),
            overview: Vec::new(),
            support_endpoints: vec![SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/health".to_string(),
                summary: "health".to_string(),
            }],
            table_get_api: TableGetApiSpec {
                method: "GET".to_string(),
                route_pattern: "/read".to_string(),
                filtering_behavior: Vec::new(),
                query_parameters: vec![RequestFieldSpec {
                    name: "id".to_string(),
                    required: false,
                    data_type: "number".to_string(),
                    description: "id".to_string(),
                }],
                responses: vec![ResponseSpec {
                    status: 200,
                    body: "[]".to_string(),
                    description: "ok".to_string(),
                }],
            },
            table_post_api: TablePostApiSpec {
                method: "POST".to_string(),
                read_route_pattern: "/read".to_string(),
                upsert_route_pattern: "/update".to_string(),
                behavior: Vec::new(),
                request_fields: Vec::new(),
                read_responses: Vec::new(),
                upsert_responses: Vec::new(),
            },
            table_endpoints: vec![TableEndpointSpec {
                table_name: "sample_table".to_string(),
                model_name: "SampleTable".to_string(),
                path: "/update".to_string(),
                summary: "sample".to_string(),
                schema_found: true,
                get_sample_request: String::new(),
                post_read_sample_request: String::new(),
                post_upsert_sample_request: String::new(),
                columns: vec![
                    TableColumnSpec {
                        name: "id".to_string(),
                        data_type: "int".to_string(),
                        column_type: "int".to_string(),
                        nullable: false,
                        key_type: Some("PRI".to_string()),
                        ordinal_position: 1,
                    },
                    TableColumnSpec {
                        name: "name".to_string(),
                        data_type: "varchar".to_string(),
                        column_type: "varchar(255)".to_string(),
                        nullable: true,
                        key_type: None,
                        ordinal_position: 2,
                    },
                ],
            }],
        }
    }

    #[test]
    fn normalize_selector_skips_table_name_and_empty_values() {
        let params = HashMap::from([
            ("table_name".to_string(), "sample_table".to_string()),
            ("id".to_string(), "10".to_string()),
            ("name".to_string(), "".to_string()),
        ]);

        let selector = normalize_selector(&params);

        assert_eq!(selector.len(), 1);
        assert_eq!(selector.get("id"), Some(&Value::String("10".to_string())));
    }

    #[test]
    fn validate_post_request_rejects_unknown_columns() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("unknown".to_string(), json!("x"))]),
            search_mode: SearchMode::And,
            options: QueryOptions::default(),
            values: None,
        };

        let error = validate_post_request(&api_spec, "sample_table", &request)
            .expect_err("unknown column should fail");

        assert!(matches!(error, TableApiError::InvalidColumn(column) if column == "unknown"));
    }

    #[test]
    fn validate_post_request_accepts_scalar_values() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("id".to_string(), json!(10))]),
            search_mode: SearchMode::Or,
            options: QueryOptions {
                order_by: Some("id".to_string()),
                limit: Some(10),
            },
            values: Some(BTreeMap::from([("name".to_string(), json!("updated"))])),
        };

        validate_post_request(&api_spec, "sample_table", &request)
            .expect("scalar values should pass");
    }
}
