# spec.md

## Request

- Provide read-only API endpoints for each table model defined in `src/database_models/models.rs`.
- Remove unused dashboard, snapshot, and compatibility code that is not used by the current runtime.
- Publish an HTML API manual at `GET /manual`.
- Publish a JSON API specification for the manual at `GET /api/spec`.

## Scope

- Keep the server focused on read-only MySQL table APIs.
- Build the API specification from `information_schema.columns` of the connected database.
- Serve the support routes `GET /`, `GET /manual`, `GET /api/spec`, and `GET /health`.
- Keep filtering behavior limited to exact-match query parameters.

## Constraints

- This project is read-only. No update, delete, export, or background job endpoints are included.
- Query parameter names must match the current table schema exactly.
- If a model exists in code but its table is missing from the current database, the manual marks the schema as missing and runtime SQL may fail with `500`.
- The current database connection string remains the existing project setting.
