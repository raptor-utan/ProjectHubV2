# spec.md

## 要求

- GET のテーブル参照は `GET /system_api_server/si/v1/execute/sql/read?table_name=...` を使う。
- JSON 条件検索は `POST /system_api_server/si/v1/execute/sql/read` を使う。
- upsert は `POST /system_api_server/si/v1/execute/sql/update` を使う。
- クエリパラメータと JSON の両方で `schema_name` を受ける。
- `schema_name` が未指定の場合は設定されたデフォルトスキーマを使う。
- 指定可能なスキーマは許可リストに含まれるものだけに制限する。
- データベース接続情報は `.env` から取得する。
- `.env` が実行ディレクトリ直下にない場合は、一つ上の階層の `.env` を参照する。

## 接続設定

- `PROJECT_HUB_DATABASE_URL` または `DATABASE_URL` があればその値を優先する。
- 上記が未設定の場合は `DB_HOST` `DB_PORT` `DB_USER` `DB_PASSWORD` `DB_NAME` から MySQL 接続設定を構成する。
- `DB_PORT` 未設定時は `3306` を使う。
- 分割設定の `DB_PASSWORD` は生パスワードを優先して扱い、接続失敗時のみ URL エンコード済み値としての再解釈を許容する。
- `PROJECT_HUB_DEFAULT_SCHEMA` は API が既定で使うスキーマ名。
- `PROJECT_HUB_ALLOWED_SCHEMAS` はアクセスを許可するスキーマ名のカンマ区切り一覧。

## 制約

- API の公開パスは現行仕様を維持する。
- DB 接続設定やスキーマ指定の追加に伴って、既存の read / update の HTTP メソッド構成は変えない。
- `PROJECT_HUB_ALLOWED_SCHEMAS` にはデフォルトスキーマを必ず含める。
- 許可リスト外の `schema_name` を指定した場合は `400 Bad Request` とする。
