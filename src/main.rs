mod app_state;
mod assets;
mod database_models;
mod models;
mod routes;
mod services;
mod settings;
mod utils;


use actix_web::{web, App, HttpServer};
use app_state::build_app_state;
use std::env;

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

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let bind_address = build_bind_address();
    let state = web::Data::new(build_app_state().await);

    println!("ProjectHubV2 listening on http://{bind_address}");
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .configure(routes::configure_routes)
            .configure(services::table_read_service::configure)
    })
    .bind(bind_address)?
    .run()
    .await
}
