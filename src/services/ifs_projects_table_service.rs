use std::collections::HashMap;
use actix_web::{web, HttpResponse};
use crate::app_state::AppState;
use crate::database_models::models::IfsProjectsTable;
use crate::interface::user_request_json::JsonRequest;
use crate::ProjectSearchQuery;
use crate::utils::fetch_data_with_params;

pub async fn ifs_projects_table_get_api(state: web::Data<AppState>, params: web::Query<HashMap<String,String>>) -> impl actix_web::Responder {
    let result = fetch_data_with_params::<IfsProjectsTable, ProjectSearchQuery>(&state.db, params).await;
    HttpResponse::Ok().json(result)
}

// pub async fn ifs_projects_table_post_api(state: web::Data<AppState>, params: web::Query<JsonRequest>) -> impl actix_web::Responder {
//     let result = fetch_data_with_params::<IfsProjectsTable, ProjectSearchQuery>(&state.db, params).await;
//     HttpResponse::Ok().json(result)
// }