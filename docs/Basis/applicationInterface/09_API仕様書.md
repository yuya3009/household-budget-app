# 家計簿アプリ 要件定義書

## 第9章 API仕様書（一次開発）

[機能一覧書](05_機能一覧書.md)の各機能（FUC-001〜）を実現するAPIについて、第三者が実装・利用できるレベルまで記述するためのテンプレート。
共通のルールは「0. 共通仕様」にまとめ、各エンドポイントでは差分のみを記載する。

---

### 0. 共通仕様

全エンドポイントに共通するルールをここに定義する。各エンドポイントの章では、ここからの差分・追加事項のみを記載する。

#### 0-1. ベースURL

| 環境 | URL |
|---|---|
| ローカル開発 | `http://localhost:3000/api` |
| 本番 | （未定） |

#### 0-2. 認証方式

- 一次開発では、[ユーザ管理API](#6-ユーザ管理api)を含む**全APIで認証なし**とする（単一ユーザー利用前提。[MVP範囲書](02_MVP範囲書.md)が[ユーザ登録・ログイン機能を対象外](02_MVP範囲書.md#3-mvpで対象外とする機能)としていることに準ずる）。
- 二次開発でログインAPI（ID・パスワード等を受け取りJWTを返す）を導入予定。導入時は `Authorization: Bearer <JWT>` 形式に切り替え、このセクションおよび各エンドポイントの「認証」欄・「権限・所有者チェック」欄を更新する。

#### 0-3. 日時・金額のフォーマット規約

| 項目 | ルール |
|---|---|
| 日付 | `YYYY-MM-DD`（ISO 8601、時刻なし）例: `2026-09-21` |
| 日時 | `YYYY-MM-DDTHH:mm:ssZ`（ISO 8601、UTC） |
| 金額 | 整数（円単位、小数なし）。[テーブル定義書](07_テーブル定義書.md)の`NUMERIC(6,0)`に合わせ1〜999999の範囲（0円は登録不可） |
| 文字コード | UTF-8 |

#### 0-4. 共通リクエストヘッダー

| ヘッダー名 | 必須/任意 | 説明 |
|---|---|---|
| `Content-Type` | 必須（Body有りの場合） | `application/json` |
| `Authorization` | 任意（将来必須化予定） | `Bearer <JWT>` |

#### 0-5. 共通エラーレスポンス形式

エラー発生時は、HTTPステータスコードに加えて以下の形式のJSONを返す。

```json
{
  "error": {
    "code": "INVALID_AMOUNT",
    "message": "支出額は1〜999999の範囲で入力してください",
    "field": "expenditure_amount"
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `code` | string | エラー種別を表す一意なコード（下記0-6参照） |
| `message` | string | 人が読めるエラー内容（日本語） |
| `field` | string \| null | バリデーションエラーの場合、対象フィールド名。フィールド単位でない場合は`null` |

複数フィールドが同時にエラーの場合は、`error`を配列に置き換えた`errors`キーで返す（詳細は各エンドポイントで明記）。

#### 0-6. 共通エラーコード一覧

| ステータス | エラーコード | 説明 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | リクエストの型・必須項目に問題がある |
| 400 | `INVALID_AMOUNT` | 金額が許容範囲外 |
| 401 | `UNAUTHORIZED` | 認証情報が無効・未提供（将来の認証導入後） |
| 403 | `FORBIDDEN` | 他ユーザのリソースへのアクセス |
| 404 | `NOT_FOUND` | 指定したリソースが存在しない |
| 409 | `CONFLICT` | 楽観ロック等によるデータ競合 |
| 500 | `INTERNAL_SERVER_ERROR` | サーバ内部エラー |

#### 0-7. ページネーション（一覧系API共通）

| クエリパラメータ | 型 | 必須/任意 | 説明 |
|---|---|---|---|
| `limit` | integer | 任意（デフォルト20、最大100） | 1ページあたりの件数 |
| `offset` | integer | 任意（デフォルト0） | 取得開始位置 |

一覧系レスポンスは以下の形式で総件数を含める。

```json
{
  "data": [ /* ... */ ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

---

### 1. エンドポイント記載テンプレート

新規にAPIを追加する際は、以下の見出し構成をコピーして使用する。

```markdown
### X. <エンドポイント名>（対応機能: FUC-XXX）

#### 概要
- 処理内容を1〜2行で
- 副作用・べき等性の有無（例: 同一リクエストを複数回送った場合の挙動）

#### リクエスト

| 項目 | 内容 |
|---|---|
| メソッド | GET / POST / PUT / DELETE |
| URL | `/api/xxx` |
| 認証 | 必須 / 不要 |

**パスパラメータ**

| 名前 | 型 | 必須/任意 | 説明 |
|---|---|---|---|

**クエリパラメータ**

| 名前 | 型 | 必須/任意 | 説明 |
|---|---|---|---|

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|

リクエスト例:
\`\`\`json
{}
\`\`\`

#### レスポンス（成功時）

| ステータス | 説明 |
|---|---|

レスポンス例:
\`\`\`json
{}
\`\`\`

#### レスポンス（エラー時）

| ステータス | エラーコード | 発生条件 |
|---|---|---|

#### 権限・所有者チェック
- 誰のデータを操作できるか（例: 自分が作成したレコードのみ更新可）
```

---

### 2. 支出・収入関連API（対応機能: FUC-001〜004）

支出（expenditures）と収入（incomes）は[テーブル定義書](07_テーブル定義書.md)上カラム構成が対称のため、まずは支出登録APIをテンプレートの記載例として詳細に示し、残りの編集・削除・一覧・収入系は表形式でまとめて記載する。

#### 2-1. 記載例：支出登録API（FUC-001）

上記テンプレートに沿って実際に記載した例。

##### 概要

- ユーザが入力した支出データを1件新規登録する（[画面一覧書](03_画面一覧書.md)のSCR-002に対応）。
- 副作用あり・非冪等。同一内容のリクエストを複数回送信すると、その都度別レコードとして登録される（重複防止はクライアント側の責務とする）。

##### リクエスト

| 項目 | 内容 |
|---|---|
| メソッド | POST |
| URL | `/api/expenditures` |
| 認証 | 不要（MVP時点。[0-2](#0-2-認証方式)参照） |

**パスパラメータ**

なし

**クエリパラメータ**

なし

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `expenditure_category` | integer | 必須 | カテゴリID（[categories](07_テーブル定義書.md#4-カテゴリーcategories)テーブルの`category_id`。`category_type = "01"`のもののみ有効） |
| `expenditure_date` | string (date) | 必須 | `YYYY-MM-DD`形式。未来日は不可 |
| `expenditure_amount` | integer | 必須 | 1〜999999の整数（円）。0以下は不可 |
| `expenditure_user` | integer | 必須 | ユーザID（[users](07_テーブル定義書.md#1-ユーザusers)テーブルの`user_id`） |
| `expenditure_memo` | string | 任意 | メモ。200文字まで。省略時・空文字の場合は`null`として登録する |

リクエスト例:

```json
{
  "expenditure_category": 3,
  "expenditure_date": "2026-09-20",
  "expenditure_amount": 1200,
  "expenditure_user": 1,
  "expenditure_memo": "スーパーで買い出し"
}
```

##### レスポンス（成功時）

| ステータス | 説明 |
|---|---|
| 201 Created | 登録成功。作成されたレコードを返す |

レスポンス例:

```json
{
  "expenditure_id": 101,
  "expenditure_category": 3,
  "expenditure_date": "2026-09-20",
  "expenditure_amount": 1200,
  "expenditure_user": 1,
  "expenditure_memo": "スーパーで買い出し",
  "created_at": "2026-09-21T09:00:00Z"
}
```

##### レスポンス（エラー時）

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | 必須項目の欠落、型不一致、未来日、`expenditure_memo`が200文字超 |
| 400 | `INVALID_AMOUNT` | `expenditure_amount`が1〜999999の範囲外（0円を含む） |
| 404 | `NOT_FOUND` | `expenditure_category`または`expenditure_user`が存在しない |
| 400 | `CATEGORY_TYPE_MISMATCH` | 指定した`expenditure_category`の`category_type`が"01"（支出用）でない |
| 500 | `INTERNAL_SERVER_ERROR` | サーバ内部エラー |

バリデーションエラー例（複数項目）:

```json
{
  "errors": [
    { "code": "INVALID_AMOUNT", "message": "支出額は1〜999999の範囲で入力してください", "field": "expenditure_amount" },
    { "code": "VALIDATION_ERROR", "message": "支出日は必須です", "field": "expenditure_date" }
  ]
}
```

##### 権限・所有者チェック

- MVP時点では単一ユーザー利用を前提とするため、所有者チェックは未実装。
- 将来複数ユーザー対応時は、リクエストの認証ユーザーと`expenditure_user`が一致しない場合に`403 FORBIDDEN`を返す想定。

#### 2-2. 収入登録API（FUC-001）

支出登録と同じ構造。`expenditure_*`を`income_*`に読み替え、カテゴリの`category_type`は`"02"`（収入用）のみ有効とする。

| 項目 | 内容 |
|---|---|
| メソッド | POST |
| URL | `/api/incomes` |
| 認証 | 不要（MVP時点） |

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `income_category` | integer | 必須 | カテゴリID（`category_type = "02"`のもののみ有効） |
| `income_date` | string (date) | 必須 | `YYYY-MM-DD`形式。未来日は不可 |
| `income_amount` | integer | 必須 | 1〜999999の整数（円）。0以下は不可 |
| `income_user` | integer | 必須 | ユーザID |
| `income_memo` | string | 任意 | メモ。200文字まで。省略時・空文字の場合は`null`として登録する |

成功時: `201 Created`。エラー時のコード体系は支出登録と同一（`VALIDATION_ERROR` / `INVALID_AMOUNT` / `NOT_FOUND` / `CATEGORY_TYPE_MISMATCH`）。

#### 2-3. 支出・収入 編集API（FUC-002）

| 機能 | メソッド | URL |
|---|---|---|
| 支出編集 | PATCH | `/api/expenditures/{expenditure_id}` |
| 収入編集 | PATCH | `/api/incomes/{income_id}` |

- 認証: 不要（MVP時点）
- リクエストボディ: 登録時と同じフィールドのうち、変更したいものだけを送る（部分更新）。`*_memo`に`null`を送るとメモを削除する
- 成功時: `200 OK`。更新後のレコードを返す
- エラー: `404 NOT_FOUND`（指定IDが存在しない）、`400 VALIDATION_ERROR` / `INVALID_AMOUNT` / `CATEGORY_TYPE_MISMATCH`（登録時と同条件）
- **支出⇔収入の切り替えは不可**。支出と収入は別テーブル・別エンドポイントのため、支出編集APIで収入用カテゴリ（`category_type = "02"`）を指定した場合は`CATEGORY_TYPE_MISMATCH`となる（収入編集APIも同様）。区分を誤って登録した場合は、削除API（2-4）で削除してから正しい区分の登録APIで登録し直す

#### 2-4. 支出・収入 削除API（FUC-003）

| 機能 | メソッド | URL |
|---|---|---|
| 支出削除 | DELETE | `/api/expenditures/{expenditure_id}` |
| 収入削除 | DELETE | `/api/incomes/{income_id}` |

- 認証: 不要（MVP時点）
- リクエストボディ: なし
- 成功時: `204 No Content`（ボディなし）
- エラー: `404 NOT_FOUND`（指定IDが存在しない）

#### 2-5. 支出・収入 一覧API（FUC-004）

| 機能 | メソッド | URL |
|---|---|---|
| 支出一覧 | GET | `/api/expenditures` |
| 収入一覧 | GET | `/api/incomes` |

- 認証: 不要（MVP時点）
- クエリパラメータ: [0-7 ページネーション](#0-7-ページネーション一覧系api共通)に加え、`date_from` / `date_to`（string, date, 任意, 期間絞り込み）、`category_id`（integer, 任意, カテゴリ絞り込み）
- 成功時: `200 OK`。[0-7](#0-7-ページネーション一覧系api共通)の一覧レスポンス形式に従う（`data`配列の各要素は登録APIのレスポンス例と同じ構造）
- エラー: `400 VALIDATION_ERROR`（`date_from`が`date_to`より後など、クエリパラメータの不整合）

---

### 3. 固定費関連API（対応機能: FUC-005〜009）

フィールド名・値は[テーブル定義書 5. 固定費（fixed_expenditures）](07_テーブル定義書.md#5-固定費fixed_expenditures)に合わせる。

#### 3-1. 固定費登録API（FUC-005）

| 項目 | 内容 |
|---|---|
| メソッド | POST |
| URL | `/api/fixed-expenditures` |
| 認証 | 不要（MVP時点） |

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `fixed_name` | string | 必須 | 固定費名称（例: 「家賃」「動画サブスク」）。30文字まで。重複可 |
| `expenditure_category` | integer | 必須 | カテゴリID（`category_type = "01"`（支出用）のもののみ有効） |
| `fixed_amount` | integer | 必須 | 1〜999999の整数（円）。0以下は不可 |
| `fixed_frequency` | string | 必須 | `"01"`（毎月） or `"02"`（毎年） |
| `fixed_user` | integer | 必須 | ユーザID（[users](07_テーブル定義書.md#1-ユーザusers)テーブルの`user_id`） |
| `fixed_start_date` | string (date) | 必須 | 自動計上を開始する日付（`YYYY-MM-DD`）。過去・未来とも指定可。計上日はこの日付から決まる（毎月：dd／毎年：MM/dd）。該当月にその日が存在しない場合は月末日に計上する |
| `fixed_memo` | string | 任意 | メモ。200文字まで。省略時・空文字の場合は`null`として登録する |

リクエスト例:

```json
{
  "fixed_name": "家賃",
  "expenditure_category": 1,
  "fixed_amount": 80000,
  "fixed_frequency": "01",
  "fixed_user": 1,
  "fixed_start_date": "2026-10-27",
  "fixed_memo": null
}
```

成功時: `201 Created`。作成されたレコード（`fixed_expenditure_id`、サーバ側で計算した`fixed_next_posting_date`を含む）を返す。

`fixed_next_posting_date`（次回計上日）はリクエストで受け取らず、サーバ側で計算する。`fixed_start_date`が明日以降ならその日付、今日以前なら今日の翌月以降で最初に来る計上日とする（過去分・当日分は計上しない）。

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | 必須項目の欠落、型不一致、`fixed_name`が30文字超、`fixed_frequency`が`"01"`/`"02"`以外、`fixed_start_date`が日付として不正、`fixed_memo`が200文字超 |
| 400 | `INVALID_AMOUNT` | `fixed_amount`が1〜999999の範囲外（0円を含む） |
| 400 | `CATEGORY_TYPE_MISMATCH` | `expenditure_category`の`category_type`が`"01"`（支出用）でない |
| 404 | `NOT_FOUND` | `expenditure_category`または`fixed_user`が存在しない |

※ MVP時点では単一ユーザー利用を前提とするため、所有者チェックは未実装（支出・収入APIと同じ）。将来複数ユーザー対応時は、認証ユーザーと`fixed_user`が一致しない場合に`403 FORBIDDEN`を返す想定。

#### 3-2. 固定費編集API（FUC-006）

| メソッド | URL |
|---|---|
| PATCH | `/api/fixed-expenditures/{fixed_expenditure_id}` |

登録時と同じフィールドの部分更新。認証・エラー体系は登録APIに準ずる（指定IDが存在しない場合は`404 NOT_FOUND`）。`fixed_start_date`または`fixed_frequency`を変更した場合は、`fixed_next_posting_date`をサーバ側で再計算する。成功時`200 OK`。

#### 3-3. 固定費削除API（FUC-007）

| メソッド | URL |
|---|---|
| DELETE | `/api/fixed-expenditures/{fixed_expenditure_id}` |

成功時`204 No Content`。エラー: `404 NOT_FOUND`。

#### 3-4. 固定費一覧API（FUC-008）

| メソッド | URL |
|---|---|
| GET | `/api/fixed-expenditures` |

[0-7 ページネーション](#0-7-ページネーション一覧系api共通)に従う。成功時`200 OK`（`data`配列の各要素は登録APIのレスポンスと同じ構造）。

#### 3-5. 固定費自動計上（FUC-009）

- [画面一覧書](03_画面一覧書.md)の通り画面を持たないバックグラウンド処理（例: 日次バッチ／cronジョブ）として実装し、次回計上日（`fixed_next_posting_date`）が当日の固定費を`expenditures`テーブルへ自動的にレコード追加する想定。`expenditure_user`には固定費の`fixed_user`を設定する。ユーザが直接呼び出すAPIエンドポイントは提供しない。
- 動作確認・再実行用に、管理者向けの手動トリガーAPI（例: `POST /api/fixed-expenditures/apply-monthly`）が必要になった場合は、本セクションに追記する。

---

### 4. カテゴリ区分設定API（対応機能: FUC-010, FUC-014）

[テーブル定義書 6. カテゴリー区分（category_classification）](07_テーブル定義書.md#6-カテゴリー区分category_classification)に合わせ、**category_classificationにレコードがあるカテゴリを「削減対象」、レコードがないカテゴリを「維持対象」**として扱う。categoriesテーブルにはフラグを持たせない。

削減対象・優先度はSCR-008、削減金額はSCR-009で入力するが、DBへの保存はSCR-009の「保存する」でまとめて1回だけ行う（SCR-008で選んだ内容は画面側で保持してSCR-009へ引き継ぐ）。そのため、ユーザ単位で削減対象の一覧（優先度・削減金額を含む）を一括で置き換えるAPIとする。削減対象は1〜3件（SCR-008で0件にはできず、「すべて解除」も一次開発では提供しない）。

#### 4-1. カテゴリ区分取得API

| 項目 | 内容 |
|---|---|
| メソッド | GET |
| URL | `/api/category-classifications` |
| 認証 | 不要（MVP時点） |

**クエリパラメータ**

| 名前 | 型 | 必須/任意 | 説明 |
|---|---|---|---|
| `reduction_target_user` | integer | 必須 | ユーザID |

レスポンス例（`200 OK`）:

```json
{
  "data": [
    { "category_classification_id": 1, "reduction_category": 3, "category_name": "食費", "reduction_number": 1, "reduction_amount": 5000 },
    { "category_classification_id": 2, "reduction_category": 5, "category_name": "娯楽費", "reduction_number": 2, "reduction_amount": 3000 }
  ]
}
```

ここに含まれない支出用カテゴリは「維持対象」である。

#### 4-2. カテゴリ区分一括保存API

| 項目 | 内容 |
|---|---|
| メソッド | PUT |
| URL | `/api/category-classifications` |
| 認証 | 不要（MVP時点） |

- 指定ユーザのcategory_classificationを、リクエストの`items`の内容で**丸ごと置き換える**（`items`にないカテゴリの既存レコードは削除＝維持対象に戻る）。
- 副作用あり・冪等（同じ内容を複数回送っても結果は同じ）。
- 置き換えは1トランザクションで行い、途中でエラーになった場合は何も変更しない。

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `reduction_target_user` | integer | 必須 | ユーザID |
| `items` | array | 必須 | 削減対象とするカテゴリの配列。**1〜3件**（空配列・4件以上は不可） |
| `items[].reduction_category` | integer | 必須 | カテゴリID（`category_type = "01"`（支出用）のもののみ有効）。配列内での重複不可 |
| `items[].reduction_number` | integer | 必須 | 削減優先度（1〜3）。`items`内で重複不可、かつ1から欠番なく連番であること |
| `items[].reduction_amount` | integer | 必須 | 1か月あたりの削減金額。1〜999999の整数（円）。0以下は不可 |

リクエスト例:

```json
{
  "reduction_target_user": 1,
  "items": [
    { "reduction_category": 3, "reduction_number": 1, "reduction_amount": 5000 },
    { "reduction_category": 5, "reduction_number": 2, "reduction_amount": 3000 }
  ]
}
```

成功時: `200 OK`。保存後の内容を4-1と同じ形式で返す。

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | 必須項目の欠落、型不一致、`items`が0件または4件以上、`reduction_number`が1〜3の範囲外・重複・欠番あり、`items`内でカテゴリが重複 |
| 400 | `INVALID_AMOUNT` | `reduction_amount`が1〜999999の範囲外（0円を含む） |
| 400 | `CATEGORY_TYPE_MISMATCH` | 収入用カテゴリ（`category_type = "02"`）が含まれる |
| 404 | `NOT_FOUND` | `reduction_category`または`reduction_target_user`が存在しない |

---

### 5. グラフ・レポートAPI（対応機能: FUC-011〜013）

いずれも読み取り専用（副作用なし）の集計APIで、[SCR-001・SCR-007](03_画面一覧書.md)から利用される。

| 機能 | メソッド | URL | 概要 |
|---|---|---|---|
| 月次収支グラフ（FUC-011） | GET | `/api/reports/monthly-summary` | 月ごとの収入合計・支出合計の推移を返す |
| カテゴリ別支出グラフ（FUC-012） | GET | `/api/reports/category-breakdown` | 指定期間のカテゴリ別支出合計を返す |
| 削減対象カテゴリ内訳（FUC-013） | GET | `/api/reports/reduction-targets` | category_classificationに登録された（削減対象の）カテゴリに絞った支出内訳を、`reduction_number`の昇順で返す（[4章](#4-カテゴリ区分設定api対応機能-fuc-010-fuc-014)の設定に依存） |

**共通クエリパラメータ**

| 名前 | 型 | 必須/任意 | 説明 |
|---|---|---|---|
| `date_from` | string (date) | 任意（デフォルト: 当年1月1日） | 集計期間の開始日 |
| `date_to` | string (date) | 任意（デフォルト: 当日） | 集計期間の終了日 |

**レスポンス例（月次収支グラフ）**

```json
{
  "data": [
    { "month": "2026-07", "income_total": 280000, "expenditure_total": 210000 },
    { "month": "2026-08", "income_total": 280000, "expenditure_total": 195000 }
  ]
}
```

**レスポンス例（カテゴリ別支出グラフ／削減対象内訳）**

```json
{
  "data": [
    { "category_id": 3, "category_name": "食費", "amount": 42000 },
    { "category_id": 5, "category_name": "娯楽費", "amount": 18000 }
  ]
}
```

エラー: `400 VALIDATION_ERROR`（`date_from`が`date_to`より後など、期間指定が不正）。認証は不要（MVP時点）。

---

### 6. ユーザ管理API

⚠️ [MVP範囲書](02_MVP範囲書.md#3-mvpで対象外とする機能)・[機能一覧書](05_機能一覧書.md)は「ユーザ登録・ログイン機能」をMVP対象外としているため、本APIは現行スコープの拡張にあたる。追加する場合は02章・05章の対象外リストの見直しも合わせて検討すること。

#### 6-1. ユーザ登録API

##### 概要

- [users](07_テーブル定義書.md#1-ユーザusers)テーブルに新規ユーザデータを1件作成する。
- 副作用あり・非冪等。

##### リクエスト

| 項目 | 内容 |
|---|---|
| メソッド | POST |
| URL | `/api/users` |
| 認証 | 不要（これから認証情報を作る操作のため） |

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `user_name` | string | 必須 | [users](07_テーブル定義書.md#1-ユーザusers)テーブル`user_name`。50文字まで |
| `age` | integer | 必須 | `age`。0〜999 |
| `gender` | string | 必須 | `gender`。`"男性"` または `"女性"`のみ許可 |
| `email` | string | 必須 | `email`。メール形式必須・重複不可 |

リクエスト例:

```json
{
  "user_name": "山田太郎",
  "age": 30,
  "gender": "男性",
  "email": "taro.yamada@example.com"
}
```

##### レスポンス（成功時）

| ステータス | 説明 |
|---|---|
| 201 Created | 登録成功。メッセージと作成されたレコードを返す |

レスポンス例:

```json
{
  "message": "ユーザ登録しました",
  "user_id": 5,
  "user_name": "山田太郎",
  "age": 30,
  "gender": "男性",
  "email": "taro.yamada@example.com"
}
```

##### レスポンス（エラー時）

`user_id`以外のカラム（`user_name` / `age` / `gender` / `email`）のいずれかが`Null`の場合:

```json
{
  "error": {
    "code": "CHECK_NOT_NULL",
    "message": "必須入力欄に値が入っていません",
    "field": "email"
  }
}
```

`field`には実際にNullだったカラム名が入る（複数ある場合は[0-5](#0-5-共通エラーレスポンス形式)の`errors`配列形式で返す）。

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `CHECK_NOT_NULL` | `user_id`以外のいずれかのカラムが`Null` |
| 400 | `VALIDATION_ERROR` | `gender`が`"男性"`/`"女性"`以外、`age`が範囲外など |
| 400 | `INVALID_EMAIL_FORMAT` | `email`の形式が不正（[6-2](#6-2-ユーザ情報変更api)参照） |
| 409 | `DUPLICATE_EMAIL` | 指定した`email`が既に登録済み |
| 500 | `INTERNAL_SERVER_ERROR` | サーバ内部エラー |

##### 権限・所有者チェック

- 認証不要のため、所有者チェックの概念はなし。

---

#### 6-2. ユーザ情報変更API

##### 概要

- ユーザの`email`（メールアドレス）のみを更新する。他のカラム（`user_name` / `age` / `gender`）は本APIでは変更不可。
- 副作用あり・冪等（同じ値で複数回送っても結果は同じ）。

##### リクエスト

| 項目 | 内容 |
|---|---|
| メソッド | PATCH |
| URL | `/api/users/{user_id}` |
| 認証 | 不要（一次開発時点。[0-2](#0-2-認証方式)参照） |

**パスパラメータ**

| 名前 | 型 | 必須/任意 | 説明 |
|---|---|---|---|
| `user_id` | integer | 必須 | 対象ユーザのID |

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `email` | string | 必須 | 新しいメールアドレス。`Null`・空文字不可、メール形式必須、重複不可 |

リクエスト例:

```json
{ "email": "new.address@example.com" }
```

##### レスポンス（成功時）

| ステータス | 説明 |
|---|---|
| 200 OK | 更新成功。メッセージと更新後のレコードを返す |

レスポンス例:

```json
{
  "message": "メールアドレスを変更しました",
  "user_id": 5,
  "email": "new.address@example.com"
}
```

##### レスポンス（エラー時）

`email`を`Null`（または空文字）で更新しようとした場合:

```json
{
  "error": {
    "code": "EMAIL_REQUIRED",
    "message": "メールアドレスは空欄では登録はできません",
    "field": "email"
  }
}
```

`email`が`@`を含まない、`.com`など`.`以降のドメイン形式に準拠していない等、メール形式として不正な場合:

```json
{
  "error": {
    "code": "INVALID_EMAIL_FORMAT",
    "message": "メールアドレスの形式が正しくありません",
    "field": "email"
  }
}
```

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `EMAIL_REQUIRED` | `email`が`Null`または空文字 |
| 400 | `INVALID_EMAIL_FORMAT` | `@`がない、ドメイン部が`.`以降を含む正しい形式でない等 |
| 404 | `NOT_FOUND` | 指定した`user_id`のユーザが存在しない |
| 409 | `DUPLICATE_EMAIL` | 指定した`email`が他のユーザで既に使用されている |
| 500 | `INTERNAL_SERVER_ERROR` | サーバ内部エラー |

##### 権限・所有者チェック

- 一次開発時点では認証なし・単一ユーザー利用を前提とするため、所有者チェックは未実装。
- 二次開発でログインAPI導入後は、JWTから特定される認証ユーザ本人の`user_id`と、パスパラメータの`user_id`が一致する場合のみ更新可能とする。一致しない場合は`403 FORBIDDEN`を返す想定。

---

### 7. カテゴリ管理API（対応機能: FUC-015〜018）

フィールド名・値は[テーブル定義書 4. カテゴリー（categories）](07_テーブル定義書.md#4-カテゴリーcategories)に合わせる。SCR-006での追加・編集・削除に加え、一覧APIはSCR-002・SCR-003・SCR-004のカテゴリ選択、SCR-008の一覧表示でも使う。

**編集・削除できるカテゴリ**：自分が作成したカテゴリ（`category_creater_user`=自分、かつ`default_category`=false）のみ。デフォルトカテゴリ（`default_category`=true）は参照のみ可能。

#### 7-1. カテゴリ一覧API（FUC-018）

| 項目 | 内容 |
|---|---|
| メソッド | GET |
| URL | `/api/categories` |
| 認証 | 不要（MVP時点） |

**クエリパラメータ**

| 名前 | 型 | 必須/任意 | 説明 |
|---|---|---|---|
| `category_type` | string | 任意 | `"01"`（支出用） or `"02"`（収入用）。省略時は両方 |
| `user_id` | integer | 必須 | ユーザID。デフォルトカテゴリと、このユーザが作成したカテゴリを返す |

- 論理削除済み（`is_delete`=true）のカテゴリは返さない。
- 並び順：デフォルトカテゴリ → ユーザ作成カテゴリの順。それぞれの中は`category_id`の昇順。
- ページネーションは行わない（カテゴリは件数が少ないため全件返す）。

レスポンス例（`200 OK`）:

```json
{
  "data": [
    { "category_id": 1, "category_name": "食費", "category_description": null, "category_icon": "/icons/food.svg", "category_type": "01", "default_category": true, "editable": false },
    { "category_id": 12, "category_name": "推し活", "category_description": "ライブ・グッズ", "category_icon": "/icons/star.svg", "category_type": "01", "default_category": false, "editable": true }
  ]
}
```

`editable`はDBの列ではなく、APIが算出する値（自分が作成した非デフォルトカテゴリならtrue）。画面はこの値で編集可否を出し分ける。

#### 7-2. カテゴリ登録API（FUC-015）

| 項目 | 内容 |
|---|---|
| メソッド | POST |
| URL | `/api/categories` |
| 認証 | 不要（MVP時点） |

**リクエストボディ**

| フィールド | 型 | 必須/任意 | 説明・制約 |
|---|---|---|---|
| `category_name` | string | 必須 | カテゴリ名。30文字まで。既存カテゴリと重複不可 |
| `category_icon` | string | 必須 | アイコン画像のURL。画面で用意したアイコン候補の中から選んだ値 |
| `category_type` | string | 必須 | `"01"`（支出用） or `"02"`（収入用） |
| `category_description` | string | 任意 | 説明。100文字まで。省略時・空文字の場合は`null`として登録する |
| `category_creater_user` | integer | 必須 | 作成するユーザのID |

- `default_category`はリクエストで受け取らず、常に`false`で登録する（ユーザがデフォルトカテゴリを作ることはできない）。
- 成功時: `201 Created`。作成されたレコードを7-1と同じ形式で返す。

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | 必須項目の欠落、型不一致、`category_name`が30文字超、`category_description`が100文字超、`category_type`が`"01"`/`"02"`以外 |
| 404 | `NOT_FOUND` | `category_creater_user`が存在しない |
| 409 | `DUPLICATE_CATEGORY_NAME` | 同じ`category_name`のカテゴリが既に存在する（論理削除済みを除く） |

#### 7-3. カテゴリ編集API（FUC-016）

| メソッド | URL |
|---|---|
| PATCH | `/api/categories/{category_id}` |

- 変更できるのは`category_name` / `category_icon` / `category_description`のみ（部分更新）。
- **`category_type`（支出用⇔収入用）は変更不可**。既存の支出・収入・固定費データとの整合が崩れるため。送られた場合は`400 VALIDATION_ERROR`。
- 成功時: `200 OK`。更新後のレコードを返す。

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | 型不一致、文字数超過、`category_type`を含む |
| 403 | `FORBIDDEN` | デフォルトカテゴリ、または他ユーザが作成したカテゴリを指定した |
| 404 | `NOT_FOUND` | 指定IDが存在しない（論理削除済みを含む） |
| 409 | `DUPLICATE_CATEGORY_NAME` | 変更後の`category_name`が他のカテゴリと重複する |

#### 7-4. カテゴリ削除API（FUC-017）

| メソッド | URL |
|---|---|
| DELETE | `/api/categories/{category_id}` |

- 論理削除（`is_delete`=true）する。
- 同じトランザクションで、このカテゴリを参照する自分の`category_classification`も論理削除する（削減対象から外れる）。
- 削除したカテゴリが削減対象だった場合は、同じトランザクションで残りの削減対象の`reduction_number`を、1から欠番のない連番に自動で詰め直す（例：1・2・3のうち2番目を削除 → 1番目は変更なし、3番目が2番目になる）。`reduction_amount`は変更しない。
- 支出・収入（expenditures / incomes）は履歴として残し、変更しない。一覧等では削除済みカテゴリの名称をそのまま表示する。
- 成功時: `204 No Content`。

| ステータス | エラーコード | 発生条件 |
|---|---|---|
| 403 | `FORBIDDEN` | デフォルトカテゴリ、または他ユーザが作成したカテゴリを指定した |
| 404 | `NOT_FOUND` | 指定IDが存在しない（論理削除済みを含む） |
| 409 | `CATEGORY_IN_USE` | 有効な固定費（fixed_expenditures.is_delete=false）がこのカテゴリを使用している |

---

### 8. 今後の検討事項

- 二次開発でログインAPI（JWT発行）を実装する。導入時は[0-2 認証方式](#0-2-認証方式)を更新し、[6章 ユーザ管理API](#6-ユーザ管理api)（特に6-2 ユーザ情報変更API）を認証必須・所有者チェックありに切り替える。支出・収入等の他のAPIも認証必須にするかは、その時点で方針を確定する。
- 固定費API（[3章](#3-固定費関連api対応機能-fuc-005009)）・カテゴリ区分API（[4章](#4-カテゴリ区分設定api対応機能-fuc-010-fuc-014)）は[07_テーブル定義書](07_テーブル定義書.md)に合わせて定義済み。fixed_expendituresへのユーザカラム追加、自動計上の計上済み判定用カラムの追加時は、3章も合わせて更新する。
- 更新系API（PATCH）導入時は、楽観ロック（`updated_at`の送受信によるコンフリクト検出）の要否を検討し、採用する場合は0章に共通ルールとして追記する。
- ユーザ登録・ユーザ情報変更（一次開発で追加）を踏まえ、[MVP範囲書](02_MVP範囲書.md#3-mvpで対象外とする機能)・[機能一覧書](05_機能一覧書.md)の「対象外」記載も合わせて見直す。
