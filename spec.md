# spec.md

## 要求

- GET の table read は `GET /system_api_server/si/v1/execute/sql/read?table_name=...` を使う。
- JSON 条件検索は `POST /system_api_server/si/v1/execute/sql/read` を使う。
- upsert は `POST /system_api_server/si/v1/execute/sql/update` を使う。
- `schema_name` はクエリパラメータと JSON の両方で指定できる。
- `schema_name` を省略した場合は、設定されたデフォルトスキーマを使う。
- 指定可能なスキーマは allowlist に含まれるものだけに制限する。
- allowlist に含めた任意のスキーマについて、テーブル群を API から動的に操作できるようにする。
- 許可スキーマの一覧は Rust 側に固定せず、設定された allowlist と `information_schema` を使って動的に解決する。
- 許可テーブルの一覧は Rust 側に固定せず、`.env` の `PROJECT_HUB_ALLOWED_TABLES` で指定できるようにする。

## 設定

- `PROJECT_HUB_DATABASE_URL` または `DATABASE_URL` があればその値を優先する。
- URL 指定がない場合は `DB_HOST` `DB_PORT` `DB_USER` `DB_PASSWORD` `DB_NAME` から MySQL 接続設定を組み立てる。
- `DB_PORT` 未指定時は `3306` を使う。
- 分割設定の `DB_PASSWORD` は生パスワードを推奨するが、接続失敗時は URL エンコード済み値としても再試行する。
- `PROJECT_HUB_DEFAULT_SCHEMA` は API が既定で使うスキーマ名とする。
- `PROJECT_HUB_ALLOWED_SCHEMAS` はアクセスを許可するスキーマ名のカンマ区切りリストとする。
- `PROJECT_HUB_ALLOWED_TABLES` はアクセスを許可するテーブル名のカンマ区切りリストとする。
- テーブル名は `schema.table` 形式を基本とし、スキーマ省略時はデフォルトスキーマのテーブルとして扱う。
- allowlist に追加したスキーマは、再起動後に `/api/spec` と `/manual` に反映されるようにする。
- `PROJECT_HUB_ALLOWED_TABLES` 未設定時は、後方互換のため `sql/` 配下の SQL ファイルから allowlist を補完する。

## 制約

- API の公開パスは変更しない。
- 許可対象外スキーマにはアクセスできない。
- allowlist に含まれていても、`information_schema` で解決できないスキーマは操作対象にしない。
- テーブル allowlist に含まれないテーブルは、対象スキーマ内に存在しても操作対象にしない。
- 対象テーブルは、指定されたスキーマの `information_schema` に存在するものだけを扱う。
- カラム検証は `schema_name + table_name` 単位で行う。
- 読み取り結果は動的な JSON オブジェクト配列として返す。
- upsert の SQL は ``schema.table`` を明示した完全修飾名で実行する。

## 2026-05-20 metadata endpoint
- `GET /system_api_server/si/v1/execute/sql/table-metadata` returns allowlisted table names, table comments, and column comments as JSON.
- Optional query parameter: `schema_name`. When omitted, the endpoint returns all discoverable allowlisted tables across allowed schemas.

## 2026-06-16 nested JSON upsert

### 要求
- `POST /system_api_server/si/v1/execute/sql/update` の `values` で、JSON 列に配列/オブジェクト（ネスト JSON）を保存できるようにする。
- 既存の scalar 値（string / number / bool / null）も従来通り受け付ける。

### 制約
- `selector` は従来通り scalar 値のみを許可する。
- 配列/オブジェクトを指定できるのは `data_type = json` の列のみとし、非 JSON 列では 400 を返す。

### 仮定
- JSON 列への書き込み時は `CAST(? AS JSON)` を使用して SQL を組み立てる。

## 2026-07-17 delete endpoint

### 要求
- `DELETE /system_api_server/si/v1/execute/sql/delete` を追加する。
- 対象行の指定方法は `POST /update` と同じ JSON 形式（`schema_name`, `table_name`, `selector`, `search_mode`, `options`）を使う。

### 制約
- `values` は受け付けない。
- 誤削除防止のため `selector` は必須とする。
- update と同じく `order_by`/`limit` 指定を受け取り、実行時は1件削除（`LIMIT 1`）とする。

### 出力
- 正常時は `{"result":"delete","deleted_count":number}` を返す。

### 仮定
- delete も既存の allowlist / information_schema 検証の対象とする。
