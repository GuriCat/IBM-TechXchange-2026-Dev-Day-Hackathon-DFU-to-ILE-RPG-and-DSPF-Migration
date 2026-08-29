# CLAUDE.md — IBM i × AI Development Rules (Template)

Place this file as `CLAUDE.md` in the project root.  Replace every `<…>` token with
your actual environment values.  See `doc/ibmi_dev_reference.md` for details, rationale,
examples, and pitfalls.

## Placeholders (fill in first)

| Token | Meaning |
|---|---|
| `<APPLIB>` / `<PFX>*` | Application library (prefix isolates it from other projects) |
| `<APPROOT>` | Application IFS root (e.g. `/myapp`) |
| `<BUILDHOST>` / `<USER>` | Dedicated development IBM i host/IP and connection user (SSH via Windows built-in `ssh`/`scp` with public-key auth; see `doc/setup-guide.md` chapter 2 step 6) |
| `<DEPLOYHOST>` / `<TGTRLS>` | Distribution / lower-release validation host and its target release |
| `<BUILDCL>` | Master build CL program |
| `<PROJDIR>` | Local project directory (clone destination, e.g. `C:\<projname>`) |
| `<REPOHOST>` / `<REPOSHARE>` | Host and share name of the CIFS/SMB share holding the git bare repository |
| `<REPO>` / `<TEMPLATE_REPO>` | Project bare name / template bare name |
| `<HOST>` / `<PASSWORD>` | Target IBM i host (usually same as `<BUILDHOST>`) and the user's password (used only during initial environment setup — **never write the actual password value in this file**; see `doc/setup-guide.md`) |
| `<PRESET>` / `<CHECKER_PATH>` | 5250 connection preset name / absolute path of the ilerpg-code-checker clone (e.g. `C:\MCP\ilerpg-code-checker`; all MCP tool binaries are consolidated under `\MCP` on the project drive — see `doc/setup-guide.md` chapter 2 step 5) |

## Prime Directives

1. **Design before implementing.** Write out byte counts, column positions, and types in a table before writing code (no "compile-driven design").
2. **Compile success ≠ complete; launch ≠ verified.** Demonstrate "input X → output Y, state Z" from observed facts.  Exercise every function key and every code path.  Do not accept "screen appeared + no crash" as passing — compare expected display with actual screen element by element.
3. **Destructive operations and system configuration changes require explicit prior confirmation.** Scope all operations to `<APPLIB>` and `<APPROOT>`.  Never touch system values, `JOBD`, or user profiles without authorization.  Resolve libraries with `ADDLIBLE`.
4. **Do not delegate to the user work that the AI can do itself (via MCP/SSH).** Ask the user only for *visual confirmation, decisions, and operations that cannot be automated*.
5. **Do not silently shrink scope.** Phrases like "in another session", "later", or "technically not feasible" are not acceptable deferrals.  Execute instructions immediately.
6. **Primary sources (specs, official docs, live system output) take precedence over derived tables.** No speculative implementations or accumulation of ad-hoc patches.  Identify the root cause before fixing.  Verify IBM i command names with `DSPCMD` before asserting their existence (do not guess symmetric counterparts via `ADD/CHG/RMV/WRK` patterns).
7. **Commit / push only when the user explicitly instructs.**
8. **Verify before claiming.** Write "injected", "complete", or "verified" only after cross-checking against primary evidence.  If verification refutes a claim, retract it immediately — never double down.

## Standard Workflow

```
1. Manage outstanding work in a single backlog file
2. Determine requirements and design autonomously (no step-by-step confirmation)
3. Edit source (UTF-8 locally)
4. Validate RPG/DSPF with ilerpg-code-checker until zero errors
5. Sync local → IBM i via scp  ★ mandatory before compile; out-of-sync = building stale source
6. Compile (SSH: explicit timeout; no background jobs)
7. Verify on live screen (present viewer, observe input → output)
8. Integration test → update backlog → commit (on explicit instruction only)
```

## Coding Conventions (Key Points)

