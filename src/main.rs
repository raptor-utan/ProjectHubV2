mod app_state;
mod assets;
mod models;
mod routes;
mod database;
mod database_models;

use actix_web::{web, App, HttpResponse, HttpServer};
use app_state::build_app_state;
use std::env;
use sqlx::MySqlPool;
use crate::app_state::AppState;
use serde_json::Value;

use serde::{Deserialize, Serialize};

const DEFAULT_HOST: &str = "127.0.0.1";
const DEFAULT_PORT: u16 = 8080;

fn build_bind_address() -> String {
    let host = env::var("PROJECT_HUB_HOST").unwrap_or_else(|_| DEFAULT_HOST.to_string());
    let port = env::var("PROJECT_HUB_PORT")
        .ok()
        .and_then(|value| value.parse::<u16>().ok())
        .unwrap_or(DEFAULT_PORT);

    format!("{host}:{port}")
}

async fn test_index(state: web::Data<AppState>) -> impl actix_web::Responder {
    let pool = &state.db;

    let result = sqlx::query("SELECT * FROM ifs_projects_table LIMIT 10")
        .fetch_one(pool)
        .await
        .expect("Failed to fetch projects");
    HttpResponse::Ok().json(Value::Object(result.into_iter().collect()))
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
                web::resource("/test_index")
                    .route(web::get().to(test_index))
            )
    })
    .bind(bind_address)?
    .run()
    .await
}