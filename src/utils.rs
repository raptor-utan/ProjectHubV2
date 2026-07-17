use std::collections::{BTreeMap, HashMap};

use serde_json::{Number, Value};
use sqlx::{MySql, MySqlPool, QueryBuilder, query_as};

use crate::models::{
    AllowedSchemaSpec, ApiSpecification, DeleteResult, QueryOptions, SearchMode, TableColumnSpec,
    TableEndpointSpec, TablePostRequest, UpsertResult,
};
use crate::settings::constants::{TABLE_NAME_QUERY_PARAM, TABLE_SCHEMA_QUERY_PARAM};

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
                format!(
                    "table_name does not match the endpoint model. expected={expected}, actual={actual}"
                )
            }
            Self::InvalidColumn(column) => {
                format!("Unknown or unsupported column: {column}")
            }
            Self::InvalidRequest(message) => message.clone(),
            Self::QueryFailed(error) => {
                format!("Database query failed: {error}")
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

fn qualified_table_name(schema_name: &str, table_name: &str) -> String {
    format!("`{schema_name}`.`{table_name}`")
}

pub fn find_table_endpoint_spec<'a>(
    api_spec: &'a ApiSpecification,
    schema_name: &str,
    table_name: &str,
) -> Result<&'a TableEndpointSpec, TableApiError> {
    let endpoint = api_spec
        .table_endpoints
        .iter()
        .find(|endpoint| endpoint.schema_name == schema_name && endpoint.table_name == table_name)
        .ok_or_else(|| {
            TableApiError::InvalidRequest(format!(
                "Unsupported table_name in schema {schema_name}: {table_name}"
            ))
        })?;

    if !endpoint.schema_found || endpoint.columns.is_empty() {
        return Err(TableApiError::InvalidRequest(format!(
            "table_name is allowlisted but was not found in information_schema: {schema_name}.{table_name}"
        )));
    }

    Ok(endpoint)
}

pub fn find_allowed_schema_spec<'a>(
    api_spec: &'a ApiSpecification,
    schema_name: &str,
) -> Result<&'a AllowedSchemaSpec, TableApiError> {
    api_spec
        .allowed_schema_specs
        .iter()
        .find(|schema_spec| schema_spec.schema_name == schema_name)
        .ok_or_else(|| {
            TableApiError::InvalidRequest(format!(
                "schema_name is not registered in the API specification: {schema_name}"
            ))
        })
}

fn allowed_columns<'a>(
    api_spec: &'a ApiSpecification,
    schema_name: &str,
    table_name: &str,
) -> Result<Vec<&'a str>, TableApiError> {
    let endpoint = find_table_endpoint_spec(api_spec, schema_name, table_name)?;

    Ok(endpoint
        .columns
        .iter()
        .map(|column| column.name.as_str())
        .collect::<Vec<_>>())
}

fn ensure_allowed_column(allowed_columns: &[&str], column: &str) -> Result<(), TableApiError> {
    if !is_safe_identifier(column) || !allowed_columns.iter().any(|name| name == &column) {
        return Err(TableApiError::InvalidColumn(column.to_string()));
    }

    Ok(())
}

fn is_json_column(columns: &[TableColumnSpec], column_name: &str) -> bool {
    columns
        .iter()
        .any(|column| column.name == column_name && column.data_type.eq_ignore_ascii_case("json"))
}

fn ensure_supported_selector_value(value: &Value, field_name: &str) -> Result<(), TableApiError> {
    match value {
        Value::Null | Value::String(_) | Value::Bool(_) | Value::Number(_) => Ok(()),
        Value::Array(_) | Value::Object(_) => Err(TableApiError::InvalidRequest(format!(
            "{field_name} supports only string, number, bool, or null values"
        ))),
    }
}

fn ensure_supported_update_value(
    value: &Value,
    field_name: &str,
    allow_nested_json: bool,
) -> Result<(), TableApiError> {
    match value {
        Value::Null | Value::String(_) | Value::Bool(_) | Value::Number(_) => Ok(()),
        Value::Array(_) | Value::Object(_) if allow_nested_json => Ok(()),
        Value::Array(_) | Value::Object(_) => Err(TableApiError::InvalidRequest(format!(
            "{field_name} supports array/object values only when the target column data_type is json"
        ))),
    }
}

