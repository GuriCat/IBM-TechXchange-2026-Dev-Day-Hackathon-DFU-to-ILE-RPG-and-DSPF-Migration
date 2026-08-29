# CLAUDE.md — IBM i × Claude 開発ルール（雛形）

新規プロジェクトの root に `CLAUDE.md` として配置する。`<…>` を自分の環境に置換すること。
詳細・理由・例・落とし穴は `doc/ibmi_dev_reference.md` を参照。

## プレースホルダ（最初に埋める）

| 記号 | 意味 |
|---|---|
| `<APPLIB>` / `<PFX>*` | アプリ用ライブラリ（接頭辞で他と分離） |
| `<APPROOT>` | アプリ用 IFS ルート（例 `/myapp`） |
| `<BUILDHOST>` / `<USER>` | ビルド専用の開発機（host/IP）と IBM i 接続ユーザー（SSH は Windows 標準 `ssh`/`scp`・公開鍵認証。構築は `doc/setup-guide.md` 2章⑥） |
| `<DEPLOYHOST>` / `<TGTRLS>` | 配布・下位リリース検証機とその対象リリース |
| `<BUILDCL>` | ビルド統括 CL プログラム |
| `<PROJDIR>` | ローカルのプロジェクトディレクトリ（雛形の clone 先。例 `C:\<projname>`） |
| `<REPOHOST>` / `<REPOSHARE>` | git bare を置く CIFS/SMB 共有のホストと共有名 |
| `<REPO>` / `<TEMPLATE_REPO>` | プロジェクトの bare 名 / 雛形の bare 名 |
| `<HOST>` / `<PASSWORD>` | 接続先 IBM i（通常 `<BUILDHOST>` と同一）と対象ユーザーのパスワード（環境構築の初期段階でのみ使用。**パスワードの実値は本ファイルに書かない**。詳細は `doc/setup-guide.md`） |
| `<PRESET>` / `<CHECKER_PATH>` | 5250 接続プリセット名 / ilerpg-code-checker の clone 先絶対パス（例 `C:\MCP\ilerpg-code-checker`。MCP ツール本体はプロジェクトのあるドライブの `\MCP` 配下に集約 — `doc/setup-guide.md` 2章⑤） |

## 最優先の大原則

1. **設計してから実装する。** バイト数・桁位置・型を表に起こしてから書く（「コンパイルしながら考える」禁止）。
2. **コンパイル成功 ≠ 完成、起動 ≠ 動作検証。** 「入力 X → 出力 Y・状態 Z」を観測事実で示す。全 F キー・全動線を通す。「画面が出た+無クラッシュ」で 合格にせず、期待表示と実画面を要素単位で突合する。
3. **破壊的操作・システム構成変更は必ず事前確認。** 操作は `<APPLIB>`・`<APPROOT>` に限定。システム値・`JOBD`・ユーザープロファイルは無断で触らない。ライブラリ解決は `ADDLIBLE`。
4. **自分で（MCP/SSH で）できる作業をユーザーに丸投げしない。** 依頼するのは *目視確認・意思決定・自動化不能な操作* だけ。
5. **scope を勝手に縮小しない。** 「別セッションで」「後で」「技術的に無理」等の先送りは禁止。指示はその場で実行。
6. **一次資料（仕様書・公式 Docs・実機出力）を派生表より優先。** 推測実装・場当たりパッチの積み重ね禁止。根本原因を特定してから直す。IBM i コマンド名は断言前に `DSPCMD` で存在確認（`ADD/CHG/RMV/WRK` の対称体系を推測補完しない）。
7. **commit / push はユーザー明示指示時のみ。**
8. **日本語優先。** 英語カタカナは日本語化（定着語・固有名詞は除く）。「正直に／完全に／すべて」等の装飾を避け、具体的事実で述べる。
9. **確認は本文テキストで**（番号付きの短い選択肢）。選択肢ポップアップを乱用しない。
10. **「注入検出」「完了・検証済み」は一次証拠と突合してから書く。** 裏付けのない主張は捏造。検証で否定されたら固執せず撤回。

## 標準ワークフロー

```
1. 残作業を単一の backlog ファイルで管理
2. 要件・設計を自律決定（逐次確認しない）
3. ソースを編集（UTF-8）
4. RPG/DSPF を ilerpg-code-checker でエラー0まで検証
5. ローカル → IBM i へ同期（scp。★コンパイル前に必須。未同期は旧ソースをビルド）
6. コンパイル（SSH は タイムアウト 明示・background 禁止）
7. 実画面で単体検証（viewer を提示し入力→出力を観測）
8. 結合テスト → backlog 更新 → commit（指示時のみ）
```

