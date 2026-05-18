# todo.md

- [x] GET `/system_api_server/si/v1/execute/sql/read` を `table_name` クエリで参照できるようにする。
- [x] JSON 条件検索を `POST /system_api_server/si/v1/execute/sql/read` に集約する。
- [x] upsert を `POST /system_api_server/si/v1/execute/sql/update` に集約する。
- [x] `table_name` を JSON ボディから受けてモデルへディスパッチする。
- [x] DB 接続情報を `.env` から取得する。
- [x] 実行ディレクトリ直下に `.env` がない場合は親ディレクトリの `.env` を参照する。
- [x] `schema_name` をクエリパラメータと JSON の両方で受ける。
- [x] デフォルトスキーマ設定を追加し、`schema_name` 未指定時に使う。
- [x] スキーマ allowlist を追加し、許可されたスキーマだけアクセス可能にする。
- [x] `cargo check` と `cargo test` で変更範囲を確認する。
