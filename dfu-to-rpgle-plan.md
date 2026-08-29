# DFU to ILE RPG + DSPF Migration Plan
## IBM TechXchange 2026 Pre-conference Dev Day Hackathon

---

## Overview

Convert the existing DFU program `GURILIB/TESTDFU` (operating on `QIWS/QCUSTCDT`) into a
functionally equivalent ILE RPG + DSPF application.  The goal is to prove that a typical
DFU-based maintenance screen can be replaced by a maintainable, extensible source-code
application with zero behavioral regression, while opening the door to modernization.

**Scope boundaries**
- Source library: `GURILIB` only — no other user libraries are read or modified
- Data file: `QIWS/QCUSTCDT` (record format `CUSREC`) — read/write, no schema changes
- Original `GURILIB/TESTDFU` must remain untouched throughout
- All deliverable source is in English; chat is in Japanese
- Premium Package for i tools (direct IBM i access, RAG) are used wherever applicable

**Key findings from DFU investigation (STRDFU option 3)**

| Item | Value |
|---|---|
| Program | GURILIB/TESTDFU |
| Data file | QIWS/QCUSTCDT |
| Record format | CUSREC |
| Job title | TESTDFU |
| Screen format | 4 = Row-based (行基準) |
| Audit report | Y (add/change/delete all printed) |
| Print width | 132, column spacing 1 |
| Processing | Sequential (順次) |
| Record number | Not generated |
| Updatable on next screen | Y |

**QCUSTCDT / CUSREC field map**

| Order | Field | Type | Length | DFU Header | Notes |
|---|---|---|---|---|---|
| 1 | CUSNUM | Zoned | 6,0 | Number | Key field (input on *RECNBR line) |
| 2 | LSTNAM | Char | 8 | Last Name | |
| 3 | INIT | Char | 3 | Initial | |
| 4 | STREET | Char | 13 | Street | |
| 5 | CITY | Char | 6 | City | |
| 6 | STATE | Char | 2 | State | |
| 7 | ZIPCOD | Zoned | 5,0 | Zip Code | |
| 8 | CDTLMT | Zoned | 4,0 | Credit Limit | |
| 9 | CHGCOD | Zoned | 1,0 | Assessment Code | |
| 10 | BALDUE | Zoned | 6,2 | Balance | |
| 11 | CDTDUE | Zoned | 6,2 | Accounts Receivable | |

**DFU runtime screen layout (exact — verified via MCP 5250)**

```
Row 1:  " TESTDFU                                        Mode . . :   Change"
Row 2:  " Format  . . . . :   CUSREC                    File  . . :   QCUSTCDT"
Row 4:  "*RECNBR:        0"                          ← CUSNUM input (col 10, len 9, numeric, right-adj blank)
Row 6:  "Number  Last Name Initial"
Row 7:  "------  --------- -------"
Row 8:  [CUSNUM protected 7]  [LSTNAM protected 8]  [INIT protected 3]
Row 10: "Street        City   State Zip Code"
Row 11: "------------- ------ ----- --------"
Row 12: [STREET 13]  [CITY 6]  [STATE 2]  [ZIPCOD 6]
Row 14: "Credit Limit Assessment Code Balance   Accounts Receivable"
Row 15: "------------ --------------- --------- -------------------"
Row 16: [CDTLMT 6]  [CHGCOD 2]  [BALDUE 9]  [CDTDUE 9]
Row 23: "F3=終了   F5=最新表示   F6=様式の選択   F9=挿入   F10=入力   F11=変更"
```

Field attributes on row 8/12/16: `protected=true` when record is displayed; user edits via
key ENTER after positioning with *RECNBR, or via F10 (input) / F11 (change) mode switching.

**DFU function key mapping (行基準 mode)**

| Key | DFU action | RPG equivalent |
|---|---|---|
| F3 | End session (show End-of-Data-Entry screen) | Exit with audit report |
| F5 | Refresh (discard changes, redisplay) | Re-read current record |
| F6 | Select format | Not applicable (single format) |
| F9 | Insert mode | Switch to Add mode |
| F10 | Input mode | Switch to Input (append) mode |
| F11 | Change mode | Switch to Change mode |
| F14 | Advance record (commit + next) | Update + read next |
| F23 | Delete current record | Prompt delete confirmation |
| ENTER | Commit current record | Update/add record |
| PageUp/PageDown | Not standard in 行基準 | — |

