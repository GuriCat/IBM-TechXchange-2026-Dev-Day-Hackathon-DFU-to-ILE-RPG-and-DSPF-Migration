# Demo Video Narration Script

IBM TechXchange 2026 Pre-conference Dev Day Hackathon  
DFU to ILE RPG Migration — Demo Video Script

---

## Scene 1 — Sign On

**Purpose:** Sign on to the IBM i system and show the starting point of the demo.

**Action:** Enter user ID and password to sign on.

**Point to note:** The sign-on screen shows system name `CJCDEV` and subsystem `QINTER`. This is the IBM i development environment used for this project.

**Confirm:** The Command Entry screen appears — sign-on is complete.

---

## Scene 2 — Add Libraries

**Purpose:** Add the application library and the data file library to the library list, so subsequent commands can resolve them.

**Action 1:** Run `ADDLIBLE GURILIB`. This is the library where the developed programs are stored.

**Confirm:** "Library GURILIB added to library list."

**Action 2:** Run `ADDLIBLE QIWS`. This is the library containing the target data file `QCUSTCDT` (Customer Master).

**Confirm:** "Library QIWS added to library list."

---

## Scene 3 — Inspect Original DFU Definition (STRDFU)

**Purpose:** View the definition of the original DFU program `TESTDFU` to show the basis for the ILE RPG migration. This step is performed **automatically by Bob** via MCP 5250 — no manual screen reading required.

**Action:** Call `STRDFU` with F4 (prompt). Enter:
- DFU option: `3` (Change DFU program / DFU プログラムの変更)
- DFU program: `TESTDFU / GURILIB`
- Database file: `QCUSTCDT / QIWS`

Press ENTER.

**Point to note ①:** The **General Information / Non-Indexed File Definition** screen appears.
- Screen format: `4` (Row-based / 行基準)
- Processing: `2` (Sequential / 順次)

These settings are directly reflected in the RPG program's behavior.

**Point to note ②:** Press `2` on `CUSREC` to reach the **Field Selection and Sequencing** screen. All 11 fields are listed with their types and lengths:

| Order | Field | Type | Length |
|---|---|---|---|
| 10 | CUSNUM | Zoned | 6,0 |
| 20 | LSTNAM | Char | 8 |
| 30 | INIT | Char | 3 |
| 40 | STREET | Char | 13 |
| 50 | CITY | Char | 6 |
| 60 | STATE | Char | 2 |
| 70 | ZIPCOD | Zoned | 5,0 |
| 80 | CDTLMT | Zoned | 4,0 |
| 90 | CHGCOD | Zoned | 1,0 |
| 100 | BALDUE | Zoned | 6,2 |
| 110 | CDTDUE | Zoned | 6,2 |

These fields were used directly to design the DSPF layout and RPG field definitions.

**Point to note ③ (key highlight):** Press **F14** (Definition Display) to reach the **Data File Detail** screen. This shows the **start byte position** of each field within the record:

| Field | Start byte |
|---|---|
| CUSNUM | 1 |
| LSTNAM | 7 |
| INIT | 15 |
| STREET | 18 |
| CITY | 31 |
| STATE | 37 |
| ZIPCOD | 39 |
| CDTLMT | 44 |
| CHGCOD | 48 |
| BALDUE | 49 |
| CDTDUE | 55 |

This is the ground truth for the DSPF screen layout design. Bob captured this data automatically from `get_screen(format='json')` — a human would need ~15 minutes to transcribe the same information by hand.

**Exit:** Set Save=`N`, Run=`N` and press ENTER. `TESTDFU` is left completely untouched.

---

## Scene 4 — Launch the Converted ILE RPG Program

**Purpose:** Start the ILE RPG program `TDSTRPGLE` that replaces the DFU, and confirm the same screen layout is displayed.

**Action:** Run `CALL GURILIB/TDSTRPGLE`.

**Point to note:** The title line shows `TESTDFU` (the original DFU program name), format `CUSREC`, and file `QCUSTCDT`. The field headings (Number / Last Name / Street / Credit Limit…) and the first record HENNING are displayed — faithfully reproducing the DFU screen layout.

