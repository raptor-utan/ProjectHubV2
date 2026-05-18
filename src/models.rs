use serde::Serialize;

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

#[derive(Clone, Debug, Serialize)]
pub struct ApiSpecification {
    pub title: String,
    pub version: String,
    pub generated_at: String,
    pub overview: Vec<String>,
    pub support_endpoints: Vec<SupportEndpointSpec>,
    pub table_read_api: TableReadApiSpec,
}

#[derive(Clone, Debug, Serialize)]
pub struct SupportEndpointSpec {
    pub method: String,
    pub path: String,
    pub summary: String,
}

#[derive(Clone, Debug, Serialize)]
pub struct TableReadApiSpec {
    pub method: String,
    pub route_prefix: String,
    pub filtering_behavior: Vec<String>,
    pub query_parameters: Vec<QueryParameterSpec>,
    pub responses: Vec<ResponseSpec>,
    pub table_endpoints: Vec<TableEndpointSpec>,
}

#[derive(Clone, Debug, Serialize)]
pub struct QueryParameterSpec {
    pub name: String,
    pub required: bool,
    pub data_type: String,
    pub description: String,
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
    pub sample_request: String,
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
