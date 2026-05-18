# spec.md

## Request

- GET は `GET /system_api_server/si/v1/execute/sql/read` を維持する。
- JSON 検索の POST は `POST /system_api_server/si/v1/execute/sql/read` にする。
- upsert の POST は `POST /system_api_server/si/v1/execute/sql/update` にする。
- JSON 系 POST の対象テーブル名はどちらも JSON の `table_name` から受け取る。
- `/manual` と `/api/spec` の記述も新しい POST 仕様に合わせて更新する。

## Scope

- GET は `table_name` クエリパラメータで対象テーブルを選ぶ。
- POST `/read` は JSON 条件検索だけを扱う。
- POST `/update` は upsert だけを扱う。
- POST の `table_name` は必須にする。
- GET/POST のサンプル、HTTP テストファイル、関連ドキュメントを更新する。

## Constraints

- GET の挙動は変更しない。
- POST `/read` では `values` を受け付けない。
- POST `/update` では `values` を必須にする。
- POST は `table_name` から既存の型付きモデルへディスパッチする。
