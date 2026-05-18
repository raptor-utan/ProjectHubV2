# todo.md

- [x] GET の共通 `/read` ルートはそのまま維持する。
- [x] JSON 検索を POST `/read` に移す。
- [x] upsert を POST `/update` に残す。
- [x] POST の `table_name` から対象モデルへディスパッチする。
- [x] `/api/spec` と `/manual` の POST 記述を更新する。
- [x] `query_param_test.http` の POST サンプルを更新する。
- [x] `cargo check`、`cargo test`、`node --check static/manual.js` で確認する。
- [ ] DB 接続文字列の環境変数化が必要になったら別タスクで対応する。
