use std::collections::BTreeMap;

use chrono::Local;
use serde_json::json;
use sqlx::{FromRow, MySql, MySqlPool, QueryBuilder};

use crate::models::{
    ApiSpecification, RequestFieldSpec, ResponseSpec, SupportEndpointSpec, TableColumnSpec,
    TableEndpointSpec, TableGetApiSpec, TablePostApiSpec,
};
use crate::services::table_read_service::{TableEndpointDescriptor, table_endpoint_descriptors};
use crate::settings::constants::{
    TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE, TABLE_SCHEMA_QUERY_PARAM, TABLE_UPDATE_ROUTE,
};

#[derive(Debug, FromRow)]
struct InformationSchemaColumnRow {
    table_name: String,
    column_name: String,
    data_type: String,
    column_type: String,
    is_nullable: String,
    column_key: Option<String>,
    ordinal_position: u32,
}

/// information_schema を基準に API 仕様を組み立てる。
pub async fn build_api_spec(
    pool: &MySqlPool,
    allowed_schemas: &[String],
    default_schema: &str,
) -> Result<ApiSpecification, sqlx::Error> {
    let table_descriptors = table_endpoint_descriptors();
    let columns_by_table = fetch_columns_by_table(pool, &table_descriptors, default_schema).await?;

    let table_endpoints = table_descriptors
        .iter()
        .map(|descriptor| {
            let columns = columns_by_table
                .get(descriptor.table_name)
                .cloned()
                .unwrap_or_default();

            TableEndpointSpec {
                table_name: descriptor.table_name.to_string(),
                model_name: descriptor.model_name.to_string(),
                path: TABLE_READ_ROUTE.to_string(),
                summary: format!(
                    "{} can be read by GET or POST /read and updated by POST /update within the allowed schemas",
                    descriptor.table_name
                ),
                schema_found: !columns.is_empty(),
                get_sample_request: build_get_sample_request(default_schema, descriptor.table_name, &columns),
                post_read_sample_request: build_post_read_sample_request(
                    default_schema,
                    descriptor.table_name,
                    &columns,
                ),
                post_upsert_sample_request: build_post_upsert_sample_request(
                    default_schema,
                    descriptor.table_name,
                    &columns,
                ),
                columns,
            }
        })
        .collect();

    Ok(ApiSpecification {
        title: "ProjectHubV2 API仕様".to_string(),
        version: "1.2.0".to_string(),
        generated_at: Local::now().to_rfc3339(),
        overview: vec![
            format!(
                "GET はクエリ、POST は JSON で検索条件を受け取り、POST /update は upsert を実行します。"
            ),
            format!(
                "`{TABLE_SCHEMA_QUERY_PARAM}` は GET と POST の両方で指定できます。未指定時はデフォルトスキーマ `{default_schema}` を使用します。"
            ),
            format!(
                "アクセス可能なスキーマは次の allowlist のみです: {}",
                allowed_schemas.join(", ")
            ),
            format!(
                "カラム定義とサンプルはデフォルトスキーマ `{default_schema}` の information_schema を基準に生成しています。"
            ),
        ],
        allowed_schemas: allowed_schemas.to_vec(),
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
                summary: "マニュアル用の JSON API 仕様を返します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/health".to_string(),
                summary: "ヘルスチェック結果を返します。".to_string(),
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
                "追加のクエリパラメータは対象テーブルのカラム名として扱い、AND 条件で検索します。".to_string(),
                "文字列値に `%` を含めると LIKE 条件として扱います。".to_string(),
            ],
            query_parameters: vec![
                RequestFieldSpec {
                    name: TABLE_SCHEMA_QUERY_PARAM.to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "対象スキーマ名。allowlist に含まれる値のみ指定できます。".to_string(),
                },
                RequestFieldSpec {
                    name: TABLE_NAME_QUERY_PARAM.to_string(),
                    required: true,
                    data_type: "string".to_string(),
                    description: "対象テーブル名。".to_string(),
                },
                RequestFieldSpec {
                    name: "<column_name>".to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "一致または LIKE で検索するカラム値。".to_string(),
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
                    description: "必須パラメータ不足、許可外スキーマ、不正カラムのときに返します。".to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行に失敗したときに返します。".to_string(),
                },
            ],
        },
        table_post_api: TablePostApiSpec {
            method: "POST".to_string(),
            read_route_pattern: TABLE_READ_ROUTE.to_string(),
            upsert_route_pattern: TABLE_UPDATE_ROUTE.to_string(),
            behavior: vec![
                "POST /read は JSON 条件検索を行い、{\"result\":[...]} を返します。".to_string(),
                "POST /update は JSON upsert を行い、update か insert の結果を返します。".to_string(),
                format!(
                    "`schema_name` は任意です。未指定時はデフォルトスキーマ `{default_schema}` を使用します。"
                ),
                "selector では and_ / or_ を選べ、options.order_by と options.limit を指定できます。".to_string(),
                "POST /update の values は必須で、更新対象が見つからない場合は selector と values を合わせて INSERT します。".to_string(),
            ],
            request_fields: vec![
                RequestFieldSpec {
                    name: "schema_name".to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "対象スキーマ名。allowlist に含まれる値のみ指定できます。".to_string(),
                },
                RequestFieldSpec {
                    name: "table_name".to_string(),
                    required: true,
                    data_type: "string".to_string(),
                    description: "対象テーブル名。".to_string(),
                },
                RequestFieldSpec {
                    name: "selector".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description: "検索条件。値には string / number / bool / null を使用できます。".to_string(),
                },
                RequestFieldSpec {
                    name: "search_mode".to_string(),
                    required: false,
                    data_type: "`and_` | `or_`".to_string(),
                    description: "selector の結合方法。省略時は `or_` です。".to_string(),
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
                    description: "POST /update 用の更新値。POST /read では指定できません。".to_string(),
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
                    description: "必須項目不足、許可外スキーマ、不正カラム、不正 JSON のときに返します。".to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行に失敗したときに返します。".to_string(),
                },
            ],
            upsert_responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "{\"result\":\"update|insert\",\"created_id\":number|null}"
                        .to_string(),
                    description: "insert 時は auto increment の ID を created_id に返します。".to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description: "必須項目不足、許可外スキーマ、不正カラム、不正 JSON のときに返します。".to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行に失敗したときに返します。".to_string(),
                },
            ],
        },
        table_endpoints,
    })
}

