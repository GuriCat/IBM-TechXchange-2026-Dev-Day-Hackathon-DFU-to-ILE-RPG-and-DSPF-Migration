# IBM Bob session screenshots

Stills from the screen recording of the IBM Bob agent session of 2026-08-29.  Each frame
shows the Bob task pane on the right driving the work, and the 5250 terminal it controlled
on the left.  The mode selector at the bottom of the Bob pane reads **Agent** in every frame.

| File | What it shows |
|---|---|
| `01-agent-session-start.png` | Bob signing on to the IBM i through the ibm5250 MCP server. Task pane shows the `Send Text (ibm5250)` / `Send Key (ibm5250)` tool calls. |
| `02-dfu-definition-capture.png` | `STRDFU OPTION(3)` on `GURILIB/TESTDFU`. The DFU definition screen lists all 11 `CUSREC` fields with types and lengths; the task pane shows the `Get Screen (ibm5250)` call that captured them. |
| `03-replacement-insert-test.png` | The replacement `TDSTRPGLE` in F9 Insert mode with test data entered. Function-key legend is the reproduced one: F3=Exit F5=Refresh F9=Insert F10=Input F11=Change F14=Advance F23=Delete. |
| `04-task-session-summary.png` | Full window at the end of the session. |
| `05-task-session-summary-pane.png` | The task pane from the same frame, cropped for legibility: **all tasks completed**, with a per-scene result table covering sign-on, library list, DFU definition capture, initial display, insert, update, delete and the exit counters. |

Source recording: `video/2026-08-29 212404.mp4` (229 s, 1918x1034).  Frames extracted at
8 s, 70 s, 150 s and 224 s.
