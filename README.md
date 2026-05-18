# cyberbrain

A [Pi](https://github.com/mariozechner/pi) coding agent skill for personal task tracking organized by strategic work threads.

## What It Does

- Manages tasks in a simple Markdown file (`threads.md`) grouped under strategic threads
- Supports sub-tasks (one level deep), context notes, and reference links
- Tracks completion dates
- Stores reference notes in a `notes/` directory
- Auto-commits and pushes if the data directory is a git repo

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

Examples:

```bash
# Git-tracked (auto-commits)
echo "$HOME/cyberbrain-link" > ~/.config/cyberbrain

# Dropbox (just saves files)
echo "$HOME/Dropbox/cyberbrain" > ~/.config/cyberbrain

# iCloud
echo "$HOME/Library/Mobile Documents/com~apple~CloudDocs/cyberbrain" > ~/.config/cyberbrain
```

## Usage

Just talk to Pi naturally:

- "Add a task under Billing: review API design"
- "Complete the MFA task"
- "Show me all open tasks"
- "Save a note about the architecture review"
- "Move task X under task Y"

## License

MIT
