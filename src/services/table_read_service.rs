use std::collections::HashMap;

use actix_web::http::StatusCode;
use actix_web::{HttpRequest, HttpResponse, web};

use crate::app_state::AppState;
use crate::models::{ApiMessage, QueryResult, TablePostRequest};
use crate::settings::constants::{
    TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE, TABLE_SCHEMA_QUERY_PARAM, TABLE_UPDATE_ROUTE,
};
use crate::utils::{
    TableApiError, fetch_table_rows, fetch_table_rows_from_selector, find_table_endpoint_spec,
    upsert_table_row, validate_allowed_schema, validate_discoverable_schema,
    validate_filter_columns, validate_post_request,
};

pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::resource(TABLE_READ_ROUTE)
            .route(web::get().to(read_table_by_query))
            .route(web::post().to(post_read_by_json)),
    );
    cfg.service(web::resource(TABLE_UPDATE_ROUTE).route(web::post().to(post_update_by_json)));
}

/// `table_name` と `schema_name` をクエリで受けてテーブル参照を行う。
pub async fn read_table_by_query(
    request: HttpRequest,
    state: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
) -> HttpResponse {
    let request_path = request.path().to_string();
    let Some(table_name) = params.get(TABLE_NAME_QUERY_PARAM).cloned() else {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "GET requires the table_name query parameter".to_string(),
            ),
        );
    };

    let schema_name = match resolve_query_schema_name(&params.0, &state) {
        Ok(schema_name) => schema_name,
        Err(error) => return build_error_response(&request_path, error),
    };

    read_table(
        schema_name.as_str(),
        table_name.as_str(),
        request,
        state,
        params,
    )
    .await
}

/// JSON ボディで条件検索を行う `POST /read` を処理する。
pub async fn post_read_by_json(
    request: HttpRequest,
    state: web::Data<AppState>,
    body: web::Bytes,
) -> HttpResponse {
    let request_path = request.path().to_string();
    let payload = match parse_post_request(&body) {
        Ok(payload) => payload,
        Err(error) => return build_error_response(&request_path, error),
    };

    let Some(table_name) = payload.table_name.clone() else {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "POST /read requires table_name in the JSON body".to_string(),
            ),
        );
    };

    let schema_name = match resolve_payload_schema_name(&payload, &state) {
        Ok(schema_name) => schema_name,
        Err(error) => return build_error_response(&request_path, error),
    };

    if payload.values.is_some() {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "POST /read does not accept values. Use /system_api_server/si/v1/execute/sql/update for upsert".to_string(),
            ),
        );
    }

    post_read_table(
        schema_name.as_str(),
        table_name.as_str(),
        request_path.as_str(),
        state,
        payload,
    )
    .await
}

/// JSON ボディで upsert を行う `POST /update` を処理する。
pub async fn post_update_by_json(
    request: HttpRequest,
    state: web::Data<AppState>,
    body: web::Bytes,
) -> HttpResponse {
    let request_path = request.path().to_string();
    let payload = match parse_post_request(&body) {
        Ok(payload) => payload,
        Err(error) => return build_error_response(&request_path, error),
    };

    let Some(table_name) = payload.table_name.clone() else {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "POST /update requires table_name in the JSON body".to_string(),
            ),
        );
    };

    let schema_name = match resolve_payload_schema_name(&payload, &state) {
        Ok(schema_name) => schema_name,
        Err(error) => return build_error_response(&request_path, error),
    };

    if payload.values.is_none() {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "POST /update requires values in the JSON body".to_string(),
            ),
        );
    }

    post_update_table(
        schema_name.as_str(),
        table_name.as_str(),
        request_path.as_str(),
        state,
        payload,
    )
    .await
}

