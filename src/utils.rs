use std::collections::HashMap;

use sqlx::mysql::MySqlRow;
use sqlx::{FromRow, MySql, MySqlPool};

use crate::database_models::models::TableReadModel;
use crate::models::ApiSpecification;
use crate::settings::constants::TABLE_NAME_QUERY_PARAM;

#[derive(Debug)]
pub enum TableReadError {
    TableNameMismatch {
        expected: &'static str,
        actual: String,
    },
    InvalidColumn(String),
    QueryFailed(sqlx::Error),
}

impl TableReadError {
    pub fn message(&self) -> String {
        match self {
            Self::TableNameMismatch { expected, actual } => {
                format!(
                    "table_name パラメータが不正です。expected={expected}, actual={actual}"
                )
            }
            Self::InvalidColumn(column) => {
                format!("不正な検索カラムです: {column}")
            }
            Self::QueryFailed(error) => {
                format!("テーブルデータの取得に失敗しました: {error}")
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

pub fn validate_filter_columns(
    api_spec: &ApiSpecification,
    table_name: &str,
    params: &HashMap<String, String>,
) -> Result<(), TableReadError> {
    let allowed_columns = api_spec
        .table_read_api
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
        .unwrap_or_default();

    for column in params.keys() {
        if column == TABLE_NAME_QUERY_PARAM {
            continue;
        }

        if !is_safe_identifier(column) || !allowed_columns.iter().any(|name| name == column) {
            return Err(TableReadError::InvalidColumn(column.clone()));
        }
    }

    Ok(())
}

pub async fn fetch_table_rows<R>(
    pool: &MySqlPool,
    params: &HashMap<String, String>,
) -> Result<Vec<R>, TableReadError>
where
    R: TableReadModel + for<'row> FromRow<'row, MySqlRow> + Send + Unpin + 'static,
{
    if let Some(table_name) = params.get(TABLE_NAME_QUERY_PARAM) {
        if table_name != R::TABLE_NAME {
            return Err(TableReadError::TableNameMismatch {
                expected: R::TABLE_NAME,
                actual: table_name.clone(),
            });
        }
    }

    let mut select_query = format!("SELECT * FROM `{}` WHERE 1 = 1", R::TABLE_NAME);
    let mut bind_values = Vec::new();

    let mut columns: Vec<&String> = params.keys().collect();
    columns.sort();

    for column in columns {
        if column.as_str() == TABLE_NAME_QUERY_PARAM {
            continue;
        }

        let Some(value) = params.get(column) else {
            continue;
        };

        if value.is_empty() {
            continue;
        }

        if !is_safe_identifier(column) {
            return Err(TableReadError::InvalidColumn(column.clone()));
        }

        select_query.push_str(&format!(" AND `{}` = ?", column));
        bind_values.push(value.clone());
    }

    let mut query = sqlx::query_as::<MySql, R>(&select_query);
    for value in bind_values {
        query = query.bind(value);
    }

    query
        .fetch_all(pool)
        .await
        .map_err(TableReadError::QueryFailed)
}
