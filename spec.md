# spec.md

## 要求

- 既存の Python Flask 版 ProjectHub を Rust 版へ置き換える。
- Rust 版の作業フォルダは `C:\Users\j12415\RustRoverProjects\ProjectHubV2` とする。
- 既存 Python 版の主要 URL へアクセスしたときに、Rust 版で応答できる入口を用意する。

## 今回の移植範囲

- Actix Web を使用した Rust サーバーを起動する。
- MCP 取得済みの `data/project_snapshot.json` を読み込み、プロジェクト一覧と DB メタ情報を API で返す。
- Python 版の主要 GET ルートを Rust 版ダッシュボードへ接続する。
- DB 更新、帳票、通知、認証、バックグラウンド処理など未移植の操作系ルートは 501 JSON を返す。
- 画面の文字化けを修正し、移植状況を確認できる画面にする。

## 制約・未決事項

- Python 版の SQLAlchemy/Pandas/OpenPyXL/ReportLab/WebPush 相当機能は、Rust 側の DB 接続方式と帳票ライブラリ選定が必要。
- 現在のプロジェクト一覧は MCP スナップショット由来で、実 DB へのライブクエリではない。
- 認証セッション、権限チェック、Excel/PDF 出力、スケジューラは未移植。
