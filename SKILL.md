---
name: cyberbrain
description: Personal task tracking organized by strategic work threads. Add, update, complete, and summarize tasks in a simple Markdown file. Tasks are grouped under threads (strategic areas of focus). Supports sub-tasks one level deep.
---

# Cyberbrain – Personal Work Thread & Task Tracker

Manage the user's personal task list and reference notes. Tasks live in `threads.md` and notes in `notes/` within the user's data directory.

## Configuration

Read `~/.config/cyberbrain` to get the data directory path. The file contains a single line: the absolute path to the directory containing `threads.md` and `notes/`.

If the file does not exist, ask the user where their cyberbrain data is stored, then create the config file.

Example config:
```
/Users/alice/cyberbrain-link
```

Throughout these instructions, `$DATA_DIR` refers to the path read from this config file.

## File Format

```markdown
# Work Threads

## Thread Name
Summary: One-line description of this strategic area.

- [ ] Task description
  - See: [Relevant Page](https://wiki.example.com/relevant-page)
  - See: [Local Notes](./notes/research.md)
  - [ ] Sub-task description
  - [x] Completed sub-task ✓ 2026-05-11
- [x] Completed task ✓ 2026-05-11
```

### Rules

- **Threads**: `##` headings under `# Work Threads`, with optional `Summary:` line.
- **Tasks**: Top-level `- [ ]` / `- [x]` items under a thread.
- **Sub-tasks**: Indented two spaces under parent task, also checkboxes. One level deep max.
- **Context notes**: Indented two spaces, no checkbox — for links, references, or annotations.
- **Links**: Use `[display text](url)` for URLs and local file references so they render clickable. Raw URLs are fine if short (under ~60 chars).
- **Completing**: Change `- [ ]` to `- [x]` and append ` ✓ YYYY-MM-DD`. Complete child sub-tasks too.
- **Ordering**: Preserve user's order. New threads append at bottom. Completed tasks stay in place (until archived).
- **Style**: Task descriptions start with a capital letter. Dates use `YYYY-MM-DD`.

## Operations

Read the file before making changes. Match tasks/threads by substring or close wording.

- **Add** thread, task, sub-task, or context note in the appropriate location.
- **Complete** a task: mark `[x]`, append date, complete open sub-tasks.
- **Update** a task's description, preserving checkbox state and completion date.
- **Remove** a task and its children — only when explicitly asked.
- **Reorder** tasks or threads when asked.
- **Summarize** as a tree view (see below).
- **Archive** completed tasks: move completed tasks older than 14 days to `archive.md`. See Archive section below.
- **Default** (no specific request): show full tree view.

## Archive

The archive (`$DATA_DIR/archive.md`) stores completed tasks pruned from `threads.md`. It is organized chronologically by completion month — not by thread — since chronology is more useful for reflection.

### Archive File Format

```markdown
# Archive

## 2026-05

- [x] Review API gateway design ✓ 2026-05-11 (Thread: Platform Migration)
  - [x] Check rate limiting config ✓ 2026-05-10
- [x] Write onboarding doc ✓ 2026-05-08 (Thread: Team Enablement)

## 2026-04

- [x] Set up CI pipeline ✓ 2026-04-22 (Thread: Platform Migration)
```

### Archive Rules

- **Trigger**: User asks to archive (e.g., "archive", "prune", "clean up completed tasks").
- **Threshold**: Only completed tasks (`- [x]`) with a completion date older than 14 days are archived. Recent completions stay in `threads.md` for context.
- **Grouping**: Archived tasks are grouped under `## YYYY-MM` headings (the month of completion).
- **Thread tag**: Append ` (Thread: <thread name>)` to each top-level archived task so its origin is preserved as metadata.
- **Sub-tasks and context notes**: Move together with their parent task, preserving indentation.
- **Month sections**: Insert new month headings in reverse chronological order (newest first). Append tasks within a month section in the order they are processed.
- **Partial completion**: A parent task with a mix of completed and open sub-tasks is NOT archived. Only fully completed tasks (parent `[x]` with all sub-tasks `[x]`) are eligible.
- **Empty threads**: If archiving removes all items from a thread, leave the thread heading and summary in `threads.md` (the user can remove it manually).
- **Initialization**: If `archive.md` doesn't exist, create it with `# Archive\n` before appending.

### Archive Procedure

1. Read `threads.md`. Identify all top-level `- [x]` tasks with completion dates older than 14 days from today.
2. Read (or create) `archive.md`.
3. For each eligible task, determine its completion month (`YYYY-MM`) and thread name.
4. Append the task (with sub-tasks/context notes) under the appropriate month heading in `archive.md`.
5. Remove the task (and its children) from `threads.md`.
6. Write both files.
7. Commit: `"Archive N completed tasks"`.

### Viewing the Archive

When the user asks to see archived/completed tasks (e.g., "what did I do last month?", "show archive"), read `archive.md` and present it using the tree view format, scoped by time or thread as requested.

### Recent Wins

When the user asks for "recent wins", "recent completions", or "what did I finish lately", show all completed tasks that are *inside* the 14-day archive window (i.e., completed within the last 14 days) as a Markdown table:

```
| Task | Thread | Completed | Days ago |
|------|--------|-----------|----------|
| Complete MFA setup for Mac | Compliance | 2026-05-12 | 9 |
| Replace Copilot workflows with Pi | Learning | 2026-05-11 | 10 |
```

**Rules:**
- Include both top-level tasks and sub-tasks (sub-tasks shown with their own description, not the parent's).
- Sort by completion date descending (most recent first).
- "Thread" column shows the `##` heading the task lives under.
- "Days ago" is relative to today.
- End with a count line: `N wins in the last 14 days`.

## Notes Directory

The `$DATA_DIR/notes/` folder stores reference docs (meeting notes, research, analysis). When the user asks to save a note:

1. Write a Markdown file to `notes/` with a descriptive kebab-case filename.
2. Link it from the relevant task: `- See: [Note Title](./notes/filename.md)`

When a task links to a note, read that file for context if the user asks about it.

## Tree View

Use this format when summarizing:

```
📋 Work Threads
├── Thread Name — summary text
│   ├── ○ Open task
│   │   ├── See: Display Text (source)
│   │   ├── ○ Open sub-task
│   │   └── ✅ Done sub-task (2026-05-11)
│   └── ✅ Done task (2026-05-11)
└── Last Thread
    └── (no tasks)

2 threads · 3 open · 2 completed
```

- Standard box-drawing tree characters. `○` for open, `✅` for completed (with date).
- Context notes: use the Markdown link display text; append a source hint like `(SharePoint)`, `(TWiki)`, `(GitHub)`, `(local)` for linked notes.
- Scoping: all threads, one thread, or open-only — based on what the user asks.
- End with count line: `N threads · N open · N completed`.

## Persistence

After every change, persist the data. If `$DATA_DIR` is a git repository, commit and push:

```bash
cd $DATA_DIR && git add -A && git commit -m "<short description>" && git push
```

Use brief commit messages (e.g., "Add task: review API gateway design"). If `threads.md` doesn't exist, create it with `# Work Threads` and commit as "Initialize work threads".

If `$DATA_DIR` is not a git repository, simply save the file (no commit/push needed).
