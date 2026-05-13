# architecture.md

## 構成

- `src/main.rs`: Actix Web サーバーの起動、ホスト・ポート設定。
- `src/app_state.rs`: アプリケーション状態の生成。MCP スナップショットと移植ルート一覧を保持する。
- `src/assets.rs`: HTML、CSS、JavaScript、JSON スナップショット、Service Worker の埋め込み。
- `src/models.rs`: API レスポンス、プロジェクトスナップショット、移植状況モデル。
- `src/routes.rs`: API、静的画面、Python 互換ルート、未移植ルートの 501 応答を定義する。
- `static/index.html`: Rust 版ダッシュボード画面。
- `static/app.js`: `/api/projects` と `/api/routes` を取得して画面へ反映する。
- `static/styles.css`: 業務画面向けのレイアウトと表示スタイル。
- `data/project_snapshot.json`: MCP で取得した DB メタ情報のスナップショット。

## API

- `GET /`: Rust 版ダッシュボード。
- `GET /api/projects`: プロジェクトスナップショットを返す。
- `GET /api/database`: DB テーブル情報を返す。
- `GET /api/routes`: Python 版主要ルートの移植状況を返す。
- `GET /health`: ヘルスチェック。
- Python 版の主要 GET 画面ルートは `/` と同じダッシュボードを返す。
- 未移植の更新・帳票・通知・バックグラウンド処理ルートは `501 Not Implemented` を返す。

## 設計判断

- DB 接続を推測で実装せず、現時点では MCP スナップショットを読み取り専用データとして扱う。
- 既存 Python 版 URL へのブックマークや画面遷移を壊さないよう、主要ルートを Rust 側へ登録する。
- 未移植機能は成功扱いにせず、JSON で未実装を明示する。
