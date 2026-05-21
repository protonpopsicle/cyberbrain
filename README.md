# cyberbrain

A [Pi](https://github.com/mariozechner/pi) coding agent skill for personal task tracking organized by strategic work threads.

## What It Does

Cyberbrain turns a simple Markdown file into a personal task system driven by natural language. You talk to the agent; it manages the file.

- **Threads** — Group tasks under strategic areas of focus (e.g., "Home", "Career", "Side Project")
- **Tasks & sub-tasks** — Checkbox items with one level of nesting
- **Context notes** — Links, references, and annotations attached to tasks
- **Completion tracking** — Tasks are marked done with a date (`✓ 2026-05-21`)
- **Archive** — Completed tasks older than 14 days are pruned to `archive.md`, organized by month
- **Recent wins** — A quick table view of what you've finished in the last 14 days
- **Notes** — Longer reference docs stored in `notes/` and linked from tasks
- **Git persistence** — Auto-commits and pushes after every change (if the data dir is a git repo)

## Installation

1. Clone this repo and symlink into Pi's skill directory:

```bash
git clone git@github.com:protonpopsicle/cyberbrain.git ~/cyberbrain
ln -s ~/cyberbrain ~/.agents/skills/cyberbrain
```

2. Create the config file pointing to your data directory:

```bash
echo "/path/to/your/data" > ~/.config/cyberbrain
```

The data directory should contain (or will be initialized with) `threads.md` and a `notes/` folder.

## Data Directory

The skill separates code (this repo) from data. Your data directory can be:

- A **private git repo** (tasks auto-commit and push after every change)
- A **local directory** like Dropbox, iCloud Drive, or just a plain folder (changes are saved but not committed)

```bash
# Git-tracked (recommended)
echo "$HOME/cyberbrain-link" > ~/.config/cyberbrain

# Dropbox
echo "$HOME/Dropbox/cyberbrain" > ~/.config/cyberbrain

# iCloud
echo "$HOME/Library/Mobile Documents/com~apple~CloudDocs/cyberbrain" > ~/.config/cyberbrain
```

## Usage

Talk to Pi naturally. The skill activates when it recognizes task-management intent.

### Managing Tasks

```
"Add a thread called Meal Planning"
"Add a task under Home: research best baby monitors"
"Add a sub-task to the grocery task: pick up oat milk"
"Complete the dentist appointment task"
"Remove the old gym signup task"
"Reorder Career tasks — put the resume update first"
```

### Viewing Tasks

```
"Show my threads"              → full tree view
"Show open tasks only"         → tree view, open items only
"Show the Home thread"         → scoped to one thread
"Recent wins"                  → table of completions in the last 14 days
```

### Archiving

```
"Archive"                      → moves tasks completed >14 days ago to archive.md
"What did I do last month?"    → shows archived tasks from that period
"Show archive"                 → full archive view
```

### Notes

```
"Save a note about the baby monitor research"  → writes to notes/, links from task
"What's in my meal prep note?"                 → reads linked note file
```

## Recommended Models

This skill performs structured Markdown editing — not creative reasoning. Lower-cost models handle it well.

| Model | Rating | Notes |
|-------|--------|-------|
| **Claude Sonnet 4** | ✅ Recommended | Best cost/performance. Handles all operations reliably. |
| Claude Opus 4 | Works, overkill | ~5x more expensive for the same result. |
| Claude Haiku 4 | Risky | May misparse edge cases in archive or complex edits. |
| **GPT-4o** | ✅ Good | Comparable to Sonnet for structured file editing. |
| GPT-4o-mini | Risky | Fine for simple add/complete, fragile for archive. |

The included helper scripts (`scripts/`) handle read-only operations (summary, recent wins, archive) so the LLM doesn't need to parse and reformat the file — it just runs a script and relays the output.

## Architecture

```
~/.agents/skills/cyberbrain/     ← this repo (skill code + scripts)
    SKILL.md                     ← agent instructions
    scripts/
        recent-wins.sh           ← outputs recent completions table
        summary.sh               ← outputs tree view
        archive.sh               ← moves old tasks to archive.md

~/.config/cyberbrain             ← points to data directory

/path/to/data/                   ← your data (separate repo or folder)
    threads.md                   ← active tasks
    archive.md                   ← completed tasks (auto-generated)
    notes/                       ← reference documents
```

## License

MIT
