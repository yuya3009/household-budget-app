# household-budget-app

個人開発用の家計簿アプリの資材を管理するためのリポジトリ

> **現在の状況**: 設計ドキュメント（`docs/`）のみが存在し、アプリのソースコードは未作成です。
> 「ソースコード側のフォルダ構成」「セットアップ手順」「コマンド一覧」は、
> [デプロイ・インフラ方針書](docs/Basis/deploy_infra/11_デプロイ・インフラ方針書.md)と[技術スタック書](docs/Basis/premiseDocument/06_技術スタック書.md)に基づく**予定**です。実装時に実態に合わせて更新してください。

---

## 1. プロジェクト概要

### 目的

支出・収入の入力負担を減らし、「削ってよいもの」の基準を自分で作れるようにするための家計簿アプリです。
記録するだけでなく、ユーザー自身に判断させることを重視します（気づき → 自己ルール化の支援）。
詳細は [目的と背景](docs/Basis/premiseDocument/01_目的と背景.md) を参照してください。

### 主な機能（MVP）

- 収支の入力・一覧・編集・削除
- 固定費の登録と月次の自動計上
- カテゴリ設定（削減対象／維持対象の区分）
- 月次収支グラフ、カテゴリ別支出グラフ、削減対象カテゴリの内訳表示
- 支出削減額の設定

機能の一覧は [機能一覧書](docs/Basis/function/05_機能一覧書.md)、MVPの範囲は [MVP範囲書](docs/Basis/premiseDocument/02_MVP範囲書.md) を参照してください。

### 前提・制約

- 個人開発（開発者1名）。ホスティングは無料〜低コストの範囲に収める
- 操作はスマートフォンのブラウザが中心（レスポンシブ対応）
- 対応ブラウザ: Chrome / Edge / Firefox

---

## 2. 技術スタック

| レイヤー | 採用技術 | 備考 |
|---|---|---|
| フロントエンド | React.js | 状態管理: Zustand、UI: shadcn/ui、グラフ: Recharts（いずれも候補） |
| バックエンド | Node.js | ORM: Prisma（TypeScript導入を推奨） |
| DB | PostgreSQL | 開発: Docker／本番: Neon |
| ソース・文書管理 | GitHub | CI: GitHub Actions |
| ホスティング | Vercel（フロント）／Render（バックエンド） | 無料プランを利用 |

> バージョンはソースコード作成時に確定し、ここへ追記します（例: Node.js xx / PostgreSQL xx）。
> 選定理由とデメリットは [技術スタック書](docs/Basis/premiseDocument/06_技術スタック書.md) を参照してください。

---

## 3. セットアップ手順

> ※ ソースコード作成後に有効になる手順です。コマンド名・フォルダ名は実装に合わせて修正してください。

### 前提環境

- Git
- Node.js（バージョンは確定後に記載）
- Docker / Docker Compose（開発用PostgreSQLの起動に使用）

### 手順

```bash
# 1. リポジトリを取得
git clone <リポジトリURL>
cd household-budget-app

# 2. 環境変数ファイルを作成（値は各自で設定）
cp .env.example .env

# 3. 依存パッケージをインストール
cd backend && npm install
cd ../frontend && npm install
cd ..

# 4. 開発用DBを起動（PostgreSQL）
docker compose up -d db

# 5. DBのマイグレーションを実行
cd backend
npx prisma migrate dev
```

### 環境変数

| 変数名 | 説明 |
|---|---|
| `DATABASE_URL` | PostgreSQLの接続先。開発はローカルのDocker、本番はNeonの接続情報を指定する |

- `.env` は Git 管理外です。コミットしないでください。
- 必要な変数名は `.env.example`（値は空またはダミー）で管理します。
- 本番の接続情報は Render の環境変数にのみ登録し、PC上のファイルには保存しません。

詳細は [デプロイ・インフラ方針書](docs/Basis/deploy_infra/11_デプロイ・インフラ方針書.md) を参照してください。

---

## 4. 起動・ビルド・テスト

> ※ ソースコード作成後に有効になるコマンドです（`package.json` の `scripts` に合わせて修正してください）。

