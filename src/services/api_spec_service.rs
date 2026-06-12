use std::collections::BTreeMap;

use chrono::Local;
use serde_json::json;
use sqlx::{FromRow, MySql, MySqlPool, QueryBuilder};

use crate::models::{
    AllowedSchemaSpec, ApiSpecification, RequestFieldSpec, ResponseSpec, SupportEndpointSpec,
    TableColumnSpec, TableEndpointSpec, TableGetApiSpec, TablePostApiSpec,
};
use crate::settings::constants::{
    TABLE_METADATA_ROUTE, TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE, TABLE_SCHEMA_QUERY_PARAM,
    TABLE_UPDATE_ROUTE,
};

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct TableAllowlistEntry {
    pub schema_name: String,
    pub table_name: String,
}

#[derive(Debug, FromRow)]
struct InformationSchemaColumnRow {
    table_schema: String,
    table_name: String,
    column_name: String,
    data_type: String,
    column_type: String,
    is_nullable: String,
    column_key: Option<String>,
    ordinal_position: u32,
}

#[derive(Debug, FromRow)]
struct InformationSchemaNameRow {
    schema_name: String,
}

/// information_schema をもとに API 仕様を組み立てます。
pub async fn build_api_spec(
    pool: &MySqlPool,
    allowed_schemas: &[String],
    allowed_tables: &[TableAllowlistEntry],
    default_schema: &str,
) -> Result<ApiSpecification, sqlx::Error> {
    let table_endpoints = fetch_table_endpoints(pool, allowed_tables).await?;
    let allowed_schema_specs =
        fetch_allowed_schema_specs(pool, allowed_schemas, default_schema, &table_endpoints).await?;

    Ok(ApiSpecification {
        title: "ProjectHubV2 API仕様".to_string(),
        version: "1.7.0".to_string(),
        generated_at: Local::now().to_rfc3339(),
        overview: vec![
            "GET /read はクエリ文字列検索、POST /read は JSON 条件検索、POST /update は upsert を実行します。"
                .to_string(),
            format!(
                "`{TABLE_SCHEMA_QUERY_PARAM}` は GET/POST の両方で利用できます。未指定時はデフォルトスキーマ `{default_schema}` を使用します。"
            ),
            format!(
                "利用可能スキーマは allowlist で制御されます: {}",
                allowed_schemas.join(", ")
            ),
            "利用可能テーブルは `PROJECT_HUB_ALLOWED_TABLES`、未設定時は `sql/*.sql` の DDL から決定します。"
                .to_string(),
        ],
        allowed_schemas: allowed_schemas.to_vec(),
        allowed_schema_specs,
        support_endpoints: vec![
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/".to_string(),
                summary: "/manual へリダイレクトします。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/manual".to_string(),
                summary: "HTML 形式の API マニュアルを表示します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/api/spec".to_string(),
                summary: "マニュアル表示用の JSON API 仕様を返します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/health".to_string(),
                summary: "ヘルスチェック結果を返します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: TABLE_METADATA_ROUTE.to_string(),
                summary: "allowlist 対象テーブルのテーブルコメントと列コメントを JSON で返します。"
                    .to_string(),
            },
        ],
        table_get_api: TableGetApiSpec {
            method: "GET".to_string(),
            route_pattern: TABLE_READ_ROUTE.to_string(),
            filtering_behavior: vec![
                format!("`{TABLE_NAME_QUERY_PARAM}` は必須です。"),
                format!(
                    "`{TABLE_SCHEMA_QUERY_PARAM}` は任意です。未指定時はデフォルトスキーマ `{default_schema}` を使用します。"
                ),
                "追加のクエリパラメータは対象テーブルの列名と解釈され、AND 条件で検索します。"
                    .to_string(),
                "`%` を含む文字列は LIKE 条件として扱います。".to_string(),
            ],
            query_parameters: vec![
                RequestFieldSpec {
                    name: TABLE_SCHEMA_QUERY_PARAM.to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "対象スキーマ名。allowlist に含まれる値のみ指定できます。"
                        .to_string(),
                },
                RequestFieldSpec {
                    name: TABLE_NAME_QUERY_PARAM.to_string(),
                    required: true,
                    data_type: "string".to_string(),
                    description:
                        "対象テーブル名。allowlist に含まれ、information_schema で解決できる必要があります。"
                            .to_string(),
                },
                RequestFieldSpec {
                    name: "<column_name>".to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "列名ごとの検索条件。`%` を含むと LIKE 検索になります。"
                        .to_string(),
                },
            ],
            responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "テーブル行の JSON 配列".to_string(),
                    description: "条件に一致した行を返します。".to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description:
                        "必須パラメータ不足、allowlist 違反、不正な列名などの入力エラーです。"
                            .to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行に失敗した場合のエラーです。".to_string(),
                },
            ],
        },
        table_post_api: TablePostApiSpec {
            method: "POST".to_string(),
            read_route_pattern: TABLE_READ_ROUTE.to_string(),
            upsert_route_pattern: TABLE_UPDATE_ROUTE.to_string(),
            behavior: vec![
                "POST /read は JSON 条件検索を行い、`{\"result\":[...]}` を返します。"
                    .to_string(),
                "POST /update は JSON upsert を行い、update か insert の結果を返します。"
                    .to_string(),
                format!(
                    "`schema_name` は任意です。未指定時はデフォルトスキーマ `{default_schema}` を使用します。"
                ),
                "`selector` は `and_` / `or_` を選べます。`options.order_by` と `options.limit` に対応します。"
                    .to_string(),
                "POST /update の `values` は必須です。新規 insert 時は `selector` と `values` を合わせて使用します。"
                    .to_string(),
            ],
            request_fields: vec![
                RequestFieldSpec {
                    name: "schema_name".to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "対象スキーマ名。allowlist に含まれる値のみ指定できます。"
                        .to_string(),
                },
                RequestFieldSpec {
                    name: "table_name".to_string(),
                    required: true,
                    data_type: "string".to_string(),
                    description:
                        "対象テーブル名。allowlist に含まれ、information_schema で解決できる必要があります。"
                            .to_string(),
                },
                RequestFieldSpec {
                    name: "selector".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description:
                        "検索条件。値には string / number / bool / null を使用できます。"
                            .to_string(),
                },
                RequestFieldSpec {
                    name: "search_mode".to_string(),
                    required: false,
                    data_type: "`and_` | `or_`".to_string(),
                    description: "selector の結合条件です。省略時は `or_` です。".to_string(),
                },
                RequestFieldSpec {
                    name: "options".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description: "`order_by` と `limit` を指定できます。".to_string(),
                },
                RequestFieldSpec {
                    name: "values".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description: "POST /update 用の更新値です。POST /read では指定できません。"
                        .to_string(),
                },
            ],
            read_responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "{\"result\":[...]}".to_string(),
                    description: "JSON 条件検索の結果です。".to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description:
                        "必須 JSON 欠落、allowlist 違反、不正な列名、不正 JSON などの入力エラーです。"
                            .to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行に失敗した場合のエラーです。".to_string(),
                },
            ],
            upsert_responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "{\"result\":\"update|insert\",\"created_id\":number|null}"
                        .to_string(),
                    description:
                        "insert 時は auto increment の ID を `created_id` に返します。"
                            .to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description:
                        "必須 JSON 欠落、allowlist 違反、不正な列名、不正 JSON などの入力エラーです。"
                            .to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行に失敗した場合のエラーです。".to_string(),
                },
            ],
        },
        table_endpoints,
    })
}

