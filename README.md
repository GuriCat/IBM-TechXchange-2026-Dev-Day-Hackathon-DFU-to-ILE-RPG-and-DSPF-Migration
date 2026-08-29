# DFU to ILE RPG + DSPF Migration

**IBM TechXchange 2026 Pre-conference Dev Day Hackathon**  
Team/Author: GuriCat | Submission deadline: 2026-08-30 10:00 AM ET

---

## What This Project Does

Replaces `GURILIB/TESTDFU` — a legacy DFU (Data File Utility) program — with a
functionally equivalent ILE RPG + DSPF application, compiled to `GURILIB`,
operating on `QIWS/QCUSTCDT` without changing the data file or the original DFU.

The original DFU is **untouched**. Both programs can be called independently.

## Repository Contents

| File | Description |
|---|---|
| `TDSTRPGLE_v7.rpgle` | Final ILE RPG source (column-limited free-form, no `**FREE`) |
| `tdstdspf.dspf` | DSPF source — 5250 display file matching DFU screen layout |
| `tdstprtr.prtf` | PRTF source — audit report matching DFU spool format |
| `submission-report.md` | Full hackathon submission report with architecture diagrams |
| `dfu-to-rpgle-plan.md` | Project plan with implementation results |
| `demo-script.md` | Demo video narration script |

## How to Call the Replacement

```
CALL GURILIB/TDSTRPGLE
```

Identical call syntax to the original DFU. All CRUD operations (Change, Input,
Insert, Delete) and F-key behavior are preserved.

## Architecture

```
User (5250) ──CALL──► GURILIB/TDSTRPGLE (ILE RPG)
                          │
                          ├──EXFMT──► GURILIB/TDSTDSPF  (DSPF)
                          ├──I/O───► QIWS/QCUSTCDT     (non-keyed PF)
                          └──WRITE──► GURILIB/TDSTPRTR  (PRTF audit)

GURILIB/TESTDFU  ←── reference only, never called, untouched
```

## Test Results

All 9 test cases pass against live `QIWS/QCUSTCDT` data:

| # | Test | Result |
|---|---|---|
| T1 | Initial display (RRN=1) | ✅ Pass |
| T2 | F14 Advance to next record | ✅ Pass |
| T3 | `*RECNBR` direct RRN navigation | ✅ Pass |
| T4 | Change mode — update field | ✅ Pass |
| T5 | F5 Refresh | ✅ Pass |
| T6 | F9 Insert — add record | ✅ Pass |
| T7 | F23 Delete — confirm | ✅ Pass |
| T8 | F23 Delete — cancel | ✅ Pass |
| T9 | F3 Exit + audit report | ✅ Pass |

**Compile status:** `CRTBNDRPG` — maximum severity **00**.

## Key Technical Findings

- `QIWS/QCUSTCDT` is **non-keyed** — navigation is by RRN only (matches DFU `*RECNBR` behavior)
- Current RRN is captured from `INFDS` offset 397–400 (`dbfRRN 4I 0`)
- `INDDS(ws)` DS requires `QUALIFIED` keyword — without it, all `wsXX` references fail with `RNF7030`
- Column-limited free-form RPG (`/free` ... `/end-free` style, no `**FREE`) used throughout

## Tools Used

This project was developed entirely within an **IBM Bob 2.0** agent session using:

- **MCP 5250** (`ibm5250`) — live 5250 terminal: DFU inspection, compile, test
- **ILE RPG Code Checker** (`ilerpg_code_checker`) — local pre-upload validation
- **Bob agent reasoning** — root-cause analysis of each compiler error batch, iterative fix

See [`submission-report.md`](submission-report.md) for the full development narrative,
architecture diagrams, and effort comparison (Bob automated vs. manual: 3 min vs. 60 min).

## License

MIT — see [LICENSE](LICENSE).

---

*Hackathon submission — IBM TechXchange 2026 Pre-conference Dev Day*
