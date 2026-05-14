use std::ptr::null;
use sqlx::mysql::MySqlPoolOptions;
use sqlx::{MySql, MySqlPool, Pool};
use crate::assets::PROJECT_SNAPSHOT_JSON;
use crate::models::{LegacyRoute, ProjectSnapshot, legacy_routes};

#[derive(Clone)]
pub struct AppState {
    pub snapshot: ProjectSnapshot,
    pub legacy_routes: Vec<LegacyRoute>,
    pub db: MySqlPool
}


async fn generate_pool() -> MySqlPool {
    let database_uri = "mysql://dbuser:farad9Infinity%40@10.8.9.230:3306/ifs_reference_data";
    let pool: MySqlPool = MySqlPoolOptions::new()
        .max_connections(10)
        .connect(database_uri)
        .await
        .expect("Failed to connect to database");
    pool
}

pub async fn build_app_state() -> AppState {
    let snapshot = serde_json::from_str::<ProjectSnapshot>(PROJECT_SNAPSHOT_JSON)
        .expect("data/project_snapshot.json must match ProjectSnapshot");
    AppState {
        snapshot,
        legacy_routes: legacy_routes(),
        db: generate_pool().await
    }
}
