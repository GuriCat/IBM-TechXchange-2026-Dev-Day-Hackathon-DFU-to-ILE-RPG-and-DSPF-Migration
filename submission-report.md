# DFU to ILE RPG + DSPF Migration
## IBM TechXchange 2026 Pre-conference Dev Day Hackathon — Submission Report

**Team / Author:** E00522 (CJCDEV)  
**Submission Date:** 2026-08-29  
**Deadline:** 2026-08-30 10:00 AM ET  

---

## 1. Problem Statement

IBM i shops have accumulated hundreds — sometimes thousands — of DFU (Data File Utility)
programs over the decades.  DFU programs are fast to create but impossible to maintain as
source code: they produce no RPG, no DDS, and no comments.  They cannot be unit-tested,
version-controlled, or extended.  They run in their own activation group and have no API.

The challenge chosen for this hackathon:

> **Replace `GURILIB/TESTDFU`** (a live DFU program operating on `QIWS/QCUSTCDT`) with a
> functionally equivalent ILE RPG + DSPF application — compiled, source-controlled, and
> behaviorally identical — without touching the original DFU or the data file schema.

**Constraints imposed (self-enforced to model real-world scenarios):**

| Constraint | Rationale |
|---|---|
| Original `GURILIB/TESTDFU` must remain untouched | Non-disruptive migration path |
| Only `GURILIB` may store new objects | Single-library deployment |
| `QIWS/QCUSTCDT` schema unchanged | Zero data-layer impact |
| All source written in English | Team convention / hackathon requirement |
| Column-limited free-form RPG (no `**FREE`) | Mirrors common legacy shop constraint |

---

## 2. Solution Overview

The replacement consists of two source members compiled into `GURILIB`:

| Object | Type | Source | Description |
|---|---|---|---|
| `GURILIB/TDSTDSPF` | `*FILE *DSPF` | `GURILIB/QDDSSRC(TDSTDSPF)` | 5250 display file — exact DFU screen layout |
| `GURILIB/TDSTPRTR` | `*FILE *PRTF` | `GURILIB/QDDSSRC(TDSTPRTR)` | Printer file — DFU-compatible audit report |
| `GURILIB/TDSTRPGLE` | `*PGM` | `GURILIB/QRPGLESRC(TDSTRPGLE)` | ILE RPG driver program |

**Naming convention:** prefix `TDST` = **T**est**D**FU **ST**ub.

The program is called identically to the original:

```
CALL GURILIB/TDSTRPGLE
```

---

## 3. Technical Implementation

### 3.1 QCUSTCDT File Analysis

A critical discovery made during implementation:

> `QIWS/QCUSTCDT` is a **non-keyed physical file**.  Access is by **Relative Record Number
> (RRN)** only — not by key field.  This matches the DFU `*RECNBR` navigation model exactly.

This meant the RPG F-spec must omit `K` (keyed), and all navigation uses:

- `READ(E) CUSREC` — sequential forward
- `CHAIN(E) rrn CUSREC` — direct RRN access
- `CHAIN(E) 1 CUSREC` — wrap to first record on EOF
- Current RRN tracked in `wkRRN` via `INFDS` offset 397–400 (`dbfRRN`)

### 3.2 Display File (TDSTDSPF)

Key DDS design decisions:

| Feature | Implementation |
|---|---|
| Indicator management | `INDARA` at file level; `INDDS(ws)` in RPG F-spec |
| Mode title (row 1) | Output field `CURMODE 7A` — "Change ", "Input  ", "Insert " |
| Record number input (row 4) | `RECNBR 6Y 0B` with `CHECK(RB)` — right-blank adjust |
| Detail-section visibility | `IN60` — controls all data fields on/off |
| Delete confirmation | `IN61` — adds `DSPATR(PR)` + `DSPATR(RI)` to all data fields |
| Change detection | `CHANGE(30)` — sets `IN30` when any input field is modified |
| Error message (row 24) | `MSGDTA 78A` with `COLOR(RED)` gated by `IN50` |
| Info message (row 24) | `MSGDTB 78A` with `COLOR(GRN)` gated by `IN51` |
| Two record formats | `MAINR` (data entry) + `ENDR` (end-of-session confirmation) |

Function key bindings on `MAINR`:

