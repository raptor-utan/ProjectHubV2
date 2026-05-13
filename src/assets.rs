pub const INDEX_HTML: &str = include_str!("../static/index.html");
pub const STYLES_CSS: &str = include_str!("../static/styles.css");
pub const APP_JS: &str = include_str!("../static/app.js");
pub const PROJECT_SNAPSHOT_JSON: &str = include_str!("../data/project_snapshot.json");

pub const SERVICE_WORKER_JS: &str = r#"
self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});
"#;
