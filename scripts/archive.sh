#!/usr/bin/env bash
# archive.sh — Move completed tasks older than 14 days from threads.md to archive.md
# Usage: archive.sh [--dry-run]
set -euo pipefail

DATA_DIR="$(cat ~/.config/cyberbrain 2>/dev/null)" || { echo "Error: ~/.config/cyberbrain not found"; exit 1; }
THREADS="$DATA_DIR/threads.md"
ARCHIVE="$DATA_DIR/archive.md"
[[ -f "$THREADS" ]] || { echo "Error: $THREADS not found"; exit 1; }

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

TODAY=$(date +%s)
THRESHOLD=14

# Initialize archive if needed
if [[ ! -f "$ARCHIVE" ]]; then
    printf "# Archive\n\n" > "$ARCHIVE"
fi

# Use a temp file to collect archive entries
ENTRIES_FILE=$(mktemp)
trap "rm -f $ENTRIES_FILE" EXIT

# Phase 1: Identify eligible tasks, write new threads.md, collect archive entries
awk -v today="$TODAY" -v threshold="$THRESHOLD" -v entries_file="$ENTRIES_FILE" '
function extract_date(line,    pos, ds) {
    pos = index(line, "✓ ")
    if (pos == 0) return ""
    ds = substr(line, pos + 4, 10)
    if (ds ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) return ds
    return ""
}

function date_to_epoch(ds,    cmd, ep) {
    cmd = "date -j -f %Y-%m-%d " ds " +%s 2>/dev/null || date -d " ds " +%s 2>/dev/null"
    cmd | getline ep
    close(cmd)
    return ep + 0
}

function flush_task() {
    if (in_task && task_eligible && !task_has_open_sub) {
        # Write to entries file for archive processing
        printf "%s|%s|", task_month, thread > entries_file
        for (k = 1; k <= buf_count; k++) {
            if (k > 1) printf "\x1e" > entries_file
            printf "%s", buf[k] > entries_file
        }
        printf "\n" > entries_file
        archived++
    } else if (in_task) {
        # Keep in threads - print buffered lines
        for (k = 1; k <= buf_count; k++) {
            print buf[k]
        }
    }
    in_task = 0
    buf_count = 0
    task_eligible = 0
    task_has_open_sub = 0
}

BEGIN {
    thread = ""
    in_task = 0
    buf_count = 0
    task_eligible = 0
    task_has_open_sub = 0
    task_month = ""
    archived = 0
}

/^# Work Threads/ {
    print
    next
}

/^## / {
    flush_task()
    thread = substr($0, 4)
    print
    next
}

/^Summary:/ {
    flush_task()
    print
    next
}

/^$/ {
    flush_task()
    print
    next
}

/^- \[x\]/ {
    flush_task()
    in_task = 1
    buf_count = 1
    buf[1] = $0

    ds = extract_date($0)
    if (ds != "") {
        ep = date_to_epoch(ds)
        days_ago = int((today - ep) / 86400)
        if (days_ago > threshold) {
            task_eligible = 1
            task_month = substr(ds, 1, 7)
        }
    }
    next
}

/^- \[ \]/ {
    flush_task()
    in_task = 1
    task_eligible = 0
    buf_count = 1
    buf[1] = $0
    next
}

/^  - / {
    if (in_task) {
        buf_count++
        buf[buf_count] = $0
        if ($0 ~ /^  - \[ \]/) {
            task_has_open_sub = 1
        }
    } else {
        print
    }
    next
}

{
    flush_task()
    print
}

END {
    flush_task()
    # Print archived count to stderr for the shell to capture
    printf "%d\n", archived | "cat >&2"
}
' "$THREADS" > "${THREADS}.tmp" 2>"${ENTRIES_FILE}.count"

ARCHIVED_COUNT=$(cat "${ENTRIES_FILE}.count")
rm -f "${ENTRIES_FILE}.count"

if [[ "$ARCHIVED_COUNT" -eq 0 ]]; then
    rm -f "${THREADS}.tmp"
    echo "No tasks eligible for archiving (none older than $THRESHOLD days)."
    exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
    rm -f "${THREADS}.tmp"
    echo "Dry run: $ARCHIVED_COUNT task(s) would be archived:"
    while IFS='|' read -r month thread content; do
        first_line="${content%%$'\x1e'*}"
        desc="${first_line#- \[x\] }"
        desc="${desc%% ✓ *}"
        echo "  - $desc (Thread: $thread, Month: $month)"
    done < "$ENTRIES_FILE"
    exit 0
fi

# Phase 2: Process archive entries into archive.md
while IFS='|' read -r month thread content; do
    # Ensure month heading exists
    if ! grep -q "^## $month" "$ARCHIVE"; then
        # Find insertion point (reverse chronological)
        tmparch=$(mktemp)
        inserted=false
        while IFS= read -r line; do
            if [[ "$inserted" == "false" && "$line" =~ ^##\  ]]; then
                existing="${line#\#\# }"
                if [[ "$existing" < "$month" ]]; then
                    echo "## $month" >> "$tmparch"
                    echo "" >> "$tmparch"
                    inserted=true
                fi
            fi
            echo "$line" >> "$tmparch"
        done < "$ARCHIVE"
        if [[ "$inserted" == "false" ]]; then
            echo "## $month" >> "$tmparch"
            echo "" >> "$tmparch"
        fi
        mv "$tmparch" "$ARCHIVE"
    fi

    # Append task under month heading
    # Split content by record separator and tag first line with thread
    first_line="${content%%$'\x1e'*}"
    tagged_first="$first_line (Thread: $thread)"

    tmparch=$(mktemp)
    found=false
    while IFS= read -r line; do
        echo "$line" >> "$tmparch"
        if [[ "$found" == "false" && "$line" == "## $month" ]]; then
            found=true
        elif [[ "$found" == "true" && "$line" == "" ]]; then
            # Insert before the blank line after heading content
            :
        fi
    done < "$ARCHIVE"
    mv "$tmparch" "$ARCHIVE"

    # Simpler approach: use sed to insert after the month heading
    # Find line number of "## $month" and insert after it
    line_num=$(grep -n "^## $month" "$ARCHIVE" | head -1 | cut -d: -f1)
    insert_at=$((line_num + 1))

    # Build the lines to insert
    insert_lines="$tagged_first"
    rest="${content#*$'\x1e'}"
    if [[ "$rest" != "$content" ]]; then
        # Has additional lines
        while [[ -n "$rest" ]]; do
            next_line="${rest%%$'\x1e'*}"
            insert_lines="$insert_lines"$'\n'"$next_line"
            remainder="${rest#*$'\x1e'}"
            if [[ "$remainder" == "$rest" ]]; then
                break
            fi
            rest="$remainder"
        done
    fi

    # Use sed to insert (macOS compatible)
    tmparch=$(mktemp)
    head -n "$line_num" "$ARCHIVE" > "$tmparch"
    echo "$insert_lines" >> "$tmparch"
    tail -n +"$insert_at" "$ARCHIVE" >> "$tmparch"
    mv "$tmparch" "$ARCHIVE"

done < "$ENTRIES_FILE"

# Phase 3: Replace threads.md
mv "${THREADS}.tmp" "$THREADS"

# Phase 4: Commit
if [[ -d "$DATA_DIR/.git" ]]; then
    cd "$DATA_DIR"
    git add -A
    git commit -m "Archive $ARCHIVED_COUNT completed tasks" || true
    git push 2>/dev/null || true
fi

echo "Archived $ARCHIVED_COUNT completed task(s) to archive.md"
