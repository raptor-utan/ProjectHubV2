mod app_state;
mod assets;
mod models;
mod routes;
mod database;
mod database_models;
mod services;
mod repositories;
mod utils;
mod interface;

use crate::app_state::AppState;
use actix_web::{web, App, HttpResponse, HttpServer};
use app_state::build_app_state;
use std::collections::HashMap;
use std::env;

use crate::database_models::models::IfsProjectsTable;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

const DEFAULT_HOST: &str = "127.0.0.1";
const DEFAULT_PORT: u16 = 8080;

pub trait TableColumns{
    const COLUMNS: &'static [&'static str];
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct  ProjectSearchQuery {
    pub unique_project_id: Option<String>,
    pub project_id: Option<String>,
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

impl TableColumns for ProjectSearchQuery{
    const COLUMNS: &'static [&'static str] = &[
        "unique_project_id",
        "project_id",
        "sub_project_id",
        "sub_project_name",
        "department",
        "parent_sub_project_id",
        "variety",
        "sub_project_amount",
        "sub_project_cost",
    ];
}
fn build_bind_address() -> String {
    let host = env::var("PROJECT_HUB_HOST").unwrap_or_else(|_| DEFAULT_HOST.to_string());
    let port = env::var("PROJECT_HUB_PORT")
        .ok()
        .and_then(|value| value.parse::<u16>().ok())
        .unwrap_or(DEFAULT_PORT);

    format!("{host}:{port}")
}

async fn test_index(state: web::Data<AppState>, params: web::Query<ProjectSearchQuery>) -> impl actix_web::Responder {
    let mut sql = String::from("SELECT * FROM ifs_projects_table where 1 = 1");
    for column in ProjectSearchQuery::COLUMNS{
        let query_string = format!("{} = ?", column);
        sql.push_str(&query_string);
    }

    let unique_project_id = params.unique_project_id.clone();
    println!("{:?}", &unique_project_id);
    let pool = &state.db;
    let result = sqlx::query_as::<_, IfsProjectsTable>("SELECT * FROM ifs_projects_table where 1 = 1")
        .fetch_one(pool)
        .await
        .expect("Failed to fetch projects");
    HttpResponse::Ok().json(result)
}



#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let bind_address = build_bind_address();
    let state = web::Data::new(build_app_state().await);

    println!("ProjectHubV2 listening on http://{bind_address}");
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .service(
                web::resource("/system_api_server/si/v1/execute/sql/read")
                    .route(web::get().to(services::ifs_projects_table_service::ifs_projects_table_get_api))
            )
    })
    .bind(bind_address)?
    .run()
    .await
}