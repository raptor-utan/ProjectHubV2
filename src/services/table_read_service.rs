use std::collections::HashMap;

use actix_web::http::StatusCode;
use actix_web::{HttpRequest, HttpResponse, web};
use serde::Serialize;
use sqlx::FromRow;
use sqlx::mysql::MySqlRow;

use crate::app_state::AppState;
use crate::database_models::models::{
    BacklogTaskDateTable, BacklogTaskIdsTable, BacklogUsersTable, BluePrintAlertHistoryTable,
    BluePrintsAlertSettingTable, BluePrintsTable, BlueprintKindTable, DesignPlanTable,
    DeviceAssignTable, DeviceUsedHistoryTable, DrawingStatusTable, DvaHistoryTable,
    ExternalUsersTable, GroupKindTable, IfsComponentsTable, IfsProjectsTable,
    InformationEquipmentAssignTable, JrcUsersTable, MeasuringDeviceKindTable, NulabAccountsTable,
    PendingTable, ProcessKindTable, ProductionProcessTable, ProjectAssignTable,
    ProjectFullMergedTableWork, ProjectFullMergedTmp, ReferenceNumberTable,
    RequiredDrawingTypesTable, ShipmentAuthorizationHistoryTable, StatusKindTable,
    SystemProcessesTable, TableReadModel, UpdateHistory, UserAuthLevelTable, WorkItemKindTable,
    WorkTimeRecordTable,
};
use crate::models::{ApiMessage, QueryResult, TablePostRequest};
use crate::settings::constants::{
    TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE, TABLE_SCHEMA_QUERY_PARAM, TABLE_UPDATE_ROUTE,
};
use crate::utils::{
    TableApiError, fetch_table_rows, fetch_table_rows_from_selector, upsert_table_row,
    validate_allowed_schema, validate_filter_columns, validate_post_request,
};

#[derive(Clone, Copy, Debug)]
pub struct TableEndpointDescriptor {
    pub table_name: &'static str,
    pub model_name: &'static str,
}

macro_rules! with_table_read_models {
    ($callback:ident $(, $args:expr )* $(,)?) => {
        $callback!(
            $( $args, )*
            "backlog_task_date_table" => BacklogTaskDateTable,
            "backlog_task_ids_table" => BacklogTaskIdsTable,
            "backlog_users_table" => BacklogUsersTable,
            "blue_prints_table" => BluePrintsTable,
            "blueprint_kind_table" => BlueprintKindTable,
            "blue_print_alert_history_table" => BluePrintAlertHistoryTable,
            "blue_prints_alert_setting_table" => BluePrintsAlertSettingTable,
            "design_plan_table" => DesignPlanTable,
            "device_used_history_table" => DeviceUsedHistoryTable,
            "drawing_status_table" => DrawingStatusTable,
            "dva_history_table" => DvaHistoryTable,
            "external_users_table" => ExternalUsersTable,
            "group_kind_table" => GroupKindTable,
            "ifs_components_table" => IfsComponentsTable,
            "ifs_projects_table" => IfsProjectsTable,
            "information_equipment_assign_table" => InformationEquipmentAssignTable,
            "jrc_users_table" => JrcUsersTable,
            "measuring_device_kind_table" => MeasuringDeviceKindTable,
            "device_assign_table" => DeviceAssignTable,
            "nulab_accounts_table" => NulabAccountsTable,
            "pending_table" => PendingTable,
            "process_kind_table" => ProcessKindTable,
            "production_process_table" => ProductionProcessTable,
            "project_assign_table" => ProjectAssignTable,
            "project_full_merged_table_work" => ProjectFullMergedTableWork,
            "project_full_merged_tmp" => ProjectFullMergedTmp,
            "reference_number_table" => ReferenceNumberTable,
            "required_drawing_types_table" => RequiredDrawingTypesTable,
            "shipment_authorization_history_table" => ShipmentAuthorizationHistoryTable,
            "status_kind_table" => StatusKindTable,
            "system_processes_table" => SystemProcessesTable,
            "update_history" => UpdateHistory,
            "user_auth_level_table" => UserAuthLevelTable,
            "work_item_kind_table" => WorkItemKindTable,
            "work_time_record_table" => WorkTimeRecordTable,
        )
    };
}

macro_rules! collect_table_endpoint_descriptors {
    ($( $table_name:literal => $model:ty ),+ $(,)?) => {
        vec![
            $(
                TableEndpointDescriptor {
                    table_name: $table_name,
                    model_name: stringify!($model),
                }
            ),+
        ]
    };
}

macro_rules! dispatch_read_table {
    (
        $table_name:expr,
        $schema_name:expr,
        $request:expr,
        $state:expr,
        $params:expr,
        $request_path:expr,
        $( $registered_table_name:literal => $model:ty ),+ $(,)?
    ) => {
        match $table_name {
            $(
                $registered_table_name => {
                    read_table::<$model>($schema_name, $request, $state, $params).await
                }
            ),+,
            _ => build_error_response(
                $request_path,
                TableApiError::InvalidRequest(format!(
                    "Unsupported table_name: {}",
                    $table_name
                )),
            ),
        }
    };
}