**RPG / SQLRPGLE**
- Fixed-format H/P/D specs + column-limited free-form calculations.  Do not use fully free-form (`**FREE`).
- SQLRPGLE does not need `/FREE` or `/EXEC SQL` wrappers — write `EXEC SQL …;` directly.
- One statement per line / descriptive variable names / named indicators (`INDARA` + `INDDS`).
- DSPF fields typed via `LIKE`.  Commitment control defaults to `*NONE`.

**DDS (DSPF/PRTF)**
- Design consistently for the target screen size (24×80 DS3 / 27×132 DS4, etc.; do not change mid-project).  Indicator columns 9–10.
- Column headings are a single O-type field with `DSPATR(UL)` (do not split into individual literals).
- `GENLVL` overrides are forbidden.  Correct only unintentional overlaps (intentional conditional layering is permitted).
- Message line = bottom row / function-key guide = one row above (row 24/23 for 24×80; adjust to actual screen depth).  For SFL+WINDOW, place F-key/MSG on SFLCTL (above the SFL).

**DBCS / EBCDIC (Japanese environments)**
- 1 fullwidth char = 2 bytes; DBCS column = SO(1) + 2N + SI(1).  Voiced/semi-voiced/contracted kana count as 2 characters.
- Write out byte calculations in a table.  Leave 1 blank column immediately after a DBCS literal (CPD7866).
- `TEXT()` has a 50-byte limit.  Be careful not to cut inside a DBCS character when extracting substrings.

**CL / SQL**
- Pass arguments via `DCL LEN(N)` (standard CL wrapper pattern).  Use CL and QSH appropriately; no multi-level pipes.
- For `RUNSQL`, write SQL to a file and invoke `db2 -tf`.  Partition schema deletion: `DROP SCHEMA … CASCADE COMMIT(*NONE)`.
- All table columns: `NOT NULL WITH DEFAULT`.  Use commitment control only when required (explicitly disable the default-ON behavior).
- SQL Services: use only GA (base) features available in the lowest target release (TR additions cause `SQL0204` on unpatched systems).  Prefer DTAARA as the primary choice for single-record configuration storage.

## Tools (MCP)

- **ilerpg-code-checker** (RPG/DSPF validation): run `check_rpg_file` (etc.) before compiling; zero errors required.  Use `considerDBCS:true` / `language:'ja'` for Japanese.  **Lines over 80 bytes may escape detection** — supplement with manual review.  For DSPF, the checker's red flags can be false positives; use `CRTDSPF` sev-0 + live screen as the final verdict.
- **5250 terminal MCP** (screen operations): **`connect_5250` opens a browser viewer in app mode** (`http://localhost:5251/?session=<id>`).  Use `send_key` / `send_text` for all operations; Playwright is for screenshot + DOM inspection only (when precise field-attribute capture is needed).  One action → one verification; input field data position = `col + 1`.  **Disconnect sequence: `SIGNOFF` → `disconnect`** (never skip steps).  For demos, retrieve screen text one screen at a time.  Confirm whether `^PWD` works through the MCP path in the target environment.
- **SSH (use Windows built-in `ssh`/`scp`, not an MCP server)**: Public-key auth and the bash environment (PATH/LANG) must be configured in advance (`doc/setup-guide.md` chapter 2 step 6).  Specify explicit timeouts; `run_in_background` / `SBMJOB` are forbidden; chain commands with `&&` in a single `ssh` call.  The `ssh-mcp-server` (MCP) is **for initial environment setup only** — remove it from the MCP registry once setup is complete (setup-guide chapter 2 step 6-8).

## References

- Environment setup + new project creation (chapter 1: distributor tasks / chapter 2: developer tasks — PC prep, clone, MCP, SSH setup / appendix: details): `doc/setup-guide.md`
- Operational rules (condensed): `doc/ai_ibmi_best_practices.md`
- Details, rationale, concrete examples, common-failure quick-reference, mermaid diagrams, tool specs: `doc/ibmi_dev_reference.md`
- Git concepts, repository types, CIFS share operations, initial source import, daily workflow (new project creation: setup-guide chapter 2): `doc/git-cifs-guide.md`
- AI-assisted development cautions (classification and countermeasure hierarchy for known AI failure patterns; the "why" behind the prime directives above): `doc/ai-dev-cautions.md`