async fn fetch_allowed_schema_specs(
    pool: &MySqlPool,
    allowed_schemas: &[String],
    default_schema: &str,
    table_endpoints: &[TableEndpointSpec],
) -> Result<Vec<AllowedSchemaSpec>, sqlx::Error> {
    let existing_schema_names = fetch_existing_schema_names(pool, allowed_schemas).await?;
    let table_counts_by_schema = build_table_counts_by_schema(table_endpoints);

    Ok(allowed_schemas
        .iter()
        .map(|schema_name| AllowedSchemaSpec {
            schema_name: schema_name.clone(),
            is_default: schema_name == default_schema,
            schema_found: existing_schema_names
                .iter()
                .any(|existing_schema_name| existing_schema_name == schema_name),
            table_count: table_counts_by_schema
                .get(schema_name)
                .copied()
                .unwrap_or(0),
        })
        .collect())
}

async fn fetch_existing_schema_names(
    pool: &MySqlPool,
    allowed_schemas: &[String],
) -> Result<Vec<String>, sqlx::Error> {
    if allowed_schemas.is_empty() {
        return Ok(Vec::new());
    }

    let mut query_builder = QueryBuilder::<MySql>::new(
        "SELECT CAST(SCHEMA_NAME AS CHAR(255)) AS schema_name \
         FROM information_schema.schemata \
         WHERE schema_name IN (",
    );

    {
        let mut separated = query_builder.separated(", ");
        for schema_name in allowed_schemas {
            separated.push_bind(schema_name);
        }
    }

    query_builder.push(") ORDER BY SCHEMA_NAME");

    let rows: Vec<InformationSchemaNameRow> = query_builder
        .build_query_as::<InformationSchemaNameRow>()
        .fetch_all(pool)
        .await?;

    Ok(rows.into_iter().map(|row| row.schema_name).collect())
}

