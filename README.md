# cyberbrain

A standards-compliant coding agent skill for personal task tracking organized by strategic work threads.

It works with any agent that supports the skill format.

## What It Does

Cyberbrain turns a simple Markdown file into a personal task system driven by natural language. You talk to your agent; it manages the file.

- **Threads** — Group tasks under strategic areas of focus
- **Tasks & sub-tasks** — Checkbox items with one level of nesting
- **Context notes** — Links, references, and annotations attached to tasks
- **Completion tracking** — Tasks are marked done with a date (`✓ 2029-03-14`)
- **Archive** — Completed tasks older than 14 days are pruned to `archive.md`, organized by month
- **Recent wins** — A quick table view of what you've finished in the last 14 days
- **Notes** — Longer reference docs stored in `notes/` and linked from tasks
- **Git persistence** — Auto-commits and pushes after every change (if the data dir is a git repo)

## Installation

1. Clone this repo and install it into your agent’s standard skill directory, or symlink it there:

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
- A **local directory** (changes are saved but not committed)

```bash
# Git-tracked (recommended)
echo "$HOME/cyberbrain-link" > ~/.config/cyberbrain

# Dropbox
echo "$HOME/Dropbox/cyberbrain" > ~/.config/cyberbrain
```

## Usage

Talk to your agent naturally. The skill activates when it recognizes task-management intent.

### Viewing Tasks

```
"Show my threads"                → full tree view
"Show open tasks only"           → tree view, open items only
"Show the Ghost Dubbing thread"  → scoped to one thread
"Recent wins"                    → table of completions in the last 14 days
```

### Web Dashboard

Cyberbrain includes a small local-only dashboard for browsing your threads in a browser:

```bash
python3 scripts/web.py
```

It reads the same `~/.config/cyberbrain` data directory, serves only on `127.0.0.1`, and opens your browser automatically. Use `--daemon` to start it in the background or `--no-open` to suppress browser launch.

### Archiving

```
"Archive"                        → moves tasks completed >14 days ago to archive.md
"What did I do last month?"      → shows archived tasks from that period
"Show archive"                   → full archive view
```

### Notes

```
"Save a note about Thinks Tanks"                       → writes to notes/, links from task
"What's in my note on the Individual Eleven virus?"    → reads linked note file
```

## Recommended Models

This skill performs structured Markdown editing — not creative reasoning. Lower-cost models handle it well. The included helper scripts (`scripts/`) handle read-only operations (summary, recent wins, archive) so the LLM doesn't need to parse the file — it runs a script and relays the output.

## Architecture

```
~/.agents/skills/cyberbrain/     ← this repo (skill code + scripts)
    SKILL.md                     ← agent instructions
    scripts/
        recent-wins.sh           ← outputs recent completions table
        summary.sh               ← outputs tree view
        archive.sh               ← moves old tasks to archive.md
        web.py                   ← local browser dashboard
    dashboard/
        index.html               ← dashboard UI

~/.config/cyberbrain             ← points to data directory

/path/to/data/                   ← your data (separate repo or folder)
    threads.md                   ← active tasks
    archive.md                   ← completed tasks (auto-generated)
    notes/                       ← reference documents
```

## License

MIT