/// テーブル定義に基づく GET テーブル参照を実行する。
pub async fn read_table(
    schema_name: &str,
    table_name: &str,
    request: HttpRequest,
    state: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
) -> HttpResponse {
    if let Err(error) = validate_filter_columns(&state.api_spec, schema_name, table_name, &params.0)
    {
        return build_error_response(request.path(), error);
    }

    let columns = match find_table_endpoint_spec(&state.api_spec, schema_name, table_name) {
        Ok(endpoint) => endpoint.columns.clone(),
        Err(error) => return build_error_response(request.path(), error),
    };

    match fetch_table_rows(&state.db, schema_name, table_name, &columns, &params.0).await {
        Ok(result) => HttpResponse::Ok().json(result),
        Err(error) => build_error_response(request.path(), error),
    }
}

/// テーブル定義に基づく POST `/read` 条件検索を実行する。
pub async fn post_read_table(
    schema_name: &str,
    table_name: &str,
    request_path: &str,
    state: web::Data<AppState>,
    payload: TablePostRequest,
) -> HttpResponse {
    if let Err(error) = validate_post_request(&state.api_spec, schema_name, table_name, &payload) {
        return build_error_response(request_path, error);
    }

    let columns = match find_table_endpoint_spec(&state.api_spec, schema_name, table_name) {
        Ok(endpoint) => endpoint.columns.clone(),
        Err(error) => return build_error_response(request_path, error),
    };

    match fetch_table_rows_from_selector(
        &state.db,
        schema_name,
        table_name,
        &columns,
        &payload.selector,
        payload.search_mode,
        &payload.options,
    )
    .await
    {
        Ok(result) => HttpResponse::Ok().json(QueryResult { result }),
        Err(error) => build_error_response(request_path, error),
    }
}

/// テーブル定義に基づく POST `/update` upsert を実行する。
pub async fn post_update_table(
    schema_name: &str,
    table_name: &str,
    request_path: &str,
    state: web::Data<AppState>,
    payload: TablePostRequest,
) -> HttpResponse {
    if let Err(error) = validate_post_request(&state.api_spec, schema_name, table_name, &payload) {
        return build_error_response(request_path, error);
    }

    match upsert_table_row(&state.db, schema_name, table_name, &payload).await {
        Ok(result) => HttpResponse::Ok().json(result),
        Err(error) => build_error_response(request_path, error),
    }
}

fn resolve_query_schema_name(
    params: &HashMap<String, String>,
    state: &AppState,
) -> Result<String, TableApiError> {
    let schema_name = resolve_requested_schema(
        params.get(TABLE_SCHEMA_QUERY_PARAM).map(String::as_str),
        &state.allowed_schemas,
        &state.default_schema,
    )?;

    validate_discoverable_schema(&state.api_spec, &schema_name)?;
    Ok(schema_name)
}

fn resolve_payload_schema_name(
    payload: &TablePostRequest,
    state: &AppState,
) -> Result<String, TableApiError> {
    let schema_name = resolve_requested_schema(
        payload.schema_name.as_deref(),
        &state.allowed_schemas,
        &state.default_schema,
    )?;

    validate_discoverable_schema(&state.api_spec, &schema_name)?;
    Ok(schema_name)
}

fn resolve_requested_schema(
    requested_schema_name: Option<&str>,
    allowed_schemas: &[String],
    default_schema: &str,
) -> Result<String, TableApiError> {
    let schema_name = match requested_schema_name {
        Some(value) if value.trim().is_empty() => {
            return Err(TableApiError::InvalidRequest(
                "schema_name must not be empty".to_string(),
            ));
        }
        Some(value) => value.to_string(),
        None => default_schema.to_string(),
    };

    validate_allowed_schema(allowed_schemas, &schema_name)?;
    Ok(schema_name)
}

fn parse_post_request(body: &web::Bytes) -> Result<TablePostRequest, TableApiError> {
    if body.is_empty() {
        return Err(TableApiError::InvalidRequest(
            "POST requests require a JSON body".to_string(),
        ));
    }

    serde_json::from_slice::<TablePostRequest>(body).map_err(|error| {
        TableApiError::InvalidRequest(format!("Failed to parse JSON body: {error}"))
    })
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
