use actix_web::http::header::{ContentType, LOCATION};
use actix_web::{HttpResponse, Responder, get, web};

use crate::app_state::AppState;
use crate::assets::{GUIDE_CSS, GUIDE_HTML, GUIDE_JS, MANUAL_CSS, MANUAL_HTML, MANUAL_JS};
use crate::models::HealthStatus;

pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(index)
        .service(manual)
        .service(manual_styles)
        .service(manual_script)
        .service(api_spec)
        .service(health);
}

#[get("/")]
async fn index() -> impl Responder {
    HttpResponse::TemporaryRedirect()
        .insert_header((LOCATION, "/manual"))
        .finish()
}

#[get("/manual")]
async fn manual() -> impl Responder {
    HttpResponse::Ok()
        .content_type(ContentType::html())
        .body(MANUAL_HTML)
}


#[get("/manual/styles.css")]
async fn manual_styles() -> impl Responder {
    HttpResponse::Ok()
        .content_type("text/css; charset=utf-8")
        .body(MANUAL_CSS)
}

#[get("/manual/app.js")]
async fn manual_script() -> impl Responder {
    HttpResponse::Ok()
        .content_type("application/javascript; charset=utf-8")
        .body(MANUAL_JS)
}

#[get("/api/spec")]
async fn api_spec(data: web::Data<AppState>) -> impl Responder {
    HttpResponse::Ok().json(&data.api_spec)
}

#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthStatus { status: "ok" })
}


#[get("/guide")]
async fn guide() -> impl Responder {
    HttpResponse::Ok()
        .content_type(ContentType::html())
        .body(GUIDE_HTML)
}

#[get("/guide/style.css")]
async fn guide_styles() -> impl Responder {
    HttpResponse::Ok()
        .content_type(ContentType::html())
        .body(GUIDE_CSS)
}

#[get("/guide/app.js")]
async fn guide_script() -> impl Responder {
    HttpResponse::Ok()
        .content_type(ContentType::html())
        .body(GUIDE_JS)
}