fn build_table_counts_by_schema(table_endpoints: &[TableEndpointSpec]) -> BTreeMap<String, usize> {
    let mut table_counts_by_schema = BTreeMap::new();

    for endpoint in table_endpoints {
        *table_counts_by_schema
            .entry(endpoint.schema_name.clone())
            .or_insert(0) += 1;
    }

    table_counts_by_schema
}

async fn fetch_table_endpoints(
    pool: &MySqlPool,
    allowed_tables: &[TableAllowlistEntry],
) -> Result<Vec<TableEndpointSpec>, sqlx::Error> {
    let columns_by_table = fetch_columns_by_table(pool, allowed_tables).await?;

    Ok(allowed_tables
        .iter()
        .map(|entry| {
            let columns = columns_by_table
                .get(&(entry.schema_name.clone(), entry.table_name.clone()))
                .cloned()
                .unwrap_or_default();
            let schema_found = !columns.is_empty();
            let summary = if schema_found {
                format!(
                    "{}.{} can be read by GET or POST /read and updated by POST /update within the configured allowlists",
                    entry.schema_name, entry.table_name
                )
            } else {
                format!(
                    "{}.{} is allowlisted but was not found in information_schema, so this endpoint is unavailable",
                    entry.schema_name, entry.table_name
                )
            };

            TableEndpointSpec {
                schema_name: entry.schema_name.clone(),
                table_name: entry.table_name.clone(),
                model_name: "DynamicTableRow".to_string(),
                path: TABLE_READ_ROUTE.to_string(),
                summary,
                schema_found,
                get_sample_request: build_get_sample_request(
                    &entry.schema_name,
                    &entry.table_name,
                    &columns,
                ),
                post_read_sample_request: build_post_read_sample_request(
                    &entry.schema_name,
                    &entry.table_name,
                    &columns,
                ),
                post_upsert_sample_request: build_post_upsert_sample_request(
                    &entry.schema_name,
                    &entry.table_name,
                    &columns,
                ),
                columns,
            }
        })
        .collect())
}

async fn fetch_columns_by_table(
    pool: &MySqlPool,
    allowed_tables: &[TableAllowlistEntry],
) -> Result<BTreeMap<(String, String), Vec<TableColumnSpec>>, sqlx::Error> {
    let mut columns_by_table = BTreeMap::new();
    if allowed_tables.is_empty() {
        return Ok(columns_by_table);
    }

    let mut query_builder = QueryBuilder::<MySql>::new(
        "SELECT \
             CAST(TABLE_SCHEMA AS CHAR(255)) AS table_schema, \
             CAST(TABLE_NAME AS CHAR(255)) AS table_name, \
             CAST(COLUMN_NAME AS CHAR(255)) AS column_name, \
             CAST(DATA_TYPE AS CHAR(255)) AS data_type, \
             CAST(COLUMN_TYPE AS CHAR(255)) AS column_type, \
             CAST(IS_NULLABLE AS CHAR(8)) AS is_nullable, \
             CAST(COLUMN_KEY AS CHAR(32)) AS column_key, \
             ORDINAL_POSITION AS ordinal_position \
         FROM information_schema.columns \
         WHERE ",
    );

    append_allowed_table_conditions(&mut query_builder, allowed_tables);
    query_builder.push(" ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION");

    let rows: Vec<InformationSchemaColumnRow> = query_builder
        .build_query_as::<InformationSchemaColumnRow>()
        .fetch_all(pool)
        .await?;

    for row in rows {
        columns_by_table
            .entry((row.table_schema.clone(), row.table_name.clone()))
            .or_insert_with(Vec::new)
            .push(TableColumnSpec {
                name: row.column_name,
                data_type: row.data_type,
                column_type: row.column_type,
                nullable: row.is_nullable.eq_ignore_ascii_case("YES"),
                key_type: row.column_key.filter(|value| !value.is_empty()),
                ordinal_position: row.ordinal_position,
            });
    }

    Ok(columns_by_table)
}

