use crate::app_state::AppState;
use crate::assets::{APP_JS, INDEX_HTML, SERVICE_WORKER_JS, STYLES_CSS};
use crate::models::{ApiMessage, DatabaseInfoResponse};
use actix_web::http::header::ContentType;
use actix_web::{HttpRequest, HttpResponse, Responder, get, web};
use serde_json::json;

pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(index)
        .service(styles)
        .service(app_script)
        .service(projects)
        .service(database)
        .service(routes)
        .service(health)
        .service(service_worker)
        .service(service_worker_short)
        .service(
            web::resource("/login")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/logout")
                .route(web::get().to(logout))
                .route(web::post().to(logout)),
        )
        .service(
            web::resource("/select/group")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented))
                .route(web::delete().to(not_implemented)),
        )
        .service(
            web::resource("/dashboard/{jrc_group_name}")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/admin/feature/users")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/admin/users/external/create").route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/report/weekly")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/report/weekly/export/pdf")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/report/weekly/export/excel")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/management/calender/{jrc_group_name}")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/incomplete/gantt/{jrc_group_name}")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/process/comment")
                .route(web::get().to(process_comments))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/incomplete/list/{jrc_group_name}")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/incomplete/list/{jrc_group_name}/export")
                .route(web::get().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/incomplete/list/{jrc_group_name}/import")
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/complete/list/{jrc_group_name}")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/complete/list/{jrc_group_name}/export")
                .route(web::get().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/complete/list/{jrc_group_name}/import")
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/list/detail/{unique_project_id}")
                .route(web::get().to(index_page))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/action/complete")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/manage/update")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/project/tasks")
                .route(web::get().to(tasks))
                .route(web::post().to(not_implemented))
                .route(web::patch().to(not_implemented))
                .route(web::delete().to(not_implemented)),
        )
        .service(
            web::resource("/api/update/calender/date")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/api/notify")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(
            web::resource("/api/export")
                .route(web::get().to(not_implemented))
                .route(web::post().to(not_implemented)),
        )
        .service(web::resource("/background/merge").route(web::get().to(not_implemented)))
        .service(web::resource("/background/wt_maintenance").route(web::get().to(not_implemented)));
}

#[get("/")]
async fn index() -> impl Responder {
    index_response()
}

async fn index_page() -> impl Responder {
    index_response()
}

fn index_response() -> HttpResponse {
    HttpResponse::Ok()
        .content_type(ContentType::html())
        .body(INDEX_HTML)
}

#[get("/styles.css")]
async fn styles() -> impl Responder {
    HttpResponse::Ok()
        .content_type("text/css; charset=utf-8")
        .body(STYLES_CSS)
}

#[get("/app.js")]
async fn app_script() -> impl Responder {
    HttpResponse::Ok()
        .content_type("application/javascript; charset=utf-8")
        .body(APP_JS)
}

#[get("/service-worker.js")]
async fn service_worker() -> impl Responder {
    service_worker_response()
}

#[get("/sw.js")]
async fn service_worker_short() -> impl Responder {
    service_worker_response()
}

fn service_worker_response() -> HttpResponse {
    HttpResponse::Ok()
        .content_type("application/javascript; charset=utf-8")
        .body(SERVICE_WORKER_JS)
}

#[get("/api/projects")]
async fn projects(data: web::Data<AppState>) -> impl Responder {
    HttpResponse::Ok().json(&data.snapshot)
}

#[get("/api/database")]
async fn database(data: web::Data<AppState>) -> impl Responder {
    let snapshot = &data.snapshot;
    let response = DatabaseInfoResponse {
        fetched_at: snapshot.fetched_at.clone(),
        source: snapshot.source.clone(),
        database_tables: snapshot.database_tables.clone(),
        project_tables: snapshot.project_tables.clone(),
    };

    HttpResponse::Ok().json(response)
}

#[get("/api/routes")]
async fn routes(data: web::Data<AppState>) -> impl Responder {
    HttpResponse::Ok().json(&data.legacy_routes)
}

#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok().json(json!({ "status": "ok" }))
}

async fn logout(request: HttpRequest) -> impl Responder {
    HttpResponse::Ok().json(ApiMessage {
        status: "ok",
        message: "Rust 版ではサーバー側セッションを保持していません。".to_string(),
        path: request.path().to_string(),
    })
}

async fn tasks() -> impl Responder {
    HttpResponse::Ok().json(json!({
        "tasks": [],
        "warning": "タスク DB 連携は Rust 版へ未移植です。"
    }))
}

async fn process_comments() -> impl Responder {
    HttpResponse::Ok().json(json!({
        "comments": [],
        "warning": "工程コメント DB 連携は Rust 版へ未移植です。"
    }))
}

async fn not_implemented(request: HttpRequest) -> impl Responder {
    HttpResponse::NotImplemented().json(ApiMessage {
        status: "not_implemented",
        message: "この Python 版機能は Rust 版へ未移植です。DB 更新や外部連携の仕様確認後に実装してください。".to_string(),
        path: request.path().to_string(),
    })
}
