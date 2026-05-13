use crate::assets::PROJECT_SNAPSHOT_JSON;
use crate::models::{LegacyRoute, ProjectSnapshot, legacy_routes};

#[derive(Clone)]
pub struct AppState {
    pub snapshot: ProjectSnapshot,
    pub legacy_routes: Vec<LegacyRoute>,
}

pub fn build_app_state() -> AppState {
    let snapshot = serde_json::from_str::<ProjectSnapshot>(PROJECT_SNAPSHOT_JSON)
        .expect("data/project_snapshot.json must match ProjectSnapshot");

    AppState {
        snapshot,
        legacy_routes: legacy_routes(),
    }
}
