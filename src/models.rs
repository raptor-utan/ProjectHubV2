use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Clone, Debug, Serialize)]
pub struct ApiMessage {
    pub status: &'static str,
    pub message: String,
    pub path: String,
}

#[derive(Clone, Debug, Serialize)]
pub struct HealthStatus {
    pub status: &'static str,
}

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq, Eq)]
pub enum SearchMode {
    #[serde(rename = "and_")]
    And,
    #[default]
    #[serde(rename = "or_")]
    Or,
}

impl SearchMode {
    pub fn sql_operator(self) -> &'static str {
        match self {
            Self::And => "AND",
            Self::Or => "OR",
        }
    }
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct QueryOptions {
    pub order_by: Option<String>,
    pub limit: Option<u64>,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct TablePostRequest {
    pub schema_name: Option<String>,
    pub table_name: Option<String>,
    #[serde(default)]
    pub selector: BTreeMap<String, Value>,
    #[serde(default)]
    pub search_mode: SearchMode,
    #[serde(default)]
    pub options: QueryOptions,
    #[serde(default)]
    pub values: Option<BTreeMap<String, Value>>,
}

#[derive(Clone, Debug, Serialize)]
pub struct QueryResult<T> {
    pub result: Vec<T>,
}

#[derive(Clone, Debug, Serialize)]
pub struct UpsertResult {
    pub result: &'static str,
    pub created_id: Option<u64>,
}

#[derive(Clone, Debug, Serialize)]
pub struct ApiSpecification {
    pub title: String,
    pub version: String,
    pub generated_at: String,
    pub overview: Vec<String>,
    pub allowed_schemas: Vec<String>,
    pub support_endpoints: Vec<SupportEndpointSpec>,
    pub table_get_api: TableGetApiSpec,
    pub table_post_api: TablePostApiSpec,
    pub table_endpoints: Vec<TableEndpointSpec>,
}

#[derive(Clone, Debug, Serialize)]
pub struct SupportEndpointSpec {
    pub method: String,
    pub path: String,
    pub summary: String,
}

#[derive(Clone, Debug, Serialize)]
pub struct RequestFieldSpec {
    pub name: String,
    pub required: bool,
    pub data_type: String,
    pub description: String,
}

#[derive(Clone, Debug, Serialize)]
pub struct TableGetApiSpec {
    pub method: String,
    pub route_pattern: String,
    pub filtering_behavior: Vec<String>,
    pub query_parameters: Vec<RequestFieldSpec>,
    pub responses: Vec<ResponseSpec>,
}

#[derive(Clone, Debug, Serialize)]
pub struct TablePostApiSpec {
    pub method: String,
    pub read_route_pattern: String,
    pub upsert_route_pattern: String,
    pub behavior: Vec<String>,
    pub request_fields: Vec<RequestFieldSpec>,
    pub read_responses: Vec<ResponseSpec>,
    pub upsert_responses: Vec<ResponseSpec>,
}

#[derive(Clone, Debug, Serialize)]
pub struct ResponseSpec {
    pub status: u16,
    pub body: String,
    pub description: String,
}

#[derive(Clone, Debug, Serialize)]
pub struct TableEndpointSpec {
    pub table_name: String,
    pub model_name: String,
    pub path: String,
    pub summary: String,
    pub schema_found: bool,
    pub get_sample_request: String,
    pub post_read_sample_request: String,
    pub post_upsert_sample_request: String,
    pub columns: Vec<TableColumnSpec>,
}

#[derive(Clone, Debug, Serialize)]
pub struct TableColumnSpec {
    pub name: String,
    pub data_type: String,
    pub column_type: String,
    pub nullable: bool,
    pub key_type: Option<String>,
    pub ordinal_position: u32,
}
