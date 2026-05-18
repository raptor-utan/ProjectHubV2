use std::collections::BTreeMap;

use chrono::Local;
use sqlx::{FromRow, MySql, MySqlPool, QueryBuilder};

use crate::models::{
    ApiSpecification, QueryParameterSpec, ResponseSpec, SupportEndpointSpec, TableColumnSpec,
    TableEndpointSpec, TableReadApiSpec,
};
use crate::services::table_read_service::{TableEndpointDescriptor, table_endpoint_descriptors};
use crate::settings::constants::{TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE_PREFIX};

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
            let path = format!("{TABLE_READ_ROUTE_PREFIX}{}", descriptor.table_name);

            TableEndpointSpec {
                table_name: descriptor.table_name.to_string(),
                model_name: descriptor.model_name.to_string(),
                path: path.clone(),
                summary: format!(
                    "{} の行データを完全一致フィルタ付きで返します。",
                    descriptor.table_name
                ),
                schema_found: !columns.is_empty(),
                sample_request: build_sample_request(&path, descriptor.table_name, &columns),
                columns,
            }
        })
        .collect();

    Ok(ApiSpecification {
        title: "ProjectHubV2 API仕様書".to_string(),
        version: "1.0.0".to_string(),
        generated_at: Local::now().to_rfc3339(),
        overview: vec![
            "ProjectHubV2 は現在、読み取り専用の MySQL テーブルAPIとAPIドキュメント公開に機能を絞っています。"
                .to_string(),
            "テーブルエンドポイントは GET のみを提供し、クエリ文字列は完全一致のSQL条件へ変換されます。"
                .to_string(),
            format!(
                "`{TABLE_NAME_QUERY_PARAM}` を指定する場合は、アクセス先パスのテーブル名と一致している必要があります。"
            ),
            "未定義の検索カラムは HTTP 400、DB実行失敗は HTTP 500 を返します。"
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
                summary: "HTML形式のAPIマニュアルを返します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/api/spec".to_string(),
                summary: "/manual が参照するJSON形式のAPI仕様を返します。".to_string(),
            },
            SupportEndpointSpec {
                method: "GET".to_string(),
                path: "/health".to_string(),
                summary: "ヘルスチェック結果を返します。".to_string(),
            },
        ],
        table_read_api: TableReadApiSpec {
            method: "GET".to_string(),
            route_prefix: TABLE_READ_ROUTE_PREFIX.to_string(),
            filtering_behavior: vec![
                "レスポンスに含まれる任意の列名をクエリパラメータとして指定できます。".to_string(),
                "複数の検索条件を指定した場合は AND 条件で評価します。".to_string(),
                "空文字のクエリ値は無視します。".to_string(),
                "列名は現在のテーブルスキーマと完全一致している必要があります。".to_string(),
            ],
            query_parameters: vec![
                QueryParameterSpec {
                    name: TABLE_NAME_QUERY_PARAM.to_string(),
                    required: false,
                    data_type: "文字列".to_string(),
                    description:
                        "互換用パラメータです。指定する場合はパス上のテーブル名と一致している必要があります。"
                            .to_string(),
                },
                QueryParameterSpec {
                    name: "<column_name>".to_string(),
                    required: false,
                    data_type: "文字列".to_string(),
                    description: "対象テーブルの任意の列名です。値は完全一致で検索されます。".to_string(),
                },
            ],
            responses: vec![
                ResponseSpec {
                    status: 200,
                    body: "JSON配列".to_string(),
                    description: "検索条件に一致した行配列を返します。".to_string(),
                },
                ResponseSpec {
                    status: 400,
                    body: "ApiMessage".to_string(),
                    description:
                        "table_name の不一致、または未定義カラムを指定した場合に返します。"
                            .to_string(),
                },
                ResponseSpec {
                    status: 500,
                    body: "ApiMessage".to_string(),
                    description: "SQL実行やテーブル参照に失敗した場合に返します。".to_string(),
                },
            ],
            table_endpoints,
        },
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

fn build_sample_request(
    path: &str,
    table_name: &str,
    columns: &[TableColumnSpec],
) -> String {
    match columns.first() {
        Some(column) => format!(
            "{path}?{TABLE_NAME_QUERY_PARAM}={table_name}&{}=<value>",
            column.name
        ),
        None => format!("{path}?{TABLE_NAME_QUERY_PARAM}={table_name}"),
    }
}
