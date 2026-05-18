# architecture.md

## Structure

- `src/main.rs`: Actix Web サーバーを起動し、補助ルートと table read ルートを登録する。
- `src/app_state.rs`: MySQL プールを生成し、API 仕様をキャッシュする。
- `src/routes.rs`: `/`、`/manual`、`/manual/styles.css`、`/manual/app.js`、`/api/spec`、`/health` を配信する。
- `src/services/table_read_service.rs`: GET の共通 `/read`、JSON 検索の POST `/read`、upsert の POST `/update` を登録し、`table_name` からモデルへディスパッチする。
- `src/services/api_spec_service.rs`: `information_schema.columns` から `/api/spec` 用 JSON を組み立てる。
- `src/models.rs`: API DTO とマニュアル用仕様 DTO を定義する。
- `src/utils.rs`: カラム検証と動的 SQL 組み立てを行う。
- `static/manual.*`: `/manual` の画面を構成する。

## Runtime API

- `GET /`: `/manual` へリダイレクトする。
- `GET /manual`: HTML マニュアルを返す。
- `GET /api/spec`: JSON 仕様を返す。
- `GET /health`: `{"status":"ok"}` を返す。
- `GET /system_api_server/si/v1/execute/sql/read`: `table_name` クエリパラメータで対象テーブルを選び、クエリ文字列条件で検索する。
- `POST /system_api_server/si/v1/execute/sql/read`: JSON の `table_name` で対象テーブルを選び、JSON 条件検索を実行する。
- `POST /system_api_server/si/v1/execute/sql/update`: JSON の `table_name` で対象テーブルを選び、upsert を実行する。

## Design Notes

- GET と JSON 検索 POST は同じ `/read` を共有し、入力形式だけを分ける。
- upsert は `/update` に分離して `values` 必須にしている。
- POST はどちらも JSON の `table_name` から既存の型付きハンドラへディスパッチする。
- `/manual` と `/api/spec` では POST `/read` と POST `/update` を分けて案内する。
