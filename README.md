# cyberbrain

A [Pi](https://github.com/mariozechner/pi) coding agent skill for personal task tracking organized by strategic work threads.

## What It Does

- Manages tasks in a simple Markdown file (`threads.md`) grouped under strategic threads
- Supports sub-tasks (one level deep), context notes, and reference links
- Tracks completion dates
- Stores reference notes in a `notes/` directory
- Auto-commits and pushes after every change

## Installation

Clone this repo and symlink into Pi's global skill directory:

```bash
git clone git@github-personal:protonpopsicle/cyberbrain.git ~/cyberbrain
ln -s ~/cyberbrain ~/.agents/skills/cyberbrain
```

## Usage

The skill expects a separate git-tracked data repo containing `threads.md` and `notes/`. Point the skill's paths at your data repo by convention (`~/cyberbrain-link/`).

Just talk to Pi naturally:
- "Add a task under Billing: review API design"
- "Complete the MFA task"
- "Show me all open tasks"
- "Save a note about the architecture review"

## Data Repo

The task data (threads, notes) is stored separately from this skill repo. This allows the skill to be public/shared while the data stays private. See your data repo's README for setup instructions.