The function key guide at the bottom shows `F3=Exit`, `F9=Insert`, `F11=Change`, `F23=Delete` — the DFU-equivalent key bindings.

---

## Scene 5 — INSERT (Add a Record)

**Purpose:** Confirm that a new record can be added. This is the DFU "Insert" mode equivalent.

**Action:** Press **F9** (Insert). Enter the following data and press ENTER:
- Number: `999001`
- Last Name: `TANAKA`
- Initial: `H`
- Street: `1-2-3 TOKYO`
- City: `OSAKA`
- State: `JP`
- Zip Code: `54321`
- Credit Limit: `5000`
- Assessment Code: `1`
- Balance: `3700` (= 37.00)
- Accounts Receivable: `500` (= 5.00)

**Point to note:** The mode indicator at the top right switches to `Insert` and all fields appear blank and ready for input.

**Confirm:** `"Record added."` is displayed at the bottom. The new record TANAKA is shown on screen. This is the same feedback the original DFU provides.

---

## Scene 6 — UPDATE (Change a Record)

**Purpose:** Confirm that an existing record can be modified. This is the DFU "Change" mode equivalent.

**Action:** With the TANAKA record displayed, overwrite the Credit Limit field with `9999` and press ENTER.

**Point to note:** The mode indicator stays at `Change`. Only the modified field needs to be overwritten — all other fields are retained.

**Confirm:** `"Record updated."` is displayed. Credit Limit now shows `9,999`.

---

## Scene 7 — DELETE (Delete a Record)

**Purpose:** Confirm that a record can be deleted. The two-step confirmation matches DFU behavior and prevents accidental deletion.

**Action 1:** Press **F23** (Delete).

**Point to note:** `"Press F23 again to delete. F3/ENTER to cancel."` appears at the bottom. This is the same two-step delete confirmation as the original DFU.

**Action 2:** Press **F23** again to confirm the deletion.

**Confirm:** `"Record deleted."` is displayed and the screen automatically advances to the next record (HENNING). This matches DFU behavior exactly.

---

## Scene 8 — Exit Screen (Record Count Confirmation)

**Purpose:** Confirm the record counts for the session. This demonstrates that the audit functionality equivalent to DFU is implemented.

**Action:** Press **F3** (Exit).

**Point to note:** The "End of Data Entry" screen shows the records processed during this session:

```
Added   . . . . :    1
Changed . . . . :    1
Deleted . . . . :    1
```

Each operation performed — INSERT, UPDATE, and DELETE — has been accurately counted. This is equivalent to the DFU audit report and confirms that `TDSTRPGLE` tracks all record operations correctly.

**Confirm:** Press ENTER to return to the command entry screen. The demo is complete.

---

## Summary

This demo showed that the DFU program `GURILIB/TESTDFU` has been successfully replaced by an ILE RPG + DSPF application `GURILIB/TDSTRPGLE`:

| Capability | Original DFU | TDSTRPGLE | Match |
|---|---|---|---|
| Screen layout | Row-based, CUSREC | Identical layout | ✅ |
| INSERT | F9 | F9 | ✅ |
| UPDATE | ENTER / F11 | ENTER / F11 | ✅ |
| DELETE | F23 + F23 | F23 + F23 | ✅ |
| Record count (audit) | End screen + spool | End screen + spool | ✅ |
| Original DFU state | — | Untouched | ✅ |

The entire analysis, source development, compile, and testing cycle was performed by **IBM Bob 2.0** using the **MCP 5250** and **ilerpg-code-checker** tools — with the developer providing only high-level instructions.

---

## Editor Notes

- **Scene 3, F14 screen (byte positions):** Zoom in and pause — this is the key evidence for "Bob automated the analysis".
- **Scenes 5–7 message line:** Zoom in on `"Record added." / updated. / deleted.` for visibility.
- **Scene 8 counter screen:** Highlight Added/Changed/Deleted values — contrast with DFU audit report.