**Audit report format (from dfu-audit-report-sample.txt)**
```
5770SS1  V7R5M0  220415          監査ログ          26/08/08   12:58:22  ページ   1
  プログラム/ライブラリー . . . .   GURILIB/TESTDFU
  メンバー . . . . . .   QCUSTCDT
  ジョブ・タイトル . .   TESTDFU
                    0  レコードが追加された
                    0  レコードが変更された
                    0  レコードが削除された
                          * * * * * D F U 監　査　報　告　書　の　終　わ　り * * * * *
```

---

## Sub-Tasks

---

### Sub-Task 1: Create DSPF (TDSTDSPF) — Screen Definition
**Status:** `[x] done`
**Result:** `GURILIB/TDSTDSPF` compiled successfully. `GURILIB/TDSTPRTR` (printer file) also exists and compiled successfully.

**Intent**
Define the 5250 display file that exactly reproduces the DFU row-based screen layout,
including all field positions, attributes, protections, and function key bindings
verified via MCP 5250 live inspection.

**Expected Outcomes**
- Member `GURILIB/QDDSSRC(TDSTDSPF)` compiles without errors
- Screen layout matches DFU screen pixel-for-pixel:
  - Row 1: program name (left) + mode indicator (right)
  - Row 2: format name + file name
  - Row 4: `*RECNBR:` label + CUSNUM input field
  - Row 6-8: Number / Last Name / Initial group with headers and dashes
  - Row 10-12: Street / City / State / Zip Code group
  - Row 14-16: Credit Limit / Assessment Code / Balance / Accounts Receivable group
  - Row 23: function key guide
  - Row 24: message line

**Todo List**
1. Create source file `GURILIB/QDDSSRC` if it does not exist (`CRTSRCPF`)
2. Write DDS source to member `TDSTDSPF` in `GURILIB/QDDSSRC`:
   - File-level: `INDARA`, `CA03`, `CF05`, `CF09`, `CF10`, `CF11`, `CF14`, `CF23`
   - Record format `MAINR`:
     - Row 1: constant "TESTDFU" col 2, mode indicator field col 49 (len 7, output)
     - Row 2: constant labels + format/file name constants
     - Row 4: constant "*RECNBR:" col 1, CUSNUM input field col 10 (len 6, numeric, right-adj)
     - Row 6: header constants "Number", "Last Name", "Initial"
     - Row 7: dash underlines
     - Row 8: CUSNUM(O), LSTNAM(B), INIT(B) — protected by indicator when in display mode
     - Row 10: header constants
     - Row 11: dash underlines
     - Row 12: STREET(B), CITY(B), STATE(B), ZIPCOD(B) — protected by indicator
     - Row 14: header constants
     - Row 15: dash underlines
     - Row 16: CDTLMT(B), CHGCOD(B), BALDUE(B), CDTDUE(B) with edit codes — protected by indicator
     - Row 23: F-key guide constants (COLOR BLU)
     - Row 24: MSG output field (len 78, COLOR RED for errors / GREEN for info)
3. Compile with `CRTDSPF FILE(GURILIB/TDSTDSPF) SRCFILE(GURILIB/QDDSSRC) SRCMBR(TDSTDSPF)`
4. Verify compile succeeds (use Premium Package execute_compile_action or execute_cl_command)

**Relevant Context**
- Reference: `reference/EFADSPF.dspf` — template DSPF with INDARA, indicator usage pattern
- DFU screen layout verified via `get_screen format=json` on session `192.168.1.191-23-mcp5251`
- Field positions from MCP JSON: row/col are attribute-byte positions (data = col+1)
- Use `INDARA` so all indicators are managed via a DS in RPG
- Protection indicator: IN61 = ON → fields become DSPATR(PR) + DSPATR(RI) for delete confirm

---

### Sub-Task 2: Create RPG Program (TDSTRPGLE)
**Status:** `[-] in progress — compile fails with RNF0257`

**Intent**
Implement the ILE RPG program that drives `TDSTDSPF`, replicates all DFU behavioral modes
(Change, Input, Insert/Add), sequential record navigation, and delete confirmation — using
Premium Package `execute_cl_command` / `write_member` for direct IBM i authoring.

**Expected Outcomes**
- Member `GURILIB/QRPGLESRC(TDSTRPGLE)` compiles without errors
- Program `GURILIB/TDSTRPGLE` executes correctly against `QIWS/QCUSTCDT`
- All DFU function keys behave identically to the original
- Record counts (added/changed/deleted) are tracked correctly

