# architecture.md

## Structure

- `src/main.rs`: Actix Web サーバーを起動し、共有状態を注入する。
- `src/app_state.rs`: DB 接続プール、デフォルトスキーマ、許可スキーマ一覧、API 仕様情報を初期化する。
- `src/services/table_read_service.rs`: GET 参照、POST JSON 検索、POST upsert を提供する。
- `src/services/api_spec_service.rs`: `/api/spec` 用のスキーマ対応 API 仕様を生成する。
- `src/utils.rs`: カラム検証、スキーマ検証、動的 SQL 組み立てを担当する。
- `static/manual.*`: `/manual` の表示を提供する。

## Runtime API

- `GET /system_api_server/si/v1/execute/sql/read`: `schema_name` と `table_name` による参照。
- `POST /system_api_server/si/v1/execute/sql/read`: `schema_name` と JSON 条件による検索。
- `POST /system_api_server/si/v1/execute/sql/update`: `schema_name` と JSON による upsert。

## Design Notes

- `schema_name` は GET のクエリパラメータと POST の JSON の両方で受ける。
- `schema_name` 未指定時は `PROJECT_HUB_DEFAULT_SCHEMA` を使い、未設定なら接続中の既定スキーマを使う。
- アクセス可能なスキーマは `PROJECT_HUB_ALLOWED_SCHEMAS` で制御し、allowlist 外は 400 で拒否する。
- SQL は ``schema.table`` の完全修飾名で実行する。
- API 仕様のカラム定義はデフォルトスキーマの `information_schema` を基準に生成する。
