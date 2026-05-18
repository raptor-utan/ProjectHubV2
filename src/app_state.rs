use sqlx::MySqlPool;
use sqlx::mysql::MySqlPoolOptions;

use crate::models::ApiSpecification;
use crate::services::api_spec_service::build_api_spec;

#[derive(Clone)]
pub struct AppState {
    pub db: MySqlPool,
    pub api_spec: ApiSpecification,
}

async fn generate_pool() -> MySqlPool {
    let database_uri = "mysql://dbuser:farad9Infinity%40@10.8.9.230:3306/ifs_reference_data";
    MySqlPoolOptions::new()
        .max_connections(10)
        .connect(database_uri)
        .await
        .expect("Failed to connect to database")
}

pub async fn build_app_state() -> AppState {
    let db = generate_pool().await;
    let api_spec = build_api_spec(&db)
        .await
        .expect("Failed to build API specification");

    AppState { db, api_spec }
}