**Todo List**
1. Create source file `GURILIB/QRPGLESRC` if it does not exist
2. Write RPG source to member `TDSTRPGLE`:

   **Header / File definitions**
   - `DFTACTGRP(*NO) ACTGRP(*NEW)`
   - `FQCUSTCDT  UF A E K DISK` (QIWS/QCUSTCDT via library list or OVRDBF)
   - `FTDSTDSPF  CF E WORKSTN INDDS(ws)`

   **Data structures**
   - `ws` DS qualified — overlay indicators: IN03(exit), IN05(refresh), IN09(insert),
     IN10(input), IN11(change), IN14(advance), IN23(delete), IN30(change-detect),
     IN50(error-msg), IN51(info-msg), IN60(detail-visible), IN61(field-protect)
   - Counters: `ADDCNT`, `CHGCNT`, `DLTCNT` (all 5S 0)
   - Mode variable: `CURMODE` 1A ('C'=change, 'I'=input, 'A'=insert)

   **Main logic (sequential flow matching DFU 行基準)**
   - Initialize: open file, read first record, set CURMODE='C', display
   - Loop on EXFMT MAINR:
     - F3 → call #ENDSES (show end screen, print audit, exit)
     - F5 → re-read current record (discard edits)
     - F9 → set CURMODE='A' (insert/add mode), clear record, show blank
     - F10 → set CURMODE='I' (input/append mode), clear record, show blank
     - F11 → set CURMODE='C' (change mode), re-read current record
     - F14 → commit current record + read next
     - F23 → call #DELREC (confirm + delete)
     - ENTER with change detected → commit record based on CURMODE
     - ENTER without change → re-read / position by CUSNUM input

   **Subroutines**
   - `#COMMIT` — write (input/insert) or update (change) current record, increment counter
   - `#DELREC` — set IN61=ON (protect+RI), EXFMT, if F23 confirmed → DELETE, DLTCNT+1
   - `#READNXT` — READ QCUSTCDTR; if EOF → wrap or message
   - `#READPRV` — READP; if BOF → wrap or message
   - `#ENDSES` — display "End of Data Entry" confirmation screen, call #PRTRPT, *INLR=*ON
   - `#PRTRPT` — write audit report to QSYSPRT (see Sub-Task 3)
   - `#SETMSG` — set IN50/IN51 and MSG field

3. Compile with `CRTBNDRPG PGM(GURILIB/TDSTRPGLE) SRCFILE(GURILIB/QRPGLESRC) SRCMBR(TDSTRPGLE)`
4. Verify compile succeeds

**Relevant Context**
- Reference: `reference/EFARPGLE.rpgle` — full template with INDDS, subroutine patterns
- DFU key mapping table above
- `CURMODE` drives display title ("Change" / "Input" / "Insert") on row 1
- `QIWS/QCUSTCDT` must be in the job's library list → add `ADDLIBLE QIWS` at start, or use
  `OVRDBF` — GURILIB only rule does NOT prevent reading QIWS data file

---

### Sub-Task 3: Implement Audit Report (#PRTRPT)
**Status:** `[x] done (embedded in TDSTRPGLE source — awaiting compile success)`

**Intent**
Produce an audit report to QSYSPRT at session end that matches the exact DFU audit report
format observed in `reference/dfu-audit-report-sample.txt`.

**Expected Outcomes**
- Spool file written to QSYSPRT with:
  - Header line: OS version, "監査ログ", date, time, page number
  - Program/library, member, job title lines
  - Count lines: "N  レコードが追加された / 変更された / 削除された"
  - Footer: "* * * * * D F U 監　査　報　告　書　の　終　わ　り * * * * *"
- Format matches 132-column width, 1-column spacing as per DFU audit control definition

**Todo List**
1. Define printer file `GURILIB/QDDSSRC(TDSTPRTR)` in DDS or use FQSYSPRT in RPG directly
   - Use `FCUSTPRT  PRINTER OFLIND(IN99)` or `FQSYSPRT  O F 132 PRINTER` (simple approach)
2. Implement `#PRTRPT` subroutine in TDSTRPGLE:
   - Write header line with `%DATE()`, `%TIME()`, job info
   - Write program/library line: `GURILIB/TDSTRPGLE`
   - Write member line: `QCUSTCDT`
   - Write job title line: `TESTDFU`
   - Write 3 count lines with right-justified counts (matching DFU format: col ~19 count, col 22+ text)
   - Write footer line
3. Verify spool output matches reference sample format

**Relevant Context**
- `reference/dfu-audit-report-sample.txt` — exact format with column positions
- DFU audit control: print width=132, column spacing=1, add/change/delete all Y
- Report program name should show `GURILIB/TDSTRPGLE` (the replacement, not TESTDFU)

