# architecture.md

## Structure

- `src/main.rs`: starts the Actix Web server and registers support routes plus table read routes.
- `src/app_state.rs`: creates the MySQL pool and builds the cached API specification.
- `src/routes.rs`: serves `/`, `/manual`, `/manual/styles.css`, `/manual/app.js`, `/api/spec`, and `/health`.
- `src/assets.rs`: embeds the HTML, CSS, and JavaScript used by the manual page.
- `src/services/table_read_service.rs`: registers one read-only endpoint per table model and handles query execution.
- `src/services/api_spec_service.rs`: reads `information_schema.columns` and builds the JSON API specification.
- `src/database_models/models.rs`: defines SQLx row models and table-name metadata for the read-only endpoints.
- `src/utils.rs`: validates filter columns and builds SQL with bound values.
- `static/manual.html`: manual page shell.
- `static/manual.css`: manual page presentation.
- `static/manual.js`: manual page rendering logic fed by `/api/spec`.

## Runtime API

- `GET /`: redirects to `/manual`.
- `GET /manual`: returns the HTML API manual.
- `GET /api/spec`: returns the JSON API specification.
- `GET /health`: returns `{"status":"ok"}`.
- `GET /system_api_server/si/v1/execute/sql/read/<table_name>`: returns rows from the matching table model with exact-match query filters.

## Design Notes

- The project no longer keeps unused snapshot or dashboard code in the runtime path.
- The API manual is generated from live database schema metadata instead of hand-maintained field lists.
- Query values are always bound with placeholders.
- Query parameter names are validated against the current table schema before SQL execution.
