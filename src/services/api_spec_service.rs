use std::collections::BTreeMap;

use chrono::Local;
use serde_json::json;
use sqlx::{FromRow, MySql, MySqlPool, QueryBuilder};

use crate::models::{
    ApiSpecification, RequestFieldSpec, ResponseSpec, SupportEndpointSpec, TableColumnSpec,
    TableEndpointSpec, TableGetApiSpec, TablePostApiSpec,
};
use crate::services::table_read_service::{TableEndpointDescriptor, table_endpoint_descriptors};
use crate::settings::constants::{TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE, TABLE_UPDATE_ROUTE};

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

/// information_schema から現在のテーブル API 仕様を組み立てます。
pub async fn build_api_spec(pool: &MySqlPool) -> Result<ApiSpecification, sqlx::Error> {
    let table_descriptors = table_endpoint_descriptors();
    let columns_by_table = fetch_columns_by_table(pool, &table_descriptors).await?;

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
                    "{} は GET と POST /read では検索でき、POST /update では upsert できます。",
                    descriptor.table_name
                ),
                schema_found: !columns.is_empty(),
                get_sample_request: build_get_sample_request(descriptor.table_name, &columns),
                post_read_sample_request: build_post_read_sample_request(
                    descriptor.table_name,
                    &columns,
                ),
                post_upsert_sample_request: build_post_upsert_sample_request(
                    descriptor.table_name,
                    &columns,
                ),
                columns,
            }
        })
        .collect();

    Ok(ApiSpecification {
        title: "ProjectHubV2 API 仕様".to_string(),
        version: "1.1.0".to_string(),
        generated_at: Local::now().to_rfc3339(),
        overview: vec![
            "ProjectHubV2 は、接続中の MySQL テーブルをそのまま参照できるテーブル単位 API を提供します。"
                .to_string(),
            "GET はクエリ文字列による簡易検索、POST は JSON ボディによる詳細検索または upsert に使います。"
                .to_string(),
            "POST の selector では `and_` / `or_` を選べ、文字列に `%` を含めると LIKE 条件として扱います。"
                .to_string(),
            "POST に values を含めると、条件に合う先頭 1 件を更新し、見つからなければ selector と values を合わせて新規作成します。"
                .to_string(),
        ],
        support_endpoints: vec![
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/".to_string(),
                summary: "/manual へリダイレクトします。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/manual".to_string(),
                summary: "HTML 形式の API マニュアルを返します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/api/spec".to_string(),
                summary: "/manual が参照する JSON 形式の API 仕様を返します。".to_string(),
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
                format!(
                    "`{TABLE_NAME_QUERY_PARAM}` は必須です。値には対象テーブル名を指定してください。"
                ),
                "クエリ文字列のカラム名は現在のテーブルスキーマと完全一致している必要があります。"
                    .to_string(),
                "空文字のクエリ値は無視され、それ以外は AND 条件で検索されます。".to_string(),
                "文字列に `%` を含めると LIKE 条件として扱います。".to_string(),
            ],
            query_parameters: vec![
                RequestFieldSpec {
                    name: TABLE_NAME_QUERY_PARAM.to_string(),
                    required: true,
                    data_type: "string".to_string(),
                    description: "読み取り対象のテーブル名です。GET ではこのクエリパラメータのみでテーブルを指定します。"
                        .to_string(),
                },
                RequestFieldSpec {
                    name: "<column_name>".to_string(),
                    required: false,
                    data_type: "string".to_string(),
                    description: "一致または LIKE で検索する対象カラムです。".to_string(),
                },
            ],
            responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "テーブル行の JSON 配列".to_string(),
                    description: "一致した行をそのまま配列で返します。".to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description: "table_name 不一致や不正なカラム名を検出した場合に返します。"
                        .to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行またはテーブル参照に失敗した場合に返します。".to_string(),
                },
            ],
        },
        table_post_api: TablePostApiSpec {
            method: "POST".to_string(),
            read_route_pattern: TABLE_READ_ROUTE.to_string(),
            upsert_route_pattern: TABLE_UPDATE_ROUTE.to_string(),
            behavior: vec![
                "POST /read では JSON 条件検索を行い、`{\"result\":[...]}` を返します。"
                    .to_string(),
                "POST /update では JSON の table_name を使って対象テーブルを選び、upsert を行います。"
                    .to_string(),
                "POST /update の values は必須です。条件に合う先頭 1 件を更新し、見つからなければ新規作成します。"
                    .to_string(),
                "search_mode の既定値は `or_` です。`options.order_by` を指定すると一致候補の先頭判定は降順になります。"
                    .to_string(),
                "selector が空の upsert は更新を行わず、values と selector の内容をそのまま INSERT します。"
                    .to_string(),
            ],
            request_fields: vec![
                RequestFieldSpec {
                    name: "table_name".to_string(),
                    required: true,
                    data_type: "string".to_string(),
                    description: "POST /read と POST /update の対象テーブル名です。JSON ボディで必須です。".to_string(),
                },
                RequestFieldSpec {
                    name: "selector".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description: "検索条件です。各キーは実在カラム名、各値は文字列・数値・真偽値・null を指定できます。"
                        .to_string(),
                },
                RequestFieldSpec {
                    name: "search_mode".to_string(),
                    required: false,
                    data_type: "`and_` | `or_`".to_string(),
                    description: "selector の結合方法です。省略時は `or_` です。".to_string(),
                },
                RequestFieldSpec {
                    name: "options".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description: "`order_by` と `limit` を指定できます。order_by は降順です。"
                        .to_string(),
                },
                RequestFieldSpec {
                    name: "values".to_string(),
                    required: false,
                    data_type: "object".to_string(),
                    description: "指定すると upsert になります。INSERT 時は selector と values をマージし、values が優先されます。"
                        .to_string(),
                },
            ],
            read_responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "{\"result\":[...]}".to_string(),
                    description: "JSON 条件検索の結果を返します。".to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description: "JSON 解析失敗、不正なカラム、不正な値型などを返します。".to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行またはテーブル参照に失敗した場合に返します。".to_string(),
                },
            ],
            upsert_responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "{\"result\":\"update|insert\",\"created_id\":number|null}"
                        .to_string(),
                    description: "更新時は created_id が null、INSERT 時は auto increment があれば ID を返します。"
                        .to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description: "JSON 解析失敗、不正なカラム、不正な値型などを返します。".to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL 実行またはテーブル参照に失敗した場合に返します。".to_string(),
                },
            ],
        },
        table_endpoints,
    })
}

async fn fetch_columns_by_table(
    pool: &MySqlPool,
    table_descriptors: &[TableEndpointDescriptor],
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
         WHERE table_schema = DATABASE() AND TABLE_NAME IN (",
    );

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

fn build_get_sample_request(table_name: &str, columns: &[TableColumnSpec]) -> String {
    match columns.first() {
        Some(column) => format!(
            "{TABLE_READ_ROUTE}?{TABLE_NAME_QUERY_PARAM}={table_name}&{}=<value>",
            column.name
        ),
        None => format!("{TABLE_READ_ROUTE}?{TABLE_NAME_QUERY_PARAM}={table_name}"),
    }
}

fn build_post_read_sample_request(table_name: &str, columns: &[TableColumnSpec]) -> String {
    let selector_column = columns
        .first()
        .map(|column| column.name.clone())
        .unwrap_or_else(|| "example_column".to_string());

    serde_json::to_string_pretty(&json!({
        "table_name": table_name,
        "search_mode": "and_",
        "selector": {
            selector_column: "<value>"
        }
    }))
    .expect("sample JSON must be serializable")
}

fn build_post_upsert_sample_request(table_name: &str, columns: &[TableColumnSpec]) -> String {
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