| 目的 | コマンド | 実行場所 |
|---|---|---|
| バックエンド起動（開発） | `npm run dev` | `backend/` |
| フロントエンド起動（開発） | `npm run dev` | `frontend/` |
| 全体をDocker Composeで起動 | `docker compose up` | リポジトリ直下 |
| ビルド | `npm run build` | `backend/`, `frontend/` |
| テスト実行 | `npm test` | `backend/`, `frontend/` |
| Lint | `npm run lint` | `backend/`, `frontend/` |
| フォーマット | `npm run format` | `backend/`, `frontend/` |
| マイグレーション作成・適用（開発） | `npx prisma migrate dev` | `backend/` |
| マイグレーション適用（本番） | `npx prisma migrate deploy` | Renderのデプロイ時に実行 |

テストの方針は [テスト計画書](docs/Basis/testPolicyDocument/12_テスト計画書.md) を参照してください。

---

## 5. フォルダ構成

### 5-1. 現在のフォルダ構成

```
household-budget-app/
├── README.md                  このファイル
├── .gitignore
└── docs/                      設計ドキュメント
    ├── Basis/                 基本設計（要件定義〜全体方針）
    │   ├── premiseDocument/   前提資料（概要・目的・MVP範囲・技術スタック）
    │   ├── screen/            画面一覧・画面遷移図・ワイヤフレーム
    │   ├── function/          機能一覧
    │   ├── table/             テーブル定義書・ER図
    │   ├── applicationInterface/  API仕様書
    │   ├── deploy_infra/      デプロイ・インフラ方針
    │   └── testPolicyDocument/    テスト計画
    └── detail/                詳細設計
        ├── screen-detail/     画面ごとの詳細設計（SCR-001〜009、コンポーネント定義）
        └── sequence/          シーケンス図
```

### 5-2. docs 配下の役割

| フォルダ | 内容 |
|---|---|
| `docs/Basis/premiseDocument/` | システム全体概要書、目的と背景、MVP範囲書、技術スタック書。まず [システム全体概要書](docs/Basis/premiseDocument/00_システム全体概要書.md) から読む |
| `docs/Basis/screen/` | 画面一覧書、画面遷移図、ワイヤフレーム（HTML） |
| `docs/Basis/function/` | 機能一覧書（FUC番号で管理） |
| `docs/Basis/table/` | テーブル定義書、ER図 |
| `docs/Basis/applicationInterface/` | API仕様書 |
| `docs/Basis/deploy_infra/` | デプロイ・インフラ方針書 |
| `docs/Basis/testPolicyDocument/` | テスト計画書 |
| `docs/detail/screen-detail/` | 画面（SCR-001〜009）ごとの詳細設計書、画面コンポーネント定義 |
| `docs/detail/sequence/` | シーケンス図 |

ドキュメントのファイル名は `NN_名称.md` の通し番号形式です。

### 5-3. ソースコードのフォルダ構成（予定）

```
household-budget-app/
├── frontend/                  React アプリ
│   ├── src/
│   │   ├── components/        共通コンポーネント（入力フォーム、一覧テーブル、グラフなど）
│   │   ├── pages/             画面単位のコンポーネント（SCR-001〜009）
│   │   ├── hooks/             カスタムフック
│   │   ├── stores/            状態管理（Zustand）
│   │   ├── api/               バックエンドAPIの呼び出し
│   │   ├── types/             型定義
│   │   └── utils/             汎用関数
│   └── package.json
├── backend/                   Node.js API サーバー
│   ├── src/
│   │   ├── routes/            ルーティング（エンドポイント定義）
│   │   ├── controllers/       リクエスト／レスポンスの処理
│   │   ├── services/          業務ロジック（固定費の自動計上、集計など）
│   │   ├── middlewares/       共通処理（エラーハンドリング、認証など）
│   │   └── utils/             汎用関数
│   ├── prisma/
│   │   ├── schema.prisma      DBスキーマ
│   │   └── migrations/        マイグレーション履歴
│   ├── Dockerfile             本番（Render）で使用
│   └── package.json
├── docker-compose.yml         開発環境（frontend / backend / db）
├── .env.example               環境変数のひな形
└── docs/                      設計ドキュメント（5-1参照）
```

---

## 6. コーディング規約

> 個人開発のため、規約は最小限にし、**ツールで自動化できるものはツールに任せる**方針です。
> Lint / Formatter の設定ファイル（ESLint / Prettier など）を作成した後は、その設定を正とします。

### 6-1. 共通

