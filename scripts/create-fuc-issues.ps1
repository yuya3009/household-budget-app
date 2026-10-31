# 機能一覧書（docs/Basic/function/05_機能一覧書.md）のFUC単位でGitHub Issueを作成する。
# 前提: GitHub CLI（gh）をインストールし、`gh auth login` 済みであること。
# 使い方:
#   .\scripts\create-fuc-issues.ps1 -DryRun   # 作成せず内容だけ表示
#   .\scripts\create-fuc-issues.ps1           # Issueとラベルを作成

param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 機能ID, 機能名, 使用用途, 関連画面, MVP機能(ラベル)
$fucs = @(
    @('FUC-001', '支出・収入登録機能', '支出または収入の新規データを記録する', 'SCR-002', '支出・収入入力'),
    @('FUC-002', '支出・収入編集機能', '登録済みの支出・収入データの内容を修正する', 'SCR-003', '支出・収入入力'),
    @('FUC-003', '支出・収入削除機能', '登録済みの支出・収入データを削除する', 'SCR-003', '支出・収入入力'),
    @('FUC-004', '支出・収入一覧表示機能', '登録済みの支出・収入データを一覧形式で表示する', 'SCR-003', '支出・収入入力'),
    @('FUC-005', '固定費登録機能', '月次または年次で発生する固定費データを新規登録する', 'SCR-004', '固定費入力'),
    @('FUC-006', '固定費編集機能', '登録済みの固定費データの内容を修正する', 'SCR-005', '固定費入力'),
    @('FUC-007', '固定費削除機能', '登録済みの固定費データを削除する', 'SCR-005', '固定費入力'),
    @('FUC-008', '固定費一覧表示機能', '登録済みの固定費データを一覧形式で表示する', 'SCR-005', '固定費入力'),
    @('FUC-009', '固定費自動計上機能', '登録済みの固定費を、該当する月の支出データとして自動的に反映し、都度の入力を不要にする', 'なし（バックグラウンド処理。結果はSCR-001, SCR-003に反映）', '固定費入力'),
    @('FUC-010', 'カテゴリ区分設定機能', '支出カテゴリごとに「削減対象」「維持対象」の区分と、削減対象の優先度を設定・変更する', 'SCR-008', '削減カテゴリ決定'),
    @('FUC-011', '月次収支グラフ表示機能', '月ごとの収入・支出の推移をグラフで表示する', 'SCR-001, SCR-007', 'グラフ表示'),
    @('FUC-012', 'カテゴリ別支出グラフ表示機能', 'カテゴリ別の支出内訳をグラフで表示する', 'SCR-007', 'グラフ表示'),
    @('FUC-013', '削減対象カテゴリ内訳表示機能', '支出削減設定で「削減対象」とした支出に絞った内訳をグラフで表示し、削減効果の大きい箇所を判断できるようにする', 'SCR-007', 'グラフ表示'),
    @('FUC-014', '削減金額設定機能', '削減対象としたカテゴリごとに、1か月あたりに削減してよい金額を設定する。カテゴリ単位のため、そのカテゴリの固定費・変動費の両方が対象になる', 'SCR-009', '削減カテゴリ決定'),
    @('FUC-015', 'カテゴリ登録機能', '支出用・収入用のカテゴリを新規登録する', 'SCR-006', '削減カテゴリ決定'),
    @('FUC-016', 'カテゴリ編集機能', '自分が作成したカテゴリの名称・アイコン・説明を修正する', 'SCR-006', '削減カテゴリ決定'),
    @('FUC-017', 'カテゴリ削除機能', '自分が作成したカテゴリを削除する', 'SCR-006', '削減カテゴリ決定'),
    @('FUC-018', 'カテゴリ一覧表示機能', '登録済みのカテゴリ（デフォルト＋自分が作成したもの）を支出用・収入用に分けて一覧表示する', 'SCR-006', '削減カテゴリ決定')
)

if (-not $DryRun) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'gh（GitHub CLI）が見つかりません。インストールして gh auth login を実行してください。'
    }
    # ラベルを作成（既にあれば更新）
    gh label create 'FUC' --color '0E8A16' --description '機能一覧書の機能単位' --force
    foreach ($name in ($fucs | ForEach-Object { $_[4] } | Select-Object -Unique)) {
        gh label create $name --color '1D76DB' --description 'MVP範囲書の機能' --force
    }
}

$bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) 'fuc-issue-body.md'

foreach ($f in $fucs) {
    $id, $name, $purpose, $screen, $group = $f
    $title = "[$id] $name"
    $body = @"
## 概要

$purpose

## 関連情報

- 機能ID: $id
- 関連画面: $screen
- MVP範囲書の機能: $group
- 参照: ``docs/Basic/function/05_機能一覧書.md``

## 完了条件

- [ ] 実装
- [ ] テスト
- [ ] 画面（またはAPI）から動作確認
"@

    if ($DryRun) {
        Write-Host "=== $title [FUC, $group] ==="
        Write-Host $body
        Write-Host ''
        continue
    }

    [System.IO.File]::WriteAllText($bodyFile, $body, (New-Object System.Text.UTF8Encoding($false)))
    gh issue create --title $title --body-file $bodyFile --label 'FUC' --label $group
}
