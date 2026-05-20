use std::collections::{BTreeMap, HashMap};

use actix_web::http::StatusCode;
use actix_web::{HttpRequest, HttpResponse, web};
use sqlx::mysql::MySqlPool;
use sqlx::{FromRow, MySql, QueryBuilder};

use crate::app_state::AppState;
use crate::models::{ApiMessage, TableColumnComment, TableMetadata, TableMetadataListResponse};
use crate::services::api_spec_service::TableAllowlistEntry;
use crate::settings::constants::{TABLE_METADATA_ROUTE, TABLE_SCHEMA_QUERY_PARAM};
use crate::utils::{TableApiError, validate_allowed_schema, validate_discoverable_schema};

pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(web::resource(TABLE_METADATA_ROUTE).route(web::get().to(get_table_metadata)));
}

#[derive(Debug, FromRow)]
struct InformationSchemaTableMetadataRow {
    table_schema: String,
    table_name: String,
    table_comment: String,
    column_name: String,
    column_comment: String,
}

/// allowlist 対象テーブルのテーブルコメントと列コメントを返します。
pub async fn get_table_metadata(
    request: HttpRequest,
    state: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
) -> HttpResponse {
    let request_path = request.path().to_string();
    let requested_schema_name = match params.get(TABLE_SCHEMA_QUERY_PARAM) {
        Some(value) if value.trim().is_empty() => {
            return build_error_response(
                &request_path,
                TableApiError::InvalidRequest("schema_name must not be empty".to_string()),
            );
        }
        Some(value) => {
            if let Err(error) = validate_allowed_schema(&state.allowed_schemas, value) {
                return build_error_response(&request_path, error);
            }

            if let Err(error) = validate_discoverable_schema(&state.api_spec, value) {
                return build_error_response(&request_path, error);
            }

            Some(value.as_str())
        }
        None => None,
    };

    let allowed_tables = collect_discoverable_allowed_tables(&state, requested_schema_name);
    match fetch_table_metadata(&state.db, &allowed_tables).await {
        Ok(tables) => HttpResponse::Ok().json(TableMetadataListResponse { tables }),
        Err(error) => build_error_response(&request_path, error),
    }
}

fn collect_discoverable_allowed_tables(
    state: &AppState,
    requested_schema_name: Option<&str>,
) -> Vec<TableAllowlistEntry> {
    state
        .api_spec
        .table_endpoints
        .iter()
        .filter(|endpoint| endpoint.schema_found)
        .filter(|endpoint| match requested_schema_name {
            Some(schema_name) => endpoint.schema_name == schema_name,
            None => true,
        })
        .map(|endpoint| TableAllowlistEntry {
            schema_name: endpoint.schema_name.clone(),
            table_name: endpoint.table_name.clone(),
        })
        .collect()
}

async fn fetch_table_metadata(
    pool: &MySqlPool,
    allowed_tables: &[TableAllowlistEntry],
) -> Result<Vec<TableMetadata>, TableApiError> {
    if allowed_tables.is_empty() {
        return Ok(Vec::new());
    }

    let rows = fetch_table_metadata_rows(pool, allowed_tables)
        .await
        .map_err(TableApiError::QueryFailed)?;

    Ok(build_table_metadata_list(rows))
}

async fn fetch_table_metadata_rows(
    pool: &MySqlPool,
    allowed_tables: &[TableAllowlistEntry],
) -> Result<Vec<InformationSchemaTableMetadataRow>, sqlx::Error> {
    let mut query_builder = QueryBuilder::<MySql>::new(
        "SELECT \
             tables.TABLE_SCHEMA AS table_schema, \
             tables.TABLE_NAME AS table_name, \
             tables.TABLE_COMMENT AS table_comment, \
             columns.COLUMN_NAME AS column_name, \
             columns.COLUMN_COMMENT AS column_comment \
         FROM information_schema.tables AS tables \
         INNER JOIN information_schema.columns AS columns \
             ON columns.TABLE_SCHEMA = tables.TABLE_SCHEMA \
             AND columns.TABLE_NAME = tables.TABLE_NAME \
         WHERE ",
    );

    append_allowed_table_conditions(&mut query_builder, allowed_tables);
    query_builder
        .push(" ORDER BY tables.TABLE_SCHEMA, tables.TABLE_NAME, columns.ORDINAL_POSITION");

    query_builder
        .build_query_as::<InformationSchemaTableMetadataRow>()
        .fetch_all(pool)
        .await
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
        query_builder.push("tables.TABLE_SCHEMA = ");
        query_builder.push_bind(&entry.schema_name);
        query_builder.push(" AND tables.TABLE_NAME = ");
        query_builder.push_bind(&entry.table_name);
        query_builder.push(")");
    }
}

fn build_table_metadata_list(rows: Vec<InformationSchemaTableMetadataRow>) -> Vec<TableMetadata> {
    let mut tables_by_name = BTreeMap::new();

    for row in rows {
        let table_metadata = tables_by_name
            .entry((row.table_schema.clone(), row.table_name.clone()))
            .or_insert_with(|| TableMetadata {
                schema_name: row.table_schema.clone(),
                table_name: row.table_name.clone(),
                table_comment: row.table_comment.clone(),
                columns: Vec::new(),
            });

        table_metadata.columns.push(TableColumnComment {
            column_name: row.column_name,
            column_comment: row.column_comment,
        });
    }

    tables_by_name.into_values().collect()
}

fn build_error_response(path: &str, error: TableApiError) -> HttpResponse {
    let status_code = match &error {
        TableApiError::TableNameMismatch { .. }
        | TableApiError::InvalidColumn(_)
        | TableApiError::InvalidRequest(_) => StatusCode::BAD_REQUEST,
        TableApiError::QueryFailed(_) => StatusCode::INTERNAL_SERVER_ERROR,
    };

    HttpResponse::build(status_code).json(ApiMessage {
        status: "error",
        message: error.message(),
        path: path.to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::{InformationSchemaTableMetadataRow, build_table_metadata_list};

    #[test]
    fn build_table_metadata_list_groups_columns_per_table() {
        let rows = vec![
            InformationSchemaTableMetadataRow {
                table_schema: "plango".to_string(),
                table_name: "users".to_string(),
                table_comment: "ユーザー".to_string(),
                column_name: "id".to_string(),
                column_comment: "ID".to_string(),
            },
            InformationSchemaTableMetadataRow {
                table_schema: "plango".to_string(),
                table_name: "users".to_string(),
                table_comment: "ユーザー".to_string(),
                column_name: "name".to_string(),
                column_comment: "名称".to_string(),
            },
            InformationSchemaTableMetadataRow {
                table_schema: "plango".to_string(),
                table_name: "projects".to_string(),
                table_comment: "案件".to_string(),
                column_name: "project_id".to_string(),
                column_comment: "案件ID".to_string(),
            },
        ];

        let tables = build_table_metadata_list(rows);

        assert_eq!(tables.len(), 2);
        assert_eq!(tables[0].table_name, "projects");
        assert_eq!(tables[0].columns.len(), 1);
        assert_eq!(tables[1].table_name, "users");
        assert_eq!(tables[1].columns.len(), 2);
        assert_eq!(tables[1].columns[0].column_name, "id");
        assert_eq!(tables[1].columns[1].column_comment, "名称");
    }
}