- 言語は **TypeScript** を使用する（DBスキーマとコードの型不整合を防ぐため。[技術スタック書](docs/Basis/premiseDocument/06_技術スタック書.md) 3章）
- フォーマットは **Prettier**、静的解析は **ESLint** に従う。コミット前に実行する
- インデントはスペース2つ、文字コードはUTF-8、改行はLF
- 文字列はシングルクォート、文末はセミコロンあり（Prettierの設定で統一する）
- `any` の使用は避ける。やむを得ない場合は理由をコメントに書く
- マジックナンバー・固定文字列は定数にする
- 使っていないコード・コメントアウトしたコードは残さない
- コメントは「何をしているか」ではなく「なぜそうしているか」を書く
- パスワードや接続情報などの秘密情報をソースコードに書かない

### 6-2. 命名規則

| 対象 | 規則 | 例 |
|---|---|---|
| 変数・関数 | camelCase | `monthlyTotal`, `calcCategoryTotal()` |
| 真偽値の変数・関数 | `is` / `has` / `can` で始める | `isFixedCost`, `hasError` |
| 定数 | UPPER_SNAKE_CASE | `MAX_MEMO_LENGTH` |
| クラス・型・インターフェース | PascalCase | `Transaction`, `CategoryType` |
| Reactコンポーネント | PascalCase | `TransactionForm` |
| Reactカスタムフック | `use` + PascalCase | `useTransactions` |
| ファイル名（コンポーネント） | PascalCase | `TransactionForm.tsx` |
| ファイル名（それ以外） | camelCase | `transactionService.ts` |
| フォルダ名 | kebab-case または小文字単一語 | `components`, `fixed-cost` |
| DBのテーブル・カラム | snake_case（テーブル名は[テーブル定義書](docs/Basis/table/07_テーブル定義書.md)に従う） | `fixed_costs`, `created_at` |
| APIのパス | 小文字・kebab-case・複数形 | `/api/fixed-costs` |
| 環境変数 | UPPER_SNAKE_CASE | `DATABASE_URL` |

### 6-3. フロントエンド（React）

- 関数コンポーネントとフックで書く（クラスコンポーネントは使わない）
- 1ファイル1コンポーネントを基本とする
- 入力フォーム・一覧テーブル・グラフなど複数画面で使うものは `components/` の共通コンポーネントにする（SCR-002とSCR-004、SCR-003とSCR-005は構造が共通）
- API呼び出しはコンポーネント内に直接書かず、`api/` またはカスタムフックにまとめる
- スマートフォン表示を基準にスタイルを書き、広い画面向けを追加する（モバイルファースト）

### 6-4. バックエンド（Node.js）

- 責務を分ける: `routes`（URL定義）→ `controllers`（入出力）→ `services`（業務ロジック）
- DBアクセスは Prisma 経由とし、生SQLは集計など必要な場合に限る
- 集計（月次合計・カテゴリ別合計など）はDB側（`GROUP BY` 等）で行い、アプリ側で重複した集計ロジックを持たない
- 非同期処理は `async/await` を使う
- エラーは共通のエラーハンドラで処理し、ユーザーに内部情報を返さない
- APIの入出力は [API仕様書](docs/Basis/applicationInterface/09_API仕様書.md) に従う。仕様を変える場合は先に仕様書を更新する

### 6-5. データベース

- スキーマ変更は必ずPrismaのマイグレーションで行い、手作業でDBを変更しない
- マイグレーションファイルは編集せずコミットする
- テーブル定義は [テーブル定義書](docs/Basis/table/07_テーブル定義書.md)・[ER図](docs/Basis/table/08_ER図.md) と一致させる

### 6-6. Git

- ブランチは `main`（デプロイ対象）と作業用ブランチで運用する。作業用ブランチ名は `feature/<内容>`、`fix/<内容>`、`docs/<内容>` とする
- `main` へのpushは自動デプロイされるため、動作確認後に行う
- コミットは1つの目的ごとに分け、メッセージは次の形式で書く

  ```
  <種別>: <変更内容を簡潔に>
  ```

  | 種別 | 用途 |
  |---|---|
  | `feat` | 機能追加 |
  | `fix` | バグ修正 |
  | `docs` | ドキュメントのみの変更 |
  | `refactor` | 挙動を変えないコード整理 |
  | `test` | テストの追加・修正 |
  | `chore` | ビルド・設定・依存関係など |

- `.env` やビルド成果物、`node_modules` はコミットしない（`.gitignore` で管理）

### 6-7. ドキュメント

- 設計を変更したら、関連するドキュメントを同じ変更の中で更新する
- ドキュメントは Markdown で書き、ファイル名は `NN_名称.md` の通し番号形式に合わせる
- 機能・画面は番号（FUC-xxx、SCR-xxx）で参照し、コードのコメントやコミットメッセージにも必要に応じて記載する
