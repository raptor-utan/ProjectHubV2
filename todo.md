# todo.md

- [x] API 仕様生成時の allowlist カラム探索 SQL が不正になる不具合を修正する。
- [x] `GET /system_api_server/si/v1/execute/sql/read` が `table_name` クエリで対象テーブルを受け取れるようにする。
- [x] `POST /system_api_server/si/v1/execute/sql/read` で JSON 条件検索を行えるようにする。
- [x] `POST /system_api_server/si/v1/execute/sql/update` で upsert を行えるようにする。
- [x] `schema_name` をクエリパラメータと JSON の両方で受け取れるようにする。
- [x] デフォルトスキーマ設定と allowlist によるスキーマ制御を追加する。
- [x] `.env` と親ディレクトリ `.env` の両方を探索できるようにする。
- [x] 許可スキーマのテーブル定義を `information_schema` から動的取得するようにする。
- [x] allowlist に追加した任意スキーマを API から動的に read / update できるようにする。
- [x] 許可スキーマ自体の一覧と検出状態を `/api/spec` と `/manual` に表示する。
- [x] テーブル allowlist を `sql/*.sql` の DDL から復元し、許可テーブルだけを API 公開対象にする。
- [x] `.env` の `PROJECT_HUB_ALLOWED_TABLES` でテーブル allowlist を設定できるようにする。
- [x] `/manual` と `/api/spec` をスキーマ付きテーブル表示へ更新する。
- [x] `cargo check` と `cargo test` で動作確認する。
- [x] `GET /system_api_server/si/v1/execute/sql/table-metadata` で allowlist 対象テーブルのテーブルコメントと列コメントを JSON 返却できるようにする。
- [x] `sql/plango.sql` の最新 DDL をもとに `static/manual.html` のスキーマ説明を更新する。
- [x] information_schema �Ŗ������̃e�[�u���ɑ΂��� /read / /update �� 500 �ł͂Ȃ� 400 �ŕԂ��悤�ɏC������B
