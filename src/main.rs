mod app_state;
mod assets;
mod models;
mod routes;
mod database;

use actix_web::{App, HttpServer, web};
use app_state::build_app_state;
use routes::configure_routes;
use std::env;

const DEFAULT_HOST: &str = "127.0.0.1";
const DEFAULT_PORT: u16 = 8080;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let bind_address = build_bind_address();
    let state = web::Data::new(build_app_state());

    println!("ProjectHubV2 listening on http://{bind_address}");
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .configure(configure_routes)
    })
    .bind(bind_address)?
    .run()
    .await
}

fn build_bind_address() -> String {
    let host = env::var("PROJECT_HUB_HOST").unwrap_or_else(|_| DEFAULT_HOST.to_string());
    let port = env::var("PROJECT_HUB_PORT")
        .ok()
        .and_then(|value| value.parse::<u16>().ok())
        .unwrap_or(DEFAULT_PORT);

    format!("{host}:{port}")
}
