// Auto-generated from MySQL DDL. Review date/string columns according to actual data quality.

use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};
use rust_decimal::Decimal;
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BacklogTaskDateTable {
    pub unique_project_id: String,
    pub inspection_preparation_start_date: Option<String>,
    pub inspection_preparation_end_date: Option<String>,
    pub inspection_start_date: Option<String>,
    pub inspection_end_date: Option<String>,
    pub inspection_meeting_preparation_start_date: Option<String>,
    pub inspection_meeting_preparation_end_date: Option<String>,
    pub inspection_meeting_start_date: Option<String>,
    pub inspection_meeting_end_date: Option<String>,
    pub shipping_preparation_start_date: Option<String>,
    pub shipping_preparation_end_date: Option<String>,
    pub shipping_start_date: Option<String>,
    pub shipping_end_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BacklogTaskIdsTable {
    pub id: i32,
    pub unique_project_id: Option<String>,
    pub summary: Option<String>,
    pub issue_id: Option<i32>,
    pub parent: Option<bool>,
    pub backlog_pj_id: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BacklogUsersTable {
    pub id: i32,
    #[sqlx(rename = "userId")]
    #[serde(rename = "userId")]
    pub user_id: String,
    pub name: String,
    #[sqlx(rename = "roleType")]
    #[serde(rename = "roleType")]
    pub role_type: Option<i32>,
    pub lang: Option<String>,
    #[sqlx(rename = "mailAddress")]
    #[serde(rename = "mailAddress")]
    pub mail_address: Option<String>,
    #[sqlx(rename = "lastLoginTime")]
    #[serde(rename = "lastLoginTime")]
    pub last_login_time: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BluePrintsTable {
    pub id: i32,
    pub unique_project_id: Option<String>,
    pub blue_print_file_name: Option<String>,
    pub blue_print_kind_id: Option<i32>,
    pub blue_print_dl_link: Option<String>,
    pub downloaded: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BlueprintKindTable {
    pub blue_print_kind_id: i32,
    pub blue_print_kind_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BluePrintAlertHistoryTable {
    pub id: i32,
    pub unique_project_id: String,
    pub blue_print_kind_id: i32,
    pub status: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BluePrintsAlertSettingTable {
    pub id: i32,
    pub subproject_type_id: i32,
    pub blue_print_kind_id: i32,
    pub process_kind_id: i32,
    pub alert_offset_date: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DesignPlanTable {
    pub unique_project_id: String,
    pub components_list_date: Option<String>,
    pub drawing_release_date: Option<String>,
    pub inspection_guideline_date: Option<String>,
    pub dr_date: Option<String>,
    pub dve_date: Option<String>,
    pub incoming_inspection_date: Option<String>,
    pub inspection_meeting_date: Option<String>,
    pub dva_date: Option<String>,
    pub ship_date: Option<String>,
    pub completion_documents_date: Option<String>,
    pub years: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DeviceUsedHistoryTable {
    pub id: i32,
    pub unique_project_id: Option<String>,
    pub device_id: Option<String>,
    pub using_start_date: Option<NaiveDateTime>,
    pub using_end_date: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DrawingStatusTable {
    pub unique_project_id: String,
    pub blue_print_kind_id: Option<String>,
    pub status_id: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DvaHistoryTable {
    pub unique_project_id: String,
    pub sub_project_name: Option<String>,
    pub client_name: Option<String>,
    pub status: Option<String>,
    pub file_path: String,
    pub control_number: Option<String>,
    pub completion_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ExternalUsersTable {
    pub jrc_user_code: String,
    pub jrc_user_name: String,
    pub jrc_mail_address: Option<String>,
    pub jrc_group_id: i32,
    pub password: String,
    pub system_admin: bool,
    pub admin: bool,
    pub standard: bool,
    pub guest: bool,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct GroupKindTable {
    pub jrc_group_id: i32,
    pub jrc_group_name: Option<String>,
    pub jrc_group_code: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IfsComponentsTable {
    pub other_demand_sequence: f64,
    pub project_id: Option<String>,
    pub activity_sequence: Option<String>,
    pub site: Option<String>,
    pub digit_number: Option<String>,
    pub item_name: Option<String>,
    pub standard_planned_item: Option<String>,
    pub required_quantity: Option<String>,
    pub requested_quantity: Option<String>,
    pub allocated_quantity: Option<String>,
    pub received_quantity: Option<String>,
    pub shipped_quantity: Option<String>,
    pub allocated_at_receipt: Option<String>,
    pub receipt_date: Option<String>,
    pub shipment_date: Option<String>,
    pub allocatable: Option<String>,
    pub desired_delivery_date: Option<String>,
    pub arrangement_date: Option<String>,
    pub shipping_flag: Option<String>,
    pub manufacturing_number: Option<String>,
    pub supply_option: Option<String>,
    pub shipment_info_id: Option<String>,
    pub shipping_date: Option<String>,
    pub shape_name: Option<String>,
    pub assembly_sign: Option<String>,
    pub power_source: Option<String>,
    pub power_source_name: Option<String>,
    pub instruction_sign: Option<String>,
    pub destination: Option<String>,
    pub shipping_item_list_sign: Option<String>,
    pub prior_shipment_sign: Option<String>,
    pub instruction_notes: Option<String>,
    pub shipping_request_quantity: Option<String>,
    pub registration_date_time: Option<String>,
    pub registrant: Option<String>,
    pub update_date_time: Option<String>,
    pub updater: Option<String>,
    pub shipping_base: Option<String>,
    pub withdrawal_instruction_date: Option<String>,
    pub withdrawn_instruction_amount: Option<String>,
    pub withdrawal_destination: Option<String>,
    pub withdrawal_instruction_reg_date: Option<String>,
    pub sub_project_id: Option<String>,
    pub activity_name: Option<String>,
    pub parent_sub_project_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IfsProjectsTable {
    pub unique_project_id: String,
    pub project_id: String,
    pub sub_project_id: Option<String>,
    pub sub_project_name: Option<String>,
    pub department: Option<String>,
    pub parent_sub_project_id: Option<String>,
    pub variety: Option<String>,
    pub sub_project_amount: Option<String>,
    pub sub_project_cost: Option<String>,
    pub completion_request_date: Option<String>,
    pub completion_request: Option<String>,
    pub status: Option<String>,
    pub variety_name: Option<String>,
    pub project_name: Option<String>,
    pub accounting_completed: Option<String>,
    pub completion_date: Option<String>,
    pub initial_completion_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct InformationEquipmentAssignTable {
    pub information_device_id: String,
    pub serial_number: Option<String>,
    pub device_type_name: Option<String>,
    pub device_name: Option<String>,
    pub jrc_user_name: Option<String>,
    pub jrc_user_code: Option<String>,
    pub department: Option<String>,
    pub department2: Option<String>,
    pub jrc_group_id: Option<i32>,
    pub place: Option<String>,
    pub building_number: Option<String>,
    pub flore: Option<String>,
    pub device_variety_id: Option<i32>,
    pub ip_address: Option<String>,
    pub using_for: Option<String>,
    pub order: Option<String>,
    pub price_par_month: Option<String>,
    pub check_date: Option<String>,
    pub update_date: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct JrcUsersTable {
    pub jrc_user_code: String,
    pub jrc_user_name: Option<String>,
    pub jrc_mail_address: Option<String>,
    pub jrc_group_id: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MeasuringDeviceKindTable {
    pub device_id: String,
    pub device_name: Option<String>,
    pub device_type_name: Option<String>,
    pub device_maker: Option<String>,
    pub proofreading_date: Option<NaiveDate>,
    pub expiration_date: Option<NaiveDate>,
    pub external_rental: Option<bool>,
    pub lending_destination: Option<String>,
    pub remarks: Option<String>,
    pub lending: Option<bool>,
    pub update_date: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DeviceAssignTable {
    pub jrc_user_code: String,
    pub device_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct NulabAccountsTable {
    pub id: i32,
    pub user_id: String,
    pub nulab_id: Option<String>,
    pub name: Option<String>,
    pub unique_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PendingTable {
    pub id: i32,
    pub ask_date: Option<NaiveDateTime>,
    pub asker: Option<String>,
    pub feedback_text: Option<String>,
    pub responder: Option<String>,
    pub response_text: Option<String>,
    pub response_date: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProcessKindTable {
    pub process_kind_id: i32,
    pub process_kind_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProductionProcessTable {
    pub unique_project_id: String,
    pub process_kind_id: Option<i32>,
    pub start_date: Option<NaiveDateTime>,
    pub end_date: Option<NaiveDateTime>,
    pub plan_man_hours: Option<i32>,
    pub actual_man_hours: Option<i32>,
    pub incoming_inspection_date: Option<NaiveDateTime>,
    pub shipment_date: Option<NaiveDateTime>,
    pub inspection_meeting_date: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProjectAssignTable {
    pub id: i32,
    pub unique_project_id: Option<String>,
    pub jrc_user_code: Option<String>,
    pub inspection_ready: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProjectFullMergedTableWork {
    pub unique_project_id: Option<String>,
    pub project_id: String,
    pub sub_project_id: Option<String>,
    pub sub_project_name: Option<String>,
    pub department: Option<String>,
    pub parent_sub_project_id: Option<String>,
    pub variety: Option<String>,
    pub sub_project_amount: Option<String>,
    pub sub_project_cost: Option<String>,
    pub completion_request_date: Option<String>,
    pub completion_request: Option<String>,
    pub status: Option<String>,
    pub variety_name: Option<String>,
    pub project_name: Option<String>,
    pub accounting_completed: Option<String>,
    pub completion_date: Option<String>,
    pub initial_completion_date: Option<String>,
    pub inspection_preparation_start_date: Option<String>,
    pub inspection_preparation_end_date: Option<String>,
    pub inspection_start_date: Option<String>,
    pub inspection_end_date: Option<String>,
    pub inspection_meeting_preparation_start_date: Option<String>,
    pub inspection_meeting_preparation_end_date: Option<String>,
    pub inspection_meeting_start_date: Option<String>,
    pub inspection_meeting_end_date: Option<String>,
    pub shipping_preparation_start_date: Option<String>,
    pub shipping_preparation_end_date: Option<String>,
    pub shipping_start_date: Option<String>,
    pub shipping_end_date: Option<String>,
    pub client_name: Option<String>,
    pub contract_deadline: Option<String>,
    pub shipping_approval_date: Option<String>,
    pub progress: Option<String>,
    pub area_used: Option<String>,
    pub deployment_location: Option<String>,
    pub business_trip_start_date: Option<String>,
    pub business_trip_end_date: Option<String>,
    pub technical_manager: Option<String>,
    pub admin_manager: Option<String>,
    pub person_in_charge: Option<String>,
    pub worker: Option<String>,
    pub support_staff: Option<String>,
    pub case_name: Option<String>,
    pub man_hours: Option<String>,
    pub used_man_hours: Option<String>,
    pub comment: Option<String>,
    pub components_list_date: Option<String>,
    pub drawing_release_date: Option<String>,
    pub inspection_guideline_date: Option<String>,
    pub dr_date: Option<String>,
    pub dve_date: Option<String>,
    pub incoming_inspection_date: Option<String>,
    pub inspection_meeting_date: Option<String>,
    pub dva_date: Option<String>,
    pub ship_date: Option<String>,
    pub completion_documents_date: Option<String>,
    pub years: Option<String>,
    pub jrc_user_code: Option<String>,
    pub inspection_ready: Option<String>,
    pub complete: Option<String>,
    pub se_comment: Option<String>,
    pub ig_comment: Option<String>,
    pub partial_ship_date_1: Option<String>,
    pub partial_ship_date_2: Option<String>,
    pub partial_ship_date_3: Option<String>,
    pub partial_ship_date_4: Option<String>,
    pub partial_ship_date_5: Option<String>,
    pub partial_ship_date_6: Option<String>,
    pub partial_ship_date_7: Option<String>,
    pub partial_ship_date_8: Option<String>,
    pub partial_ship_date_9: Option<String>,
    pub responsible: Option<String>,
    pub sum_man_hours: Option<Decimal>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProjectFullMergedTmp {
    pub unique_project_id: Option<String>,
    pub project_id: String,
    pub sub_project_id: Option<String>,
    pub sub_project_name: Option<String>,
    pub department: Option<String>,
    pub parent_sub_project_id: Option<String>,
    pub variety: Option<String>,
    pub sub_project_amount: Option<String>,
    pub sub_project_cost: Option<String>,
    pub completion_request_date: Option<String>,
    pub completion_request: Option<String>,
    pub status: Option<String>,
    pub variety_name: Option<String>,
    pub project_name: Option<String>,
    pub accounting_completed: Option<String>,
    pub completion_date: Option<String>,
    pub initial_completion_date: Option<String>,
    pub inspection_preparation_start_date: Option<String>,
    pub inspection_preparation_end_date: Option<String>,
    pub inspection_start_date: Option<String>,
    pub inspection_end_date: Option<String>,
    pub inspection_meeting_preparation_start_date: Option<String>,
    pub inspection_meeting_preparation_end_date: Option<String>,
    pub inspection_meeting_start_date: Option<String>,
    pub inspection_meeting_end_date: Option<String>,
    pub shipping_preparation_start_date: Option<String>,
    pub shipping_preparation_end_date: Option<String>,
    pub shipping_start_date: Option<String>,
    pub shipping_end_date: Option<String>,
    pub client_name: Option<String>,
    pub contract_deadline: Option<String>,
    pub shipping_approval_date: Option<String>,
    pub progress: Option<String>,
    pub area_used: Option<String>,
    pub deployment_location: Option<String>,
    pub business_trip_start_date: Option<String>,
    pub business_trip_end_date: Option<String>,
    pub technical_manager: Option<String>,
    pub admin_manager: Option<String>,
    pub person_in_charge: Option<String>,
    pub worker: Option<String>,
    pub support_staff: Option<String>,
    pub case_name: Option<String>,
    pub man_hours: Option<String>,
    pub used_man_hours: Option<String>,
    pub comment: Option<String>,
    pub components_list_date: Option<String>,
    pub drawing_release_date: Option<String>,
    pub inspection_guideline_date: Option<String>,
    pub dr_date: Option<String>,
    pub dve_date: Option<String>,
    pub incoming_inspection_date: Option<String>,
    pub inspection_meeting_date: Option<String>,
    pub dva_date: Option<String>,
    pub ship_date: Option<String>,
    pub completion_documents_date: Option<String>,
    pub years: Option<String>,
    pub jrc_user_code: Option<String>,
    pub inspection_ready: Option<String>,
    pub complete: Option<String>,
    pub se_comment: Option<String>,
    pub ig_comment: Option<String>,
    pub partial_ship_date_1: Option<String>,
    pub partial_ship_date_2: Option<String>,
    pub partial_ship_date_3: Option<String>,
    pub partial_ship_date_4: Option<String>,
    pub partial_ship_date_5: Option<String>,
    pub partial_ship_date_6: Option<String>,
    pub partial_ship_date_7: Option<String>,
    pub partial_ship_date_8: Option<String>,
    pub partial_ship_date_9: Option<String>,
    pub responsible: Option<String>,
    pub sum_man_hours: Option<Decimal>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ReferenceNumberTable {
    pub id: i32,
    pub unique_project_id: Option<String>,
    pub reference_number: Option<String>,
    pub about_text: Option<String>,
    pub project_name: Option<String>,
    pub add_date: Option<NaiveDateTime>,
    pub jrc_user_name: Option<String>,
    pub jrc_user_code: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RequiredDrawingTypesTable {
    pub id: i32,
    pub sub_project_type: Option<String>,
    pub required_drawing_ids: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ShipmentAuthorizationHistoryTable {
    pub id: i32,
    pub unique_project_id: Option<String>,
    pub filename: Option<String>,
    pub number_of_files: Option<i32>,
    pub revision: Option<String>,
    pub added_date: Option<NaiveDateTime>,
    pub comment: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct StatusKindTable {
    pub status_id: i32,
    pub status_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct SystemProcessesTable {
    pub process_id: i32,
    pub process_ip_address: Option<String>,
    pub process_port_number: Option<String>,
    pub process_name: Option<String>,
    pub process_alive_status: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UpdateHistory {
    pub id: i32,
    pub process_id: i32,
    pub process_name: Option<String>,
    pub update_date: Option<NaiveDateTime>,
    pub update_comment: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserAuthLevelTable {
    pub jrc_user_code: String,
    pub system_admin: bool,
    pub admin: Option<bool>,
    pub standard: bool,
    pub guest: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct WorkItemKindTable {
    pub id: i32,
    pub item_number: String,
    pub item_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct WorkTimeRecordTable {
    pub id: i32,
    pub unique_project_id: String,
    pub jrc_user_code: String,
    pub process_kind_id: i32,
    pub start_date: Option<NaiveDateTime>,
    pub end_date: Option<NaiveDateTime>,
    pub item_number: Option<String>,
    pub one_time_bind_user_code: Option<String>,
}