| Key | DDS | Indicator | Action |
|---|---|---|---|
| F3 | `CA03(03)` | IN03 | Exit → end-of-session screen |
| F5 | `CF05(05)` | IN05 | Refresh — re-read current record |
| F9 | `CF09(09)` | IN09 | Switch to Insert mode |
| F10 | `CF10(10)` | IN10 | Switch to Input mode |
| F11 | `CF11(11)` | IN11 | Switch to Change mode |
| F14 | `CF14(14)` | IN14 | Advance — commit + read next |
| F23 | `CA23(23)` | IN23 | Delete confirmation |

### 3.3 RPG Program (TDSTRPGLE)

**Specification style:** Column-limited free-form (桁制限付き自由形式).  
H/F/D specs use 5-space indent; subroutine headers (`BEGSR`/`ENDSR`) use 7-space indent.
No `**FREE` directive — compatible with the majority of legacy ILE RPG shops.

**File declarations:**

```rpg
     FQCUSTCDT  UF A E             DISK    USROPN INFDS(dbfds)
     F                                     INFSR(#DBEX)
     FTDSTDSPF  CF   E             WORKSTN INDDS(ws)
     FTDSTPRTR  O    E             PRINTER USROPN
```

Note: `K` is intentionally absent — non-keyed file access.

**Indicator DS (`ws`) — QUALIFIED:**

```rpg
     Dws               DS                  QUALIFIED
     D  exit_03                        N   OVERLAY(ws : 3)
     D  refresh_05                     N   OVERLAY(ws : 5)
     D  insert_09                      N   OVERLAY(ws : 9)
     D  input_10                       N   OVERLAY(ws : 10)
     D  change_11                      N   OVERLAY(ws : 11)
     D  advance_14                     N   OVERLAY(ws : 14)
     D  del_23                         N   OVERLAY(ws : 23)
     D  fldChange_30                   N   OVERLAY(ws : 30)
     D  errorMsg_50                    N   OVERLAY(ws : 50)
     D  infoMsg_51                     N   OVERLAY(ws : 51)
     D  dspDetail_60                   N   OVERLAY(ws : 60)
     D  fieldRI_PR_61                  N   OVERLAY(ws : 61)
```

**RRN tracking via INFDS:**

```rpg
     Ddbfds            DS
     D  dbfStatus             11     15
     D  dbfOpr           *OPCODE
     D  dbfRRN               397    400I 0
```

After every successful I/O that positions the file, `wkRRN = dbfRRN` captures the current RRN.

**Main loop logic (abbreviated):**

```rpg
        DOW (1 = 1);
          EXSR #SETMOD;
          EXFMT MAINR;
          SELECT;
            WHEN ws.exit_03;    EXSR #ENDSES; LEAVE;
            WHEN ws.refresh_05; CHAIN(E) wkRRN CUSREC; ...
            WHEN ws.insert_09;  wkMode = 'A'; EXSR #CLRSCR; ...
            WHEN ws.input_10;   wkMode = 'I'; EXSR #CLRSCR; ...
            WHEN ws.change_11;  wkMode = 'C'; CHAIN(E) wkRRN CUSREC; ...
            WHEN ws.advance_14; EXSR #COMMIT; EXSR #RDNXT;
            WHEN ws.del_23;     EXSR #DELREC;
            OTHER;
              IF ws.fldChange_30; EXSR #COMMIT;
              ELSE;               EXSR #CHAIN;
              ENDIF;
          ENDSL;
        ENDDO;
```

**Subroutine summary:**

| Subroutine | Purpose |
|---|---|
| `#SETMOD` | Maps `wkMode` ('C'/'I'/'A') to 7-char `CURMODE` display field |
| `#CLRSCR` | Clears record buffer, hides detail section |
| `#CHAIN` | Positions to RRN entered in `*RECNBR` field |
| `#COMMIT` | UPDATE (Change) or WRITE (Input/Insert) with error handling |
| `#RDNXT` | READ next; wraps to RRN=1 on EOF with info message |
| `#DELREC` | Two-step F23 delete with field protection confirm |
| `#ENDSES` | Displays ENDR screen, calls `#PRTRPT` if confirmed |
| `#PRTRPT` | Writes DFU-format audit report to TDSTPRTR |
| `#DBEX` | INFSR handler — displays DB error, sets `returnPt='*CANCL'` |

