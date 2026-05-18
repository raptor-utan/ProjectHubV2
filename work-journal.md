# work-journal.md

- 2026-05-12 Created the initial Actix Web server, dashboard assets, and snapshot-driven APIs.
- 2026-05-12 Verified the initial server build with `cargo check`.
- 2026-05-15 Added read-only table endpoints for the models in `src/database_models/models.rs`.
- 2026-05-15 Removed unused dashboard, snapshot, and search DTO code from the active runtime.
- 2026-05-15 Added `/api/spec` and the `/manual` HTML API manual backed by live schema metadata.
- 2026-05-15 Localized `/manual`, `/api/spec`, and `api-spec.md` text to Japanese.
- 2026-05-15 Verified the refactored project with `cargo check` and `node --check static/manual.js`.
- 2026-05-18 Added POST JSON search and per-table upsert behavior to the existing `/system_api_server/si/v1/execute/sql/read/<table_name>` endpoints.
- 2026-05-18 Changed GET table read routing to use only the `table_name` query parameter instead of a path parameter.
- 2026-05-18 Moved JSON-body POST search/upsert to `/system_api_server/si/v1/execute/sql/update` and switched table selection to JSON `table_name`.
- 2026-05-18 Split JSON-body search back to `POST /system_api_server/si/v1/execute/sql/read` while keeping upsert on `POST /system_api_server/si/v1/execute/sql/update`.