---

### Sub-Task 4: End-of-Session Confirmation Screen (ENDR format)
**Status:** `[x] done (ENDR record format already added to TDSTDSPF; #ENDSES subroutine in TDSTRPGLE)`

**Intent**
Reproduce the DFU "データ入力の終了" (End of Data Entry) confirmation screen that appears
when F3 is pressed, showing record counts and asking Y/N to confirm exit.

**Expected Outcomes**
- Screen matches DFU end-of-session screen layout:
  - Title: "データ入力の終了" centered
  - Section "処理されたレコード数"
  - Three count lines: 追加 / 変更 / 削除 with current values
  - Input field "データ入力の終了 . . . Y  (Y=YES, N=NO)"
  - F3 and F12 keys

**Todo List**
1. Add record format `ENDR` to existing `TDSTDSPF` source (or separate member):
   - Constant title row
   - Output fields: ADDCNT, CHGCNT, DLTCNT (display only)
   - Input field: ENDYES 1A (Y/N, default Y)
   - CA03, CA12 keys
2. In `#ENDSES` subroutine:
   - EXFMT ENDR
   - If F3 or ENDYES='Y' → proceed to #PRTRPT + exit
   - If F12 → return to main loop (cancel exit)
3. Compile and verify

**Relevant Context**
- DFU End screen observed via MCP 5250: F3=終了, F12=取り消し
- Counts displayed match ADDCNT/CHGCNT/DLTCNT at time of F3 press

---

### Sub-Task 5: Integration Testing via MCP 5250
**Status:** `[ ] pending`

**Intent**
Run the completed program `GURILIB/TDSTRPGLE` via MCP 5250, exercise all major paths,
and verify behavioral equivalence with the original DFU.

**Expected Outcomes**
- All function keys behave as per DFU specification
- Records can be changed, added, deleted against `QIWS/QCUSTCDT`
- Audit report spool file matches reference format
- No unhandled errors or screen layout deviations

**Todo List**
1. Add `QIWS` to library list: `ADDLIBLE LIB(QIWS)`
2. Call `GURILIB/TDSTRPGLE` via MCP 5250 session
3. Test Change mode: navigate with CUSNUM, edit a field, press ENTER → verify update
4. Test Input mode: press F10, enter new record, press ENTER → verify add
5. Test Insert mode: press F9, enter record → verify add
6. Test Delete: navigate to record, press F23, confirm with F23 again → verify delete
7. Test F5 (refresh): edit a field, press F5 → verify original value restored
8. Test F14 (advance): commit + auto-advance to next record
9. Press F3 → verify End screen with counts → confirm → verify spool file
10. Compare spool output with `reference/dfu-audit-report-sample.txt`
11. Run original TESTDFU side-by-side to confirm identical behavior

**Relevant Context**
- Use `mcp__ibm5250__send_text` / `send_key` / `get_screen` tools
- Session: `192.168.1.191-23-mcp5251` (reconnect if dropped)
- Test data in `QIWS/QCUSTCDT` must not be permanently corrupted — note record values before test

---

### Sub-Task 6: Submission Report (English)
**Status:** `[ ] pending`

**Intent**
Produce the final English-language submission document for the hackathon, covering problem
statement, solution design, Bob/Premium Package usage, further deployment ideas, and a
working code repository summary.

**Expected Outcomes**
- File `submission-report.md` (English) containing:
  1. Problem statement: DFU as a maintenance/modernization challenge
  2. Solution overview: ILE RPG + DSPF as the replacement pattern
  3. Technical implementation summary (DSPF layout, RPG logic, audit report)
  4. How IBM Bob 2.0 and Premium Package for i were used (MCP 5250 inspection,
     direct IBM i source authoring, RAG for DFU/RPG documentation)
  5. Further deployment ideas (web UI via Host Access Transformation Services,
     API layer via Db2 Web Query, automated DFU-to-RPG conversion tooling,
     CI/CD with Bob agent in pipeline)
  6. Lessons learned and limitations
  7. Links to source members in GURILIB

**Todo List**
1. Draft `submission-report.md` in English covering all sections above
2. Include code snippets of key DSPF and RPG sections
3. Include screen capture descriptions (or ASCII art) of the reproduced screen vs DFU original
4. Describe Bob session workflow: plan → MCP inspect → write_member → compile → test
5. Review and finalize

