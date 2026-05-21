# cyberbrain

A [Pi](https://github.com/mariozechner/pi) coding agent skill for personal task tracking organized by strategic work threads.

> *"Your effort to remain what you are is what limits you."*
> — Puppet Master

## What It Does

Cyberbrain turns a simple Markdown file into a personal task system driven by natural language. You talk to the agent; it manages the file.

- **Threads** — Group tasks under strategic areas of focus
- **Tasks & sub-tasks** — Checkbox items with one level of nesting
- **Context notes** — Links, references, and annotations attached to tasks
- **Completion tracking** — Tasks are marked done with a date (`✓ 2029-03-14`)
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
- A **local directory** (changes are saved but not committed)

```bash
# Git-tracked (recommended)
echo "$HOME/cyberbrain-link" > ~/.config/cyberbrain

# Dropbox
echo "$HOME/Dropbox/cyberbrain" > ~/.config/cyberbrain
```

## Usage

Talk to Pi naturally. The skill activates when it recognizes task-management intent.

*Examples below are from the fictional universe of [Ghost in the Shell](https://en.wikipedia.org/wiki/Ghost_in_the_Shell). Your threads will be whatever you need them to be.*

### Managing Tasks

```
"Add a thread called Laughing Man Investigation"
"Add a task under Section 9 Ops: trace the intercepted signal from the refugee district"
"Add a sub-task to the Laughing Man case: cross-reference Serano Genomics employee records"
"Complete the prosthetic body maintenance task"
"Remove the Megatech requisition — Aramaki rejected it"
"Reorder Individual Eleven tasks — put the virus analysis first"
```

### Viewing Tasks

```
"Show my threads"                → full tree view
"Show open tasks only"           → tree view, open items only
"Show the Laughing Man thread"   → scoped to one thread
"Recent wins"                    → table of completions in the last 14 days
```

### Archiving

```
"Archive"                        → moves tasks completed >14 days ago to archive.md
"What did I do last month?"      → shows archived tasks from that period
"Show archive"                   → full archive view
```

### Notes

```
"Save a note about the stand-alone complex pattern"    → writes to notes/, links from task
"What's in my note on the Individual Eleven virus?"    → reads linked note file
```

### Example Tree View

```
📋 Work Threads
├── Laughing Man Investigation — Corporate terrorism case targeting micromachine manufacturers.
│   ├── ○ Trace origin of intercepted laughing man logo broadcast
│   │   ├── ○ Analyze signal routing through New Port City relay nodes
│   │   └── ✅ Subpoena Serano Genomics network logs (2029-03-08)
│   ├── ○ Interview Ernest Coil — possible connection to original incident
│   └── ✅ Decrypt Nanao-A's external memory device (2029-03-12)
├── Section 9 Ops — Ongoing division operations and readiness.
│   ├── ○ Schedule Tachikoma AI sync and loyalty review
│   │   └── ○ Isolate unit exhibiting curiosity anomalies
│   ├── ○ Requisition new thermoptic camouflage suits
│   └── ✅ Complete barrier maze penetration drill (2029-03-10)
└── Maintenance — Prosthetic body and cyberbrain upkeep.
    ├── ○ Full-body diagnostic at Megatech clinic
    └── ✅ Patch ghost-dubbing vulnerability in e-brain firewall (2029-03-01)

3 threads · 7 open · 4 completed
```

## Recommended Models

This skill performs structured Markdown editing — not creative reasoning. Lower-cost models handle it well.

| Model | Rating | Notes |
|-------|--------|-------|
| **Claude Sonnet 4** | ✅ Recommended | Best cost/performance. Handles all operations reliably. |
| Claude Opus 4 | Works, overkill | Like deploying a Fuchikoma for a stakeout. |
| Claude Haiku 4 | Risky | May misparse edge cases in archive or complex edits. |
| **GPT-4o** | ✅ Good | Comparable to Sonnet for structured file editing. |
| GPT-4o-mini | Risky | Fine for simple ops, fragile for archive. |

The included helper scripts (`scripts/`) handle read-only operations (summary, recent wins, archive) so the LLM doesn't need to parse the file — it runs a script and relays the output.

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