fn push_scalar_value(
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
                "Array and object values are not supported in SQL conditions".to_string(),
            ));
        }
    }

    Ok(())
}

fn push_json_document_value(
    builder: &mut QueryBuilder<'_, MySql>,
    value: &Value,
) -> Result<(), TableApiError> {
    let encoded_json = serde_json::to_string(value).map_err(|error| {
        TableApiError::InvalidRequest(format!("Failed to encode JSON value: {error}"))
    })?;

    builder.push("CAST(");
    builder.push_bind(encoded_json);
    builder.push(" AS JSON)");
    Ok(())
}

fn push_upsert_value(
    builder: &mut QueryBuilder<'_, MySql>,
    value: &Value,
    as_json_document: bool,
) -> Result<(), TableApiError> {
    if as_json_document {
        if value.is_null() {
            builder.push("NULL");
            return Ok(());
        }

        return push_json_document_value(builder, value);
    }

    push_scalar_value(builder, value)
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
        "Failed to decode numeric value".to_string(),
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
                push_scalar_value(builder, value)?;
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

fn append_json_object_projection(
    builder: &mut QueryBuilder<'_, MySql>,
    columns: &[TableColumnSpec],
) {
    builder.push("SELECT CAST(JSON_OBJECT(");

    if columns.is_empty() {
        builder.push(") AS CHAR)");
        return;
    }

    let mut is_first = true;
    for column in columns {
        if is_first {
            is_first = false;
        } else {
            builder.push(", ");
        }

        builder.push_bind(column.name.clone());
        builder.push(", `");
        builder.push(column.name.as_str());
        builder.push("`");
    }

    builder.push(") AS CHAR)");
}

fn normalize_selector(params: &HashMap<String, String>) -> BTreeMap<String, Value> {
    let mut selector = BTreeMap::new();

    for (column, value) in params {
        if column == TABLE_NAME_QUERY_PARAM
            || column == TABLE_SCHEMA_QUERY_PARAM
            || value.is_empty()
        {
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

fn parse_u64_value(value: &Value) -> Option<u64> {
    match value {
        Value::Number(number) => number.as_u64().or_else(|| {
            number
                .as_i64()
                .and_then(|value| (value >= 0).then_some(value as u64))
        }),
        Value::String(text) => text.parse::<u64>().ok(),
        _ => None,
    }
}

fn extract_created_id_from_insert_values(
    table_columns: &[TableColumnSpec],
    values: &BTreeMap<String, Value>,
) -> Option<u64> {
    let primary_key_columns = table_columns
        .iter()
        .filter(|column| column.key_type.as_deref() == Some("PRI"))
        .collect::<Vec<_>>();

    if primary_key_columns.len() != 1 {
        return None;
    }

    let primary_key_name = primary_key_columns[0].name.as_str();
    let primary_key_value = values.get(primary_key_name)?;
    parse_u64_value(primary_key_value)
}

pub fn validate_allowed_schema(
    allowed_schemas: &[String],
    schema_name: &str,
) -> Result<(), TableApiError> {
    if schema_name.trim().is_empty() {
        return Err(TableApiError::InvalidRequest(
            "schema_name must not be empty".to_string(),
        ));
    }

    if !is_safe_identifier(schema_name) {
        return Err(TableApiError::InvalidRequest(format!(
            "schema_name contains unsupported characters: {schema_name}"
        )));
    }

    if !allowed_schemas
        .iter()
        .any(|allowed_schema| allowed_schema == schema_name)
    {
        return Err(TableApiError::InvalidRequest(format!(
            "schema_name is not allowed: {schema_name}"
        )));
    }

    Ok(())
}

pub fn validate_discoverable_schema(
    api_spec: &ApiSpecification,
    schema_name: &str,
) -> Result<(), TableApiError> {
    let schema_spec = find_allowed_schema_spec(api_spec, schema_name)?;

    if !schema_spec.schema_found {
        return Err(TableApiError::InvalidRequest(format!(
            "schema_name is allowed but was not found in information_schema: {schema_name}"
        )));
    }

    Ok(())
}

pub fn validate_filter_columns(
    api_spec: &ApiSpecification,
    schema_name: &str,
    table_name: &str,
    params: &HashMap<String, String>,
) -> Result<(), TableApiError> {
    let allowed_columns = allowed_columns(api_spec, schema_name, table_name)?;

    for column in params.keys() {
        if column == TABLE_NAME_QUERY_PARAM || column == TABLE_SCHEMA_QUERY_PARAM {
            continue;
        }

        ensure_allowed_column(&allowed_columns, column)?;
    }

    Ok(())
}

pub fn validate_post_request(
    api_spec: &ApiSpecification,
    schema_name: &str,
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

    let endpoint = find_table_endpoint_spec(api_spec, schema_name, table_name)?;
    let allowed_columns = endpoint
        .columns
        .iter()
        .map(|column| column.name.as_str())
        .collect::<Vec<_>>();
    for (column, value) in &request.selector {
        ensure_allowed_column(&allowed_columns, column)?;
        ensure_supported_selector_value(value, column)?;
    }

    if let Some(values) = &request.values {
        for (column, value) in values {
            ensure_allowed_column(&allowed_columns, column)?;
            ensure_supported_update_value(
                value,
                column,
                is_json_column(&endpoint.columns, column),
            )?;
        }
    }

    if let Some(order_by) = &request.options.order_by {
        ensure_allowed_column(&allowed_columns, order_by)?;
    }

    if request.options.limit == Some(0) {
        return Err(TableApiError::InvalidRequest(
            "options.limit must be at least 1".to_string(),
        ));
    }

    Ok(())
}

pub async fn fetch_table_rows(
    pool: &MySqlPool,
    schema_name: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
    params: &HashMap<String, String>,
) -> Result<Vec<Value>, TableApiError> {
    if let Some(requested_table_name) = params.get(TABLE_NAME_QUERY_PARAM) {
        if requested_table_name != table_name {
            return Err(TableApiError::TableNameMismatch {
                expected: table_name.to_string(),
                actual: requested_table_name.clone(),
            });
        }
    }

    let selector = normalize_selector(params);
    fetch_table_rows_from_selector(
        pool,
        schema_name,
        table_name,
        columns,
        &selector,
        SearchMode::And,
        &QueryOptions::default(),
    )
    .await
}

pub async fn fetch_table_rows_from_selector(
    pool: &MySqlPool,
    schema_name: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
    options: &QueryOptions,
) -> Result<Vec<Value>, TableApiError> {
    let qualified_name = qualified_table_name(schema_name, table_name);
    let mut query_builder = QueryBuilder::<MySql>::new(String::new());
    append_json_object_projection(&mut query_builder, columns);
    query_builder.push(" AS row_json FROM ");
    query_builder.push(qualified_name);
    append_selector_conditions(&mut query_builder, selector, search_mode)?;
    append_order_by_and_limit(&mut query_builder, options, None);

    let rows: Vec<(String,)> = query_builder
        .build_query_as()
        .fetch_all(pool)
        .await
        .map_err(TableApiError::QueryFailed)?;

    rows.into_iter()
        .map(|(json_text,)| {
            serde_json::from_str::<Value>(&json_text).map_err(|error| {
                TableApiError::InvalidRequest(format!(
                    "Failed to decode database row JSON for {schema_name}.{table_name}: {error}"
                ))
            })
        })
        .collect()
}

pub async fn upsert_table_row(
    pool: &MySqlPool,
    schema_name: &str,
    table_name: &str,
    table_columns: &[TableColumnSpec],
    request: &TablePostRequest,
) -> Result<UpsertResult, TableApiError> {
    let insert_values = build_insert_values(request);
    if insert_values.is_empty() {
        return Err(TableApiError::InvalidRequest(
            "At least one value is required in selector or values".to_string(),
        ));
    }

    if request.selector.is_empty() {
        let created_id =
            insert_table_row(pool, schema_name, table_name, table_columns, &insert_values).await?;
        return Ok(UpsertResult {
            result: "insert",
            created_id,
        });
    }

    if row_exists(
        pool,
        schema_name,
        table_name,
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
                    schema_name,
                    table_name,
                    &request.selector,
                    request.search_mode,
                    &request.options,
                    table_columns,
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

    let created_id =
        insert_table_row(pool, schema_name, table_name, table_columns, &insert_values).await?;
    Ok(UpsertResult {
        result: "insert",
        created_id,
    })
}

pub async fn delete_table_row(
    pool: &MySqlPool,
    schema_name: &str,
    table_name: &str,
    request: &TablePostRequest,
) -> Result<DeleteResult, TableApiError> {
    if request.selector.is_empty() {
        return Err(TableApiError::InvalidRequest(
            "DELETE /delete requires selector".to_string(),
        ));
    }

    let qualified_name = qualified_table_name(schema_name, table_name);
    let mut query_builder = QueryBuilder::<MySql>::new(format!("DELETE FROM {qualified_name}"));
    append_selector_conditions(&mut query_builder, &request.selector, request.search_mode)?;
    append_order_by_and_limit(&mut query_builder, &request.options, Some(1));

    let result = query_builder
        .build()
        .execute(pool)
        .await
        .map_err(TableApiError::QueryFailed)?;

    Ok(DeleteResult {
        result: "delete",
        deleted_count: result.rows_affected(),
    })
}

async fn row_exists(
    pool: &MySqlPool,
    schema_name: &str,
    table_name: &str,
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
    options: &QueryOptions,
) -> Result<bool, TableApiError> {
    let qualified_name = qualified_table_name(schema_name, table_name);
    let mut query_builder = QueryBuilder::<MySql>::new(format!("SELECT 1 FROM {qualified_name}"));
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
    schema_name: &str,
    table_name: &str,
    selector: &BTreeMap<String, Value>,
    search_mode: SearchMode,
    options: &QueryOptions,
    table_columns: &[TableColumnSpec],
    values: &BTreeMap<String, Value>,
) -> Result<(), TableApiError> {
    let qualified_name = qualified_table_name(schema_name, table_name);
    let mut query_builder = QueryBuilder::<MySql>::new(format!("UPDATE {qualified_name} SET "));
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
        push_upsert_value(
            &mut query_builder,
            value,
            is_json_column(table_columns, column),
        )?;
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
    schema_name: &str,
    table_name: &str,
    table_columns: &[TableColumnSpec],
    values: &BTreeMap<String, Value>,
) -> Result<Option<u64>, TableApiError> {
    let qualified_name = qualified_table_name(schema_name, table_name);
    let mut query_builder = QueryBuilder::<MySql>::new(format!("INSERT INTO {qualified_name} ("));
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
    for (column, value) in values {
        if is_first {
            is_first = false;
        } else {
            query_builder.push(", ");
        }

        push_upsert_value(
            &mut query_builder,
            value,
            is_json_column(table_columns, column),
        )?;
    }

    query_builder.push(")");

    let mut connection = pool.acquire().await.map_err(TableApiError::QueryFailed)?;
    let result = query_builder
        .build()
        .execute(&mut *connection)
        .await
        .map_err(TableApiError::QueryFailed)?;

    let last_insert_id = result.last_insert_id();
    if last_insert_id != 0 {
        return Ok(Some(last_insert_id));
    }

    let (session_last_insert_id,): (u64,) = query_as("SELECT LAST_INSERT_ID()")
        .fetch_one(&mut *connection)
        .await
        .map_err(TableApiError::QueryFailed)?;
    if session_last_insert_id != 0 {
        return Ok(Some(session_last_insert_id));
    }

    Ok(extract_created_id_from_insert_values(table_columns, values))
}

#[cfg(test)]
mod tests {
    use std::collections::{BTreeMap, HashMap};

    use serde_json::{Value, json};

    use super::{
        TableApiError, extract_created_id_from_insert_values, find_table_endpoint_spec,
        normalize_selector, validate_allowed_schema, validate_discoverable_schema,
        validate_post_request,
    };
    use crate::models::{
        AllowedSchemaSpec, ApiSpecification, QueryOptions, RequestFieldSpec, ResponseSpec,
        SearchMode, SupportEndpointSpec, TableColumnSpec, TableEndpointSpec, TableGetApiSpec,
        TablePostApiSpec, TablePostRequest,
    };

    fn build_api_spec() -> ApiSpecification {
        ApiSpecification {
            title: "test".to_string(),
            version: "1.0.0".to_string(),
            generated_at: "2026-05-18T00:00:00+09:00".to_string(),
            overview: Vec::new(),
            allowed_schemas: vec!["ifs_reference_data".to_string()],
            allowed_schema_specs: vec![AllowedSchemaSpec {
                schema_name: "ifs_reference_data".to_string(),
                is_default: true,
                schema_found: true,
                table_count: 1,
            }],
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
                schema_name: "ifs_reference_data".to_string(),
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
                    TableColumnSpec {
                        name: "payload".to_string(),
                        data_type: "json".to_string(),
                        column_type: "json".to_string(),
                        nullable: true,
                        key_type: None,
                        ordinal_position: 3,
                    },
                ],
            }],
        }
    }

    #[test]
    fn normalize_selector_skips_table_name_schema_name_and_empty_values() {
        let params = HashMap::from([
            ("schema_name".to_string(), "ifs_reference_data".to_string()),
            ("table_name".to_string(), "sample_table".to_string()),
            ("id".to_string(), "10".to_string()),
            ("name".to_string(), "".to_string()),
        ]);

        let selector = normalize_selector(&params);

        assert_eq!(selector.len(), 1);
        assert_eq!(selector.get("id"), Some(&Value::String("10".to_string())));
    }

    #[test]
    fn extract_created_id_returns_primary_key_value_when_present() {
        let values = BTreeMap::from([("id".to_string(), json!(1234))]);
        let api_spec = build_api_spec();
        let table_columns = &api_spec.table_endpoints[0].columns;

        let created_id = extract_created_id_from_insert_values(table_columns, &values);

        assert_eq!(created_id, Some(1234));
    }

    #[test]
    fn extract_created_id_returns_none_when_primary_key_is_not_numeric() {
        let values = BTreeMap::from([("id".to_string(), json!("abc"))]);
        let api_spec = build_api_spec();
        let table_columns = &api_spec.table_endpoints[0].columns;

        let created_id = extract_created_id_from_insert_values(table_columns, &values);

        assert_eq!(created_id, None);
    }

    #[test]
    fn extract_created_id_returns_none_when_multiple_primary_keys_exist() {
        let values = BTreeMap::from([
            ("id".to_string(), json!(1)),
            ("name".to_string(), json!("sample")),
        ]);
        let mut api_spec = build_api_spec();
        api_spec.table_endpoints[0].columns[1].key_type = Some("PRI".to_string());
        let table_columns = &api_spec.table_endpoints[0].columns;

        let created_id = extract_created_id_from_insert_values(table_columns, &values);

        assert_eq!(created_id, None);
    }

    #[test]
    fn validate_allowed_schema_accepts_listed_schema() {
        validate_allowed_schema(&["ifs_reference_data".to_string()], "ifs_reference_data")
            .expect("listed schema should pass");
    }

    #[test]
    fn validate_allowed_schema_rejects_unlisted_schema() {
        let error = validate_allowed_schema(&["ifs_reference_data".to_string()], "other_schema")
            .expect_err("unlisted schema should fail");

        assert!(matches!(error, TableApiError::InvalidRequest(_)));
    }

    #[test]
    fn validate_post_request_rejects_unknown_columns() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            schema_name: Some("ifs_reference_data".to_string()),
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("unknown".to_string(), json!("x"))]),
            search_mode: SearchMode::And,
            options: QueryOptions::default(),
            values: None,
        };

        let error =
            validate_post_request(&api_spec, "ifs_reference_data", "sample_table", &request)
                .expect_err("unknown column should fail");

        assert!(matches!(error, TableApiError::InvalidColumn(column) if column == "unknown"));
    }

    #[test]
    fn validate_post_request_accepts_scalar_values() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            schema_name: Some("ifs_reference_data".to_string()),
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("id".to_string(), json!(10))]),
            search_mode: SearchMode::Or,
            options: QueryOptions {
                order_by: Some("id".to_string()),
                limit: Some(10),
            },
            values: Some(BTreeMap::from([("name".to_string(), json!("updated"))])),
        };

        validate_post_request(&api_spec, "ifs_reference_data", "sample_table", &request)
            .expect("scalar values should pass");
    }

    #[test]
    fn validate_post_request_accepts_nested_json_values_for_json_column() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            schema_name: Some("ifs_reference_data".to_string()),
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("id".to_string(), json!(10))]),
            search_mode: SearchMode::And,
            options: QueryOptions::default(),
            values: Some(BTreeMap::from([(
                "payload".to_string(),
                json!({
                    "tags": ["a", "b"],
                    "nested": { "enabled": true, "count": 2 }
                }),
            )])),
        };

        validate_post_request(&api_spec, "ifs_reference_data", "sample_table", &request)
            .expect("nested JSON value should pass for json column");
    }

    #[test]
    fn validate_post_request_rejects_nested_json_values_for_non_json_column() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            schema_name: Some("ifs_reference_data".to_string()),
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("id".to_string(), json!(10))]),
            search_mode: SearchMode::And,
            options: QueryOptions::default(),
            values: Some(BTreeMap::from([("name".to_string(), json!({ "x": 1 }))])),
        };

        let error =
            validate_post_request(&api_spec, "ifs_reference_data", "sample_table", &request)
                .expect_err("nested JSON value should fail for non-json column");

        assert!(matches!(
            error,
            TableApiError::InvalidRequest(message)
            if message.contains("data_type is json")
        ));
    }

    #[test]
    fn validate_post_request_rejects_nested_json_selector() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            schema_name: Some("ifs_reference_data".to_string()),
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("payload".to_string(), json!({ "x": 1 }))]),
            search_mode: SearchMode::And,
            options: QueryOptions::default(),
            values: Some(BTreeMap::from([("name".to_string(), json!("updated"))])),
        };

        let error =
            validate_post_request(&api_spec, "ifs_reference_data", "sample_table", &request)
                .expect_err("selector should only accept scalar values");

        assert!(matches!(
            error,
            TableApiError::InvalidRequest(message)
            if message.contains("supports only string, number, bool, or null values")
        ));
    }

    #[test]
    fn validate_post_request_rejects_table_in_wrong_schema() {
        let api_spec = build_api_spec();
        let request = TablePostRequest {
            schema_name: Some("plango".to_string()),
            table_name: Some("sample_table".to_string()),
            selector: BTreeMap::from([("id".to_string(), json!(10))]),
            search_mode: SearchMode::And,
            options: QueryOptions::default(),
            values: None,
        };

        let error = validate_post_request(&api_spec, "plango", "sample_table", &request)
            .expect_err("table in unsupported schema should fail");

        assert!(matches!(error, TableApiError::InvalidRequest(_)));
    }

    #[test]
    fn find_table_endpoint_spec_rejects_undiscoverable_table() {
        let mut api_spec = build_api_spec();
        let mut undiscoverable_endpoint = api_spec.table_endpoints[0].clone();
        undiscoverable_endpoint.table_name = "missing_table".to_string();
        undiscoverable_endpoint.schema_found = false;
        undiscoverable_endpoint.columns = Vec::new();
        api_spec.table_endpoints.push(undiscoverable_endpoint);

        let error = find_table_endpoint_spec(&api_spec, "ifs_reference_data", "missing_table")
            .expect_err("undiscoverable table should be rejected");

        assert!(
            matches!(error, TableApiError::InvalidRequest(message) if message.contains("allowlisted but was not found in information_schema"))
        );
    }

    #[test]
    fn validate_discoverable_schema_accepts_schema_in_spec() {
        let api_spec = build_api_spec();

        validate_discoverable_schema(&api_spec, "ifs_reference_data")
            .expect("discoverable schema should pass");
    }

    #[test]
    fn validate_discoverable_schema_rejects_missing_schema() {
        let api_spec = ApiSpecification {
            allowed_schema_specs: vec![AllowedSchemaSpec {
                schema_name: "missing_schema".to_string(),
                is_default: false,
                schema_found: false,
                table_count: 0,
            }],
            ..build_api_spec()
        };

        let error = validate_discoverable_schema(&api_spec, "missing_schema")
            .expect_err("undiscoverable schema should fail");

        assert!(matches!(error, TableApiError::InvalidRequest(_)));
    }
}