### 3.4 Audit Report (TDSTPRTR)

The audit report spool output matches the DFU reference format:

```
 5770WDS  V7R5M0  220415    Audit Log         26/08/29   17:52:24  Page    1
   Program/Library . . . .   GURILIB/TDSTRPGLE
   Member  . . . . . . . .   QCUSTCDT
   Job Title . . . . . . .   TESTDFU
                    1  records added
                    0  records changed
                    1  records deleted
              * * * * * D F U  A u d i t  R e p o r t  E n d * * * * *
```

---

## 4. IBM Bob 2.0 and Premium Package for i — Usage

This project was developed entirely within an IBM Bob 2.0 agent session.  The following
capabilities were used at each stage:

### 4.1 MCP 5250 — Live Screen Inspection

The `ibm5250` MCP server provided a live 5250 terminal session to `CJCDEV (192.168.1.191)`.

**During analysis:**
- `get_screen(format='json')` was used to extract exact field positions (row/col as
  attribute-byte coordinates), field types, indicator bindings, and protection attributes
  from the running DFU program `TESTDFU`.
- `DSPFFD FILE(QIWS/QCUSTCDT)` confirmed the record format name (`CUSREC`) and revealed
  that the file is **non-keyed** — a critical design constraint.

**During development:**
- `send_text` / `send_key` / `EXFMT` drove the interactive compile-test cycle without
  leaving the Bob session.
- `CRTDSPF`, `CRTBNDRPG`, `CPYFRMSTMF`, `CPYSPLF` were all issued via MCP 5250 commands.
- Compile errors were retrieved via `CPYSPLF FILE(TDSTRPGLE) TOFILE(*TOSTMF)` + QSH `iconv`
  pipeline, then analyzed and fixed within the same turn.

**During testing:**
- All 9 functional test cases (Change, Refresh, RRN navigation, Update, Insert, Delete,
  Delete-cancel, F14 Advance, End-of-session with report) were exercised via MCP 5250 and
  results verified from `get_screen` output.

### 4.2 RPG Code Checker MCP (`ilerpg_code_checker`)

Every version of `TDSTRPGLE_vN.rpgle` was validated locally with
`check_rpg_file(checkLevel='standard')` before upload.  This caught:

- Missing `QUALIFIED` keyword on the `ws` DS (root cause of all `RNF7030` errors)
- `*OPCODE` column-position issues in D-spec
- Column-limit violations in BEGSR/ENDSR lines

### 4.3 Bob Agent — Iterative Diagnosis

The Bob agent performed root-cause analysis on each compiler error batch:

| Error batch | Root cause identified | Fix applied |
|---|---|---|
| `RNF7030` (all indicators undefined) | `ws DS` missing `QUALIFIED` | Added `QUALIFIED` |
| `RNF7030` (`QCUSTCDTR` undefined) | Wrong record format name | `QCUSTCDTR` → `CUSREC` |
| `RNF7075` (keyed op on non-keyed file) | `QCUSTCDT` has no key | Removed `K`, rewrote to RRN |
| `RNF7416` (`%RRN` type mismatch) | `%RRN` returns wrong type for non-keyed file | Used `INFDS` offset 397–400 (`dbfRRN`) |

### 4.4 SSH + SCP — File Transfer

Local source files were transferred to the IBM i IFS via `scp`, then copied to source
members with `CPYFRMSTMF ... STMFCCSID(1208)` (UTF-8 → CCSID 37 auto-conversion).

---

## 5. Test Results

All tests passed on `CJCDEV` against live `QIWS/QCUSTCDT` data.

| Test | Operation | Result |
|---|---|---|
| T1 | Initial display (RRN=1, HENNING) | ✅ Pass |
| T2 | F14 Advance to next record (JONES) | ✅ Pass |
| T3 | `*RECNBR` = 5 → direct RRN access (TYRON) | ✅ Pass |
| T4 | Change mode: edit LSTNAM, ENTER → update | ✅ Pass |
| T5 | F5 Refresh: re-reads current record | ✅ Pass |
| T6 | F9 Insert: blank screen, enter data → add | ✅ Pass |
| T7 | F23 Delete: confirm with F23 → delete | ✅ Pass |
| T8 | F23 Delete: cancel with ENTER → no delete | ✅ Pass |
| T9 | F3 → End screen (Added=1, Deleted=1) → Y → audit report | ✅ Pass |

