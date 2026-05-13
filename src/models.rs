use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct ProjectSnapshot {
    #[serde(default)]
    pub fetched_at: String,
    #[serde(default)]
    pub source: String,
    #[serde(default)]
    pub database_tables: Vec<String>,
    #[serde(default)]
    pub project_tables: Vec<String>,
    #[serde(default)]
    pub fetch_warnings: Vec<String>,
    #[serde(default)]
    pub projects: Vec<ProjectSummary>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct ProjectSummary {
    pub unique_project_id: String,
    pub project_name: String,
    pub client_name: Option<String>,
    pub status: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
pub struct DatabaseInfoResponse {
    pub fetched_at: String,
    pub source: String,
    pub database_tables: Vec<String>,
    pub project_tables: Vec<String>,
}

#[derive(Clone, Debug, Serialize)]
pub struct LegacyRoute {
    pub method: &'static str,
    pub path: &'static str,
    pub name: &'static str,
    pub migration_status: MigrationStatus,
    pub note: &'static str,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum MigrationStatus {
    Implemented,
    ReadOnly,
    Placeholder,
}

#[derive(Debug, Serialize)]
pub struct ApiMessage {
    pub status: &'static str,
    pub message: String,
    pub path: String,
}

pub fn legacy_routes() -> Vec<LegacyRoute> {
    vec![
        LegacyRoute {
            method: "GET",
            path: "/",
            name: "トップ",
            migration_status: MigrationStatus::Implemented,
            note: "Rust 版ダッシュボードを表示します。",
        },
        LegacyRoute {
            method: "GET",
            path: "/api/projects",
            name: "プロジェクト一覧 API",
            migration_status: MigrationStatus::ReadOnly,
            note: "MCP 取得済みスナップショットを返します。",
        },
        LegacyRoute {
            method: "GET",
            path: "/api/database",
            name: "DB メタ情報 API",
            migration_status: MigrationStatus::ReadOnly,
            note: "MCP 取得済みのテーブル一覧を返します。",
        },
        LegacyRoute {
            method: "GET",
            path: "/api/routes",
            name: "移植状況 API",
            migration_status: MigrationStatus::Implemented,
            note: "Python 版主要ルートの移植状態を返します。",
        },
        LegacyRoute {
            method: "GET",
            path: "/login",
            name: "ログイン画面",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。認証処理は未移植です。",
        },
        LegacyRoute {
            method: "GET",
            path: "/select/group",
            name: "グループ選択",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "GET",
            path: "/dashboard/{jrc_group_name}",
            name: "ダッシュボード",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "GET",
            path: "/project/manage/incomplete/list/{jrc_group_name}",
            name: "未完了プロジェクト一覧",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "GET",
            path: "/project/manage/complete/list/{jrc_group_name}",
            name: "完了プロジェクト一覧",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "GET",
            path: "/project/manage/incomplete/gantt/{jrc_group_name}",
            name: "ガントチャート",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "GET",
            path: "/project/management/calender/{jrc_group_name}",
            name: "カレンダー",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "GET",
            path: "/project/manage/list/detail/{unique_project_id}",
            name: "プロジェクト詳細",
            migration_status: MigrationStatus::Placeholder,
            note: "画面入口のみ互換対応しています。",
        },
        LegacyRoute {
            method: "POST/PATCH/DELETE",
            path: "更新・帳票・通知系 API",
            name: "未移植 API",
            migration_status: MigrationStatus::Placeholder,
            note: "DB 更新、Excel/PDF、WebPush、バックグラウンド処理は 501 を返します。",
        },
    ]
}
