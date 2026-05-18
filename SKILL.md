---
name: cyberbrain
description: Personal task tracking organized by strategic work threads. Add, update, complete, and summarize tasks in a simple Markdown file. Tasks are grouped under threads (strategic areas of focus). Supports sub-tasks one level deep.
---

# Cyberbrain – Personal Work Thread & Task Tracker

Manage the user's personal task list in `~/cyberbrain-link/threads.md` and reference notes in `~/cyberbrain-link/notes/`. The repo is git-tracked; commit and push after every change.

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
- **Ordering**: Preserve user's order. New threads append at bottom. Completed tasks stay in place.
- **Style**: Task descriptions start with a capital letter. Dates use `YYYY-MM-DD`.

## Operations

Read the file before making changes. Match tasks/threads by substring or close wording.

- **Add** thread, task, sub-task, or context note in the appropriate location.
- **Complete** a task: mark `[x]`, append date, complete open sub-tasks.
- **Update** a task's description, preserving checkbox state and completion date.
- **Remove** a task and its children — only when explicitly asked.
- **Reorder** tasks or threads when asked.
- **Summarize** as a tree view (see below).
- **Default** (no specific request): show full tree view.

## Notes Directory

The `~/cyberbrain-link/notes/` folder stores work-relevant reference docs (meeting notes, research, analysis). When the user asks to save a note:

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

## Git

After every change, commit and push:

```bash
cd ~/cyberbrain-link && git add -A && git commit -m "<short description>" && git push
```

Use brief commit messages (e.g., "Add task: review API gateway design"). If `threads.md` doesn't exist, create it with `# Work Threads` and commit as "Initialize work threads".