**Final compile status:** `CRTBNDRPG` — maximum severity **00** (no errors, no warnings).

---

## 6. Further Deployment Ideas

### 6.1 Automated DFU-to-RPG Conversion Tooling

The pattern demonstrated here — inspect DFU via 5250, generate DSPF + RPG — can be
automated.  A Bob skill or MCP tool could:

1. Call `STRDFU OPTION(3)` (display mode) via MCP 5250 and scrape field positions
2. Emit a DSPF skeleton and RPG skeleton from a template
3. Leave business-logic gaps for a developer to fill

### 6.2 Web UI via IBM i Access APIs

The RPG program exposes the same data as the DFU.  Adding an HTTP handler (ILE RPG +
`QZHBCGI` or Open Source Node.js on IBM i) would surface the same CRUD operations as a
REST API with zero schema changes.

### 6.3 CI/CD Integration with Bob Agent

The entire compile-test cycle demonstrated here (edit → scp → CPYFRMSTMF → CRTBNDRPG →
CALL → get_screen verify) can be encoded as a Bob workflow and triggered from a Git push
hook, giving IBM i shops a modern CI/CD loop with no new infrastructure.

### 6.4 Db2 for i Modernization

Now that the data access is in source-controlled RPG, adding SQL access is trivial:

```rpg
     FQCUSTCDT  UF A E             DISK    USROPN INFDS(dbfds)
```

can be augmented with embedded SQL (`EXEC SQL UPDATE QIWS/QCUSTCDT SET ...`) to take
advantage of Db2 for i features such as row-level security, triggers, and journaling.

---

## 7. Lessons Learned and Limitations

### Lessons Learned

1. **Non-keyed PF is the norm for old DFU files.**  Never assume a DFU target file has a
   key.  `DSPFFD` before writing any F-spec is mandatory.

2. **`QUALIFIED` on indicator DS is non-optional.**  Without it, `ws.exit_03` is parsed as
   a qualified reference to an undefined structure, producing dozens of `RNF7030` errors.

3. **`%RRN` does not work on non-keyed files in column-limited free-form.**  Use `INFDS`
   offset 397–400 (`4I 0`) instead.

4. **MCP 5250 `get_screen(format='json')` is the definitive source of truth** for field
   positions, types, and indicator bindings — faster and more accurate than reading DDS
   source or documentation.

5. **`CPYSPLF` without `STMFCCSID` writes EBCDIC.**  Use QSH `iconv` on the IBM i side
   (not on the PC side) to convert to UTF-8 for readable error analysis.

### Limitations

- **`*RECNBR` is RRN, not CUSNUM.**  The replacement preserves this DFU behavior: row-4
  input navigates by physical record position, not by customer number.  A future version
  could add an SQL `WHERE CUSNUM = :n` lookup for key-based navigation.
- **No journaling / commitment control.**  The original DFU ran without journaling; the
  replacement matches this.  Adding `STRCMTCTL` is a one-line change.
- **Audit report is English-only.**  The original DFU report is in Japanese.  A production
  migration would localize the printer file.

---

## 8. Source Inventory

| Location | Object | Description |
|---|---|---|
| `GURILIB/QDDSSRC(TDSTDSPF)` | DDS | Display file source |
| `GURILIB/QDDSSRC(TDSTPRTR)` | DDS | Printer file source |
| `GURILIB/QRPGLESRC(TDSTRPGLE)` | RPG | Main program source |
| `GURILIB/TDSTDSPF` | `*FILE *DSPF` | Compiled display file |
| `GURILIB/TDSTPRTR` | `*FILE *PRTF` | Compiled printer file |
| `GURILIB/TDSTRPGLE` | `*PGM` | Compiled ILE RPG program |
| `GURILIB/TESTDFU` | `*PGM` | Original DFU (untouched) |
| `c:\bob-demo\TDSTRPGLE_v7.rpgle` | Local | Final RPG source (Bob workspace) |
| `c:\bob-demo\tdstdspf.dspf` | Local | Final DSPF source (Bob workspace) |

---

*Report generated by IBM Bob 2.0 agent session — 2026-08-29*