## コーディング規約（要点）

**RPG / SQLRPGLE**
- 固定形式 H/P/D ＋ 桁制限付き自由形式演算。完全自由形式は使わない。
- SQLRPGLE の `/FREE`・`/EXEC SQL` ラッパーは不要（`EXEC SQL …;` 直書き）。
- 1 行 1 命令 / 長い変数名 / 標識は名前付き（`INDARA`+`INDDS`）。
- DSPF フィールドは `LIKE` で型追従。`COMMIT` は既定 `*NONE`。

**DDS（DSPF/PRTF）**
- 画面は対象サイズで一貫設計（24×80 DS3 / 27×132 DS4 等。途中で変えない）。指示器は 桁9-10。
- 列見出しは単一 O 型項目 + `DSPATR(UL)`（個別リテラル分割禁止）。
- `GENLVL` 指定禁止。非意図の重なりだけ是正（意図的な条件づけは許容）。
- MSG 行=最下行 / F キー行=その 1 つ上（24×80 なら 24/23、画面行数に合わせる）。SFL+WINDOW は F キー/MSG を SFLCTL（SFL より上）に配置。

**DBCS / EBCDIC（日本語環境）**
- 1 全角=2バイト、DBCS 列=SO(1)+2N+SI(1)。濁音・拗音・小合成カナは 2 文字扱い。
- バイト計算は表に書き出す。DBCS リテラル直後は 1桁 空ける（CPD7866）。
- `TEXT()` は 50バイト上限。部分文字列切出は DBCS 中切断に注意。

**CL / SQL**
- 引数は DCL の `LEN(N)` で渡す（CL ラッパー標準）。CL と QSH を使い分け、多層 pipe は禁止。
- `RUNSQL` は SQL をファイル化して `db2 -tf`。区画スキーマ削除は `DROP SCHEMA … CASCADE COMMIT(*NONE)`。
- テーブルは `NOT NULL WITH DEFAULT` に統一。コミットメント制御は要件時のみ（既定 ON を明示無効化）。
- SQL Service は対象最下位リリースの GA(base) 収録分のみ（TR 追加分は未適用環境で `SQL0204`）。単一レコード設定は DTAARA を第一選択。

## ツール（MCP）

- **ilerpg-code-checker**（RPG/DSPF 検証）: コンパイル前に `check_rpg_file` 等でエラー0まで。`considerDBCS:true`/`language:'ja'`。**80バイト 超は検出漏れ**があるので自前検証で補い、DSPF は checker が赤でも実機 `CRTDSPF` sev0 + 実画面で最終判定（誤検出 が多い）。
- **5250 端末 MCP**（画面操作）: **`connect_5250` でデフォルト app モードのブラウザ viewer が開く**（`http://localhost:5250/?session=<id>`）。**Playwright は viewer のスクショ + DOM 確認用**（フィールド属性を正確に取得したいとき）、操作は `send_key`/`send_text`。1 アクション 1 検証、入力欄のデータ位置=`col+1`。**切断は `SIGNOFF` → `disconnect` の段階手順**。デモは画面テキスト取得中心で 1 画面ずつ止める。`^PWD` が MCP 経路で効くか導入先で確認。
- **SSH（MCP ではなく Windows 標準 `ssh`/`scp` を使う）**: 公開鍵認証・bash 環境（PATH/LANG）は環境構築（`doc/setup-guide.md` 2章⑥）で構成済みが前提。タイムアウト明示・`run_in_background`/`SBMJOB` 禁止・`&&` で 1 ssh に連鎖。`ssh-mcp-server`（MCP）は**環境構築の初期段階専用**で、構築完了後は登録から外す（setup-guide 2章⑥-8）。

## 参照

- 環境構築＋新プロジェクト作成（1章 配布者の作業／2章 開発者の作業〈PC 準備・clone・MCP・SSH 構築〉／付録 詳細）: `doc/setup-guide.md`
- 運用の鉄則（凝縮版）: `doc/claude_ibmi_best_practices.md`
- 詳細・理由・具体例・よくある失敗の早見表・mermaid 図・ツール仕様: `doc/ibmi_dev_reference.md`
- git 概念・リポジトリ種別・CIFS 共有運用・既存ソース初回インポート・日常運用（新プロジェクト作成手順は setup-guide 2章）: `doc/git-cifs-guide.md`
- 生成AI開発の注意事項（Claude の不具合 90件超の分類・対策階層。上記大原則の「なぜ」）: `doc/ai-dev-cautions.md`