fn append_allowed_table_conditions<'a>(
    query_builder: &mut QueryBuilder<'a, MySql>,
    allowed_tables: &'a [TableAllowlistEntry],
) {
    let mut is_first = true;

    for entry in allowed_tables {
        if is_first {
            is_first = false;
        } else {
            query_builder.push(" OR ");
        }

        query_builder.push("(");
        query_builder.push("TABLE_SCHEMA = ");
        query_builder.push_bind(&entry.schema_name);
        query_builder.push(" AND TABLE_NAME = ");
        query_builder.push_bind(&entry.table_name);
        query_builder.push(")");
    }
}

fn build_get_sample_request(
    schema_name: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
) -> String {
    match columns.first() {
        Some(column) => format!(
            "{TABLE_READ_ROUTE}?{TABLE_SCHEMA_QUERY_PARAM}={schema_name}&{TABLE_NAME_QUERY_PARAM}={table_name}&{}=<value>",
            column.name
        ),
        None => format!(
            "{TABLE_READ_ROUTE}?{TABLE_SCHEMA_QUERY_PARAM}={schema_name}&{TABLE_NAME_QUERY_PARAM}={table_name}"
        ),
    }
}

fn build_post_read_sample_request(
    schema_name: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
) -> String {
    let selector_column = columns
        .first()
        .map(|column| column.name.clone())
        .unwrap_or_else(|| "example_column".to_string());

    serde_json::to_string_pretty(&json!({
        "schema_name": schema_name,
        "table_name": table_name,
        "search_mode": "and_",
        "selector": {
            selector_column: "<value>"
        }
    }))
    .expect("sample JSON must be serializable")
}

fn build_post_upsert_sample_request(
    schema_name: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
) -> String {
    let selector_column = columns
        .first()
        .map(|column| column.name.clone())
        .unwrap_or_else(|| "example_selector".to_string());
    let value_column = columns
        .iter()
        .find(|column| column.name != selector_column)
        .map(|column| column.name.clone())
        .unwrap_or_else(|| selector_column.clone());

    serde_json::to_string_pretty(&json!({
        "schema_name": schema_name,
        "table_name": table_name,
        "search_mode": "and_",
        "selector": {
            selector_column: "<value>"
        },
        "values": {
            value_column: "<new_value>"
        }
    }))
    .expect("sample JSON must be serializable")
}

#[cfg(test)]
mod tests {
    use super::{TableAllowlistEntry, append_allowed_table_conditions};
    use sqlx::{Execute, MySql, QueryBuilder};

    #[test]
    fn append_allowed_table_conditions_builds_valid_or_predicates() {
        let mut query_builder = QueryBuilder::<MySql>::new("SELECT 1 WHERE ");
        let allowed_tables = vec![
            TableAllowlistEntry {
                schema_name: "ifs_reference_data".to_string(),
                table_name: "sample_table".to_string(),
            },
            TableAllowlistEntry {
                schema_name: "plango".to_string(),
                table_name: "users".to_string(),
            },
        ];

        append_allowed_table_conditions(&mut query_builder, &allowed_tables);

        let query = query_builder.build();
        let sql = query.sql();

        assert_eq!(
            sql,
            "SELECT 1 WHERE (TABLE_SCHEMA = ? AND TABLE_NAME = ?) OR (TABLE_SCHEMA = ? AND TABLE_NAME = ?)"
        );
    }
}
