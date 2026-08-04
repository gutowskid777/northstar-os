# Routine: Your Move refresh
# STATUS: ACTIVE
# Trigger: session-end sync, or "what's my move"
# Writes: brain/your-move.md, the "▶ YOUR MOVE" block in brain/brain-state.md

Regenerates the one-screen answer to "what should I do next." Runs at session end so it's already
correct the next time you open anything.

## Output shape (locked)

```
🎯 TOP MOVE
   <one thing. Not three. The single highest-leverage next action.>
   Why now: <one line, tied to a goal in goals.md>

📊 RANKED NEXT
   2. <project> — <next action>
   3. <project> — <next action>
   4. <project> — <next action>

🚧 RABBIT-HOLE FLAG
   <what you're at risk of over-investing in right now, or "none — current work is on the #1">

   Sources: <the files this was built from>
```

## Rules

- **One top move.** The value of this file is that it removes the choice. Two top moves is zero
  top moves.
- **The rabbit-hole flag is mandatory.** "None" is a valid answer and must be stated explicitly.
  An omitted flag reads identical to a clean bill of health, and those are very different things.
- **Ranked list stays at three or four.** It's a shortlist, not the queue. The queue is the queue.
- **Every move traces to a goal.** If a move can't be tied to something in `goals.md`, that's the
  finding: surface it rather than laundering it into the list.
- **Built from files, not from memory.** Re-read `goals.md`, `brain-state.md`, and the open rows in
  `queue.json` first. A brief written from what you remember of the session is exactly how stale
  state gets baked in.

## Optional: mirror it somewhere you'll actually see it

The file is only useful if you read it. Pushing it to a phone note, a widget, or a terminal
greeting turns it from a file you'd have to remember to open into something that shows up on its
own. Wire that up in whatever way fits your setup, and record the target in
`brain/routines/config.json`.