macro_rules! dispatch_post_read_table {
    (
        $table_name:expr,
        $schema_name:expr,
        $request_path:expr,
        $state:expr,
        $payload:expr,
        $( $registered_table_name:literal => $model:ty ),+ $(,)?
    ) => {
        match $table_name {
            $(
                $registered_table_name => {
                    post_read_table::<$model>($schema_name, $request_path, $state, $payload).await
                }
            ),+,
            _ => build_error_response(
                $request_path,
                TableApiError::InvalidRequest(format!(
                    "Unsupported table_name: {}",
                    $table_name
                )),
            ),
        }
    };
}

macro_rules! dispatch_post_update_table {
    (
        $table_name:expr,
        $schema_name:expr,
        $request_path:expr,
        $state:expr,
        $payload:expr,
        $( $registered_table_name:literal => $model:ty ),+ $(,)?
    ) => {
        match $table_name {
            $(
                $registered_table_name => {
                    post_update_table::<$model>($schema_name, $request_path, $state, $payload).await
                }
            ),+,
            _ => build_error_response(
                $request_path,
                TableApiError::InvalidRequest(format!(
                    "Unsupported table_name: {}",
                    $table_name
                )),
            ),
        }
    };
}

pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::resource(TABLE_READ_ROUTE)
            .route(web::get().to(read_table_by_query))
            .route(web::post().to(post_read_by_json)),
    );
    cfg.service(web::resource(TABLE_UPDATE_ROUTE).route(web::post().to(post_update_by_json)));
}

pub fn table_endpoint_descriptors() -> Vec<TableEndpointDescriptor> {
    with_table_read_models!(collect_table_endpoint_descriptors)
}

/// `table_name` と `schema_name` をクエリで受けてテーブル参照を行う。
pub async fn read_table_by_query(
    request: HttpRequest,
    state: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
) -> HttpResponse {
    let request_path = request.path().to_string();
    let Some(table_name) = params.get(TABLE_NAME_QUERY_PARAM).map(String::as_str) else {
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

    with_table_read_models!(
        dispatch_read_table,
        table_name,
        schema_name.as_str(),
        request,
        state,
        params,
        request_path.as_str()
    )
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

    let Some(table_name) = payload.table_name.as_deref() else {
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

    with_table_read_models!(
        dispatch_post_read_table,
        table_name,
        schema_name.as_str(),
        request_path.as_str(),
        state,
        payload
    )
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

    let Some(table_name) = payload.table_name.as_deref() else {
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

    with_table_read_models!(
        dispatch_post_update_table,
        table_name,
        schema_name.as_str(),
        request_path.as_str(),
        state,
        payload
    )
}

/// モデルに紐づく GET テーブル参照を実行する。
pub async fn read_table<R>(
    schema_name: &str,
    request: HttpRequest,
    state: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
) -> HttpResponse
where
    R: TableReadModel + Serialize + for<'row> FromRow<'row, MySqlRow> + Send + Unpin + 'static,
{
    if let Err(error) = validate_filter_columns(&state.api_spec, R::TABLE_NAME, &params.0) {
        return build_error_response(request.path(), error);
    }

    match fetch_table_rows::<R>(&state.db, schema_name, &params.0).await {
        Ok(result) => HttpResponse::Ok().json(result),
        Err(error) => build_error_response(request.path(), error),
    }
}

/// モデルに紐づく POST `/read` 条件検索を実行する。
pub async fn post_read_table<R>(
    schema_name: &str,
    request_path: &str,
    state: web::Data<AppState>,
    payload: TablePostRequest,
) -> HttpResponse
where
    R: TableReadModel + Serialize + for<'row> FromRow<'row, MySqlRow> + Send + Unpin + 'static,
{
    if let Err(error) = validate_post_request(&state.api_spec, R::TABLE_NAME, &payload) {
        return build_error_response(request_path, error);
    }

    match fetch_table_rows_from_selector::<R>(
        &state.db,
        schema_name,
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

/// モデルに紐づく POST `/update` upsert を実行する。
pub async fn post_update_table<R>(
    schema_name: &str,
    request_path: &str,
    state: web::Data<AppState>,
    payload: TablePostRequest,
) -> HttpResponse
where
    R: TableReadModel + Serialize + for<'row> FromRow<'row, MySqlRow> + Send + Unpin + 'static,
{
    if let Err(error) = validate_post_request(&state.api_spec, R::TABLE_NAME, &payload) {
        return build_error_response(request_path, error);
    }

    match upsert_table_row::<R>(&state.db, schema_name, &payload).await {
        Ok(result) => HttpResponse::Ok().json(result),
        Err(error) => build_error_response(request_path, error),
    }
}

fn resolve_query_schema_name(
    params: &HashMap<String, String>,
    state: &AppState,
) -> Result<String, TableApiError> {
    resolve_requested_schema(
        params.get(TABLE_SCHEMA_QUERY_PARAM).map(String::as_str),
        &state.allowed_schemas,
        &state.default_schema,
    )
}

fn resolve_payload_schema_name(
    payload: &TablePostRequest,
    state: &AppState,
) -> Result<String, TableApiError> {
    resolve_requested_schema(
        payload.schema_name.as_deref(),
        &state.allowed_schemas,
        &state.default_schema,
    )
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
