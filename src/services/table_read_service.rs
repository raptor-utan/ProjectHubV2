use std::collections::HashMap;

use actix_web::http::StatusCode;
use actix_web::{HttpRequest, HttpResponse, Responder, web};
use serde::Serialize;
use sqlx::FromRow;
use sqlx::mysql::MySqlRow;

use crate::app_state::AppState;
use crate::database_models::models::{
    BacklogTaskDateTable, BacklogTaskIdsTable, BacklogUsersTable, BluePrintAlertHistoryTable,
    BluePrintsAlertSettingTable, BluePrintsTable, BlueprintKindTable, DesignPlanTable,
    DeviceAssignTable, DeviceUsedHistoryTable, DrawingStatusTable, DvaHistoryTable,
    ExternalUsersTable, GroupKindTable, IfsComponentsTable, IfsProjectsTable,
    InformationEquipmentAssignTable, JrcUsersTable, MeasuringDeviceKindTable,
    NulabAccountsTable, PendingTable, ProcessKindTable, ProductionProcessTable,
    ProjectAssignTable, ProjectFullMergedTableWork, ProjectFullMergedTmp,
    ReferenceNumberTable, RequiredDrawingTypesTable, ShipmentAuthorizationHistoryTable,
    StatusKindTable, SystemProcessesTable, TableReadModel, UpdateHistory,
    UserAuthLevelTable, WorkItemKindTable, WorkTimeRecordTable,
};
use crate::models::ApiMessage;
use crate::settings::constants::TABLE_READ_ROUTE_PREFIX;
use crate::utils::{TableReadError, fetch_table_rows, validate_filter_columns};

#[derive(Clone, Copy, Debug)]
pub struct TableEndpointDescriptor {
    pub table_name: &'static str,
    pub model_name: &'static str,
}

macro_rules! with_table_read_models {
    ($callback:ident) => {
        $callback!(
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
    ($callback:ident, $arg:expr) => {
        $callback!(
            $arg,
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

macro_rules! register_table_read_routes {
    ($cfg:expr, $( $table_name:literal => $model:ty ),+ $(,)?) => {
        $(
            {
                let route_path = format!("{TABLE_READ_ROUTE_PREFIX}{}", $table_name);
                $cfg.service(
                    web::resource(route_path)
                        .route(web::get().to(read_table::<$model>)),
                );
            }
        )+
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

pub fn configure(cfg: &mut web::ServiceConfig) {
    with_table_read_models!(register_table_read_routes, cfg);
}

pub fn table_endpoint_descriptors() -> Vec<TableEndpointDescriptor> {
    with_table_read_models!(collect_table_endpoint_descriptors)
}

pub async fn read_table<R>(
    request: HttpRequest,
    state: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
) -> impl Responder
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

fn build_error_response(path: &str, error: TableReadError) -> HttpResponse {
    let status_code = match &error {
        TableReadError::TableNameMismatch { .. } | TableReadError::InvalidColumn(_) => {
            StatusCode::BAD_REQUEST
        }
        TableReadError::QueryFailed(_) => StatusCode::INTERNAL_SERVER_ERROR,
    };

    HttpResponse::build(status_code).json(ApiMessage {
        status: "error",
        message: error.message(),
        path: path.to_string(),
    })
}
