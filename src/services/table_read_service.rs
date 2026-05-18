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
use crate::settings::constants::{TABLE_NAME_QUERY_PARAM, TABLE_READ_ROUTE, TABLE_UPDATE_ROUTE};
use crate::utils::{
    TableApiError, fetch_table_rows, fetch_table_rows_from_selector, upsert_table_row,
    validate_filter_columns, validate_post_request,
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
        $request:expr,
        $state:expr,
        $params:expr,
        $request_path:expr,
        $( $registered_table_name:literal => $model:ty ),+ $(,)?
    ) => {
        match $table_name {
            $(
                $registered_table_name => {
                    read_table::<$model>($request, $state, $params).await
                }
            ),+,
            _ => build_error_response(
                $request_path,
                TableApiError::InvalidRequest(format!(
                    "未対応の table_name です: {}",
                    $table_name
                )),
            ),
        }
    };
}

macro_rules! dispatch_post_read_table {
    (
        $table_name:expr,
        $request_path:expr,
        $state:expr,
        $payload:expr,
        $( $registered_table_name:literal => $model:ty ),+ $(,)?
    ) => {
        match $table_name {
            $(
                $registered_table_name => {
                    post_read_table::<$model>($request_path, $state, $payload).await
                }
            ),+,
            _ => build_error_response(
                $request_path,
                TableApiError::InvalidRequest(format!(
                    "未対応の table_name です: {}",
                    $table_name
                )),
            ),
        }
    };
}

macro_rules! dispatch_post_update_table {
    (
        $table_name:expr,
        $request_path:expr,
        $state:expr,
        $payload:expr,
        $( $registered_table_name:literal => $model:ty ),+ $(,)?
    ) => {
        match $table_name {
            $(
                $registered_table_name => {
                    post_update_table::<$model>($request_path, $state, $payload).await
                }
            ),+,
            _ => build_error_response(
                $request_path,
                TableApiError::InvalidRequest(format!(
                    "未対応の table_name です: {}",
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

/// `table_name` クエリパラメータで対象テーブルを選ぶ GET を処理します。
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
                "GET では table_name クエリパラメータを指定してください。".to_string(),
            ),
        );
    };

    with_table_read_models!(
        dispatch_read_table,
        table_name,
        request,
        state,
        params,
        request_path.as_str()
    )
}

/// JSON ボディで検索を行う POST `/read` を処理します。
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
                "POST /read では JSON の table_name を指定してください。".to_string(),
            ),
        );
    };

    if payload.values.is_some() {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "JSON 検索では values を指定できません。upsert は /system_api_server/si/v1/execute/sql/update を使用してください。".to_string(),
            ),
        );
    }

    with_table_read_models!(
        dispatch_post_read_table,
        table_name,
        request_path.as_str(),
        state,
        payload
    )
}

/// JSON ボディで upsert を行う POST `/update` を処理します。
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
                "POST /update では JSON の table_name を指定してください。".to_string(),
            ),
        );
    };

    if payload.values.is_none() {
        return build_error_response(
            &request_path,
            TableApiError::InvalidRequest(
                "upsert では values を指定してください。JSON 検索は /system_api_server/si/v1/execute/sql/read を使用してください。".to_string(),
            ),
        );
    }

    with_table_read_models!(
        dispatch_post_update_table,
        table_name,
        request_path.as_str(),
        state,
        payload
    )
}

/// 型付き GET 読み取り処理です。
pub async fn read_table<R>(
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

    match fetch_table_rows::<R>(&state.db, &params.0).await {
        Ok(result) => HttpResponse::Ok().json(result),
        Err(error) => build_error_response(request.path(), error),
    }
}

/// 型付き POST `/read` 検索処理です。
pub async fn post_read_table<R>(
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

/// 型付き POST `/update` upsert 処理です。
pub async fn post_update_table<R>(
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

    match upsert_table_row::<R>(&state.db, &payload).await {
        Ok(result) => HttpResponse::Ok().json(result),
        Err(error) => build_error_response(request_path, error),
    }
}

fn parse_post_request(body: &web::Bytes) -> Result<TablePostRequest, TableApiError> {
    if body.is_empty() {
        return Err(TableApiError::InvalidRequest(
            "POST では JSON ボディを指定してください。".to_string(),
        ));
    }

    serde_json::from_slice::<TablePostRequest>(body).map_err(|error| {
        TableApiError::InvalidRequest(format!("JSON ボディの解析に失敗しました: {error}"))
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