**Relevant Context**
- Hackathon rules: `reference/IBM TechXchange 2026 Pre-conference Dev Day Hackathon - OFFICIAL RULES.pdf`
- Evaluation criteria: Completeness (5), Effectiveness (5), Design (5), Creativity (5)
- Deadline: 2026-08-30 10:00 AM ET = 2026-08-30 23:00 JST (提出期限)
- Required artifacts: video demo, problem/solution doc, Bob usage doc, working code + Bob session report

---

## Implementation Notes

### Library List Setup
The job must have `QIWS` in its library list to access `QCUSTCDT`. At program start:
```
ADDLIBLE LIB(QIWS) POSITION(*AFTER *LIBL)
```
Or use `OVRDBF FILE(QCUSTCDT) TOFILE(QIWS/QCUSTCDT)` before calling.

### Premium Package for i Usage
- **`execute_cl_command`**: CRTSRCPF, CRTDSPF, CRTBNDRPG, ADDLIBLE, DSPSPLF
- **`write_member`**: Write DSPF DDS and RPG source directly to IBM i source members
- **`execute_sql_statement`**: Query QIWS/QCUSTCDT for test data verification
- **`search_ibm_i_docs_with_rag`**: Look up DDS keywords, RPG opcodes, spool file APIs
- **MCP 5250**: Live screen inspection during development and final integration testing

### Source Member Names
| Type | File | Member | Description |
|---|---|---|---|
| DSPF DDS | GURILIB/QDDSSRC | TDSTDSPF | Main display file |
| RPG | GURILIB/QRPGLESRC | TDSTRPGLE | Main program |

### Naming Convention
Prefix `TDST` = **T**est**D**FU **ST**ub — distinguishes from original TESTDFU.

---

## Compile Status (as of 2026-08-29)

### TDSTRPGLE — Current Blocker

**Error:** `RNF0257 sev30` — "メイン・プロシージャーの仕様書コードの項目が正しくないか，順序が違っている"
Fires on every H/F/D spec and every BEGSR/ENDSR in the source (approx. 60+ occurrences).

**Root Cause:**
The source begins with `//` comments, followed by fixed-format H/F/D specs (`H DFTACTGRP...`, `FQCUSTCDT...`, `D ...`).
When a source member does **not** start with `**FREE`, the IBM i RPG compiler treats the first
free-form `//` comment as the start of the main procedure body. Anything that follows — including
H, F, and D specs — is parsed as "inside the main procedure", triggering RNF0257 on each spec line.

**Fix Required:**
Rewrite `TDSTRPGLE_v2.rpgle` as fully-free RPG by adding `**FREE` as the very first line and
converting:
- `H` → `CTL-OPT`
- `F` → `DCL-F`
- `D SDS` → `DCL-DS ... SDS`
- `D x S ...` → `DCL-S x ...`
- `D x DS` → `DCL-DS x ...`

The C-spec `ENDSR returnPt` at the bottom of `#DBEX` (needed for INFSR return-point) is
compatible with `**FREE` mode — mixed fixed/free is allowed in `**FREE` only at the C-spec level.

**Local file:** `c:\bob-demo\TDSTRPGLE_v2.rpgle` (327 lines, passes RPG code checker)
**IBM i member:** `GURILIB/QRPGLESRC(TDSTRPGLE)` — currently contains the broken `_v2` source
**Compile command used:**
```
CRTBNDRPG PGM(GURILIB/TDSTRPGLE) SRCFILE(GURILIB/QRPGLESRC) SRCMBR(TDSTRPGLE) OPTION(*EVENTF) DBGVIEW(*ALL)
```
**Library list at compile time:** QSYS, QSYS2, QHLPSYS, QUSRSYS, GURILIB, QIWS, QGPL, QTEMP ✓
**Source CCSID:** 5123 (set by CPYFRMSTMF from UTF-8; no impact on RNF0257)

### Previously resolved errors (no longer present)
| Error | Resolution |
|---|---|
| `RNF2120` — QCUSTCDT/TDSTDSPF not found | ADDLIBLE GURILIB + QIWS before compile |
| `RNF5060` — `ENDSR returnPt;` (free-form) | Replaced with C-spec `C ENDSR returnPt` |
| `RNF3708/3712` — `*OPCODE` position | Already correct in fixed-format D spec |

---

## Open Questions / Decisions Required

None remaining — root cause confirmed, fix path clear.
Next action: create `TDSTRPGLE_v3.rpgle` using `**FREE` + fully-free declarations,
upload via `scp` + `CPYFRMSTMF`, recompile.
