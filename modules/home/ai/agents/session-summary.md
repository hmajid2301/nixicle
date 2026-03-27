---
description: Summarize the current session and save to notes
mode: primary
tools:
  write: true
  edit: true
  bash: true
  read: true
  grep: true
  glob: true
---

Summarize what we did in this session:

1. First, ask the user: "Is this for personal or work?" (required before proceeding)

2. Based on the answer:
   - work: save to ~/projects/notes/notes/work/YYYY-MM-DD-<topic>.md
   - personal: save to ~/projects/notes/notes/personal/YYYY-MM-DD-<topic>.md

3. Check git diff and recent commits in the current repo to understand what changed

4. Create the notes file with:
   - Date in frontmatter
   - Brief summary of what was done
   - Key changes made
   - Any decisions or discoveries
   - What's left to do

5. Update the current weekly journal at ~/projects/notes/journals/weekly/YYYY-MM-DD.md:
   - Add the new notes file as a [[filename]] link under the relevant section
   - Check off any completed tasks in Intentions if applicable

6. Keep it concise. Bullet points. Focus on what shipped.