async fn fetch_columns_by_table(
    pool: &MySqlPool,
    table_descriptors: &[TableEndpointDescriptor],
    default_schema: &str,
) -> Result<BTreeMap<String, Vec<TableColumnSpec>>, sqlx::Error> {
    let mut columns_by_table = BTreeMap::new();
    if table_descriptors.is_empty() {
        return Ok(columns_by_table);
    }

    let mut query_builder = QueryBuilder::<MySql>::new(
        "SELECT \
             CAST(TABLE_NAME AS CHAR(255)) AS table_name, \
             CAST(COLUMN_NAME AS CHAR(255)) AS column_name, \
             CAST(DATA_TYPE AS CHAR(255)) AS data_type, \
             CAST(COLUMN_TYPE AS CHAR(255)) AS column_type, \
             CAST(IS_NULLABLE AS CHAR(8)) AS is_nullable, \
             CAST(COLUMN_KEY AS CHAR(32)) AS column_key, \
             ORDINAL_POSITION AS ordinal_position \
         FROM information_schema.columns \
         WHERE table_schema = ",
    );

    query_builder.push_bind(default_schema);
    query_builder.push(" AND TABLE_NAME IN (");

    {
        let mut separated = query_builder.separated(", ");
        for descriptor in table_descriptors {
            separated.push_bind(descriptor.table_name);
        }
    }

    query_builder.push(") ORDER BY TABLE_NAME, ORDINAL_POSITION");

    let rows: Vec<InformationSchemaColumnRow> = query_builder
        .build_query_as::<InformationSchemaColumnRow>()
        .fetch_all(pool)
        .await?;

    for row in rows {
        columns_by_table
            .entry(row.table_name.clone())
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

fn build_get_sample_request(
    default_schema: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
) -> String {
    match columns.first() {
        Some(column) => format!(
            "{TABLE_READ_ROUTE}?{TABLE_SCHEMA_QUERY_PARAM}={default_schema}&{TABLE_NAME_QUERY_PARAM}={table_name}&{}=<value>",
            column.name
        ),
        None => format!(
            "{TABLE_READ_ROUTE}?{TABLE_SCHEMA_QUERY_PARAM}={default_schema}&{TABLE_NAME_QUERY_PARAM}={table_name}"
        ),
    }
}

fn build_post_read_sample_request(
    default_schema: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
) -> String {
    let selector_column = columns
        .first()
        .map(|column| column.name.clone())
        .unwrap_or_else(|| "example_column".to_string());

    serde_json::to_string_pretty(&json!({
        "schema_name": default_schema,
        "table_name": table_name,
        "search_mode": "and_",
        "selector": {
            selector_column: "<value>"
        }
    }))
    .expect("sample JSON must be serializable")
}

fn build_post_upsert_sample_request(
    default_schema: &str,
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
        "schema_name": default_schema,
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
