# todo.md

- [x] Remove unused dashboard, snapshot, search DTO, and placeholder route code from the current runtime.
- [x] Consolidate runtime routing around support routes and table read APIs only.
- [x] Publish `GET /manual` as the HTML API manual.
- [x] Publish `GET /api/spec` as the JSON API specification used by the manual.
- [x] Localize the manual and API specification text to Japanese.
- [x] Validate query filter columns against the current table schema.
- [x] Confirm the project still builds with `cargo check`.
- [ ] Move the database connection string out of source code if environment-based configuration is required later.
- [ ] Add HTTP-level endpoint tests if API regression coverage becomes necessary.
