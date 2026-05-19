# architecture.md

## Structure

- `src/main.rs`: Actix Web サーバーを起動し、共通ルートと SQL API を登録する。
- `src/app_state.rs`: DB 接続、デフォルトスキーマ、許可スキーマ、`.env` 由来の許可テーブル一覧、`/api/spec` 用メタデータを初期化する。
- `src/services/api_spec_service.rs`: 許可スキーマ、許可テーブル一覧、`information_schema` のカラム定義を組み合わせて API 仕様を生成する。
- `src/services/table_read_service.rs`: GET 読み取り、POST JSON 検索、POST upsert を `schema_name + table_name` 単位で処理する。
- `src/utils.rs`: スキーマ検証、テーブル検証、カラム検証、動的 SELECT/UPDATE/INSERT SQL の組み立てを担当する。
- `static/manual.*`: `/api/spec` を表示する HTML マニュアルを提供する。

## Runtime API

- `GET /system_api_server/si/v1/execute/sql/read`: `schema_name` と `table_name` を受けて対象テーブルを検索する。
- `POST /system_api_server/si/v1/execute/sql/read`: `schema_name` と JSON 条件で対象テーブルを検索する。
- `POST /system_api_server/si/v1/execute/sql/update`: `schema_name`、`selector`、`values` で対象テーブルへ upsert する。

## Design Notes

- API の対象スキーマは `PROJECT_HUB_ALLOWED_SCHEMAS` で制御し、対象テーブルは `PROJECT_HUB_ALLOWED_TABLES` で制御する。
- `PROJECT_HUB_ALLOWED_TABLES` のエントリは `schema.table` を基本とし、未修飾名はデフォルトスキーマへ解決する。
- `PROJECT_HUB_ALLOWED_TABLES` 未設定時のみ、後方互換のため `sql/*.sql` の `create table` 定義から allowlist を補完する。
- 許可スキーマは `PROJECT_HUB_ALLOWED_SCHEMAS` で管理し、API 仕様にはデフォルトスキーマ、検出状態、テーブル数を含める。
- テーブルごとのカラム検証は `schema_name` と `table_name` の組み合わせで行い、テーブル allowlist に存在しないテーブルは API 対象外とする。
- 読み取り系 SQL は `JSON_OBJECT(...)` を使って行単位の JSON を生成し、そのまま API レスポンスへ返す。
- upsert 系 SQL は完全修飾名 ``schema.table`` を使って実行する。
- `/manual` と `/api/spec` は、許可スキーマ一覧とスキーマ名付きのテーブル一覧を表示する。
