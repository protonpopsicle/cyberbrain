#!/usr/bin/env bash
# recent-wins.sh — Output recently completed tasks (within 14-day archive window)
# Usage: recent-wins.sh [days]  (default: 14)
set -euo pipefail

WINDOW="${1:-14}"
DATA_DIR="$(cat ~/.config/cyberbrain 2>/dev/null)" || { echo "Error: ~/.config/cyberbrain not found"; exit 1; }
THREADS="$DATA_DIR/threads.md"
[[ -f "$THREADS" ]] || { echo "Error: $THREADS not found"; exit 1; }

TODAY=$(date +%s)

awk -v today="$TODAY" -v window="$WINDOW" '
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

function shorten(desc) {
    # Remove completion mark and date
    sub(/ ✓ [0-9]{4}-[0-9]{2}-[0-9]{2}$/, "", desc)
    # Remove Guarantee: and ACTION REQUIRED: prefixes
    sub(/^Guarantee: /, "", desc)
    sub(/^ACTION REQUIRED: /, "", desc)
    # Remove "by YYYY-MM-DD"
    gsub(/ by [0-9]{4}-[0-9]{2}-[0-9]{2}/, "", desc)
    # Remove email addresses
    gsub(/ <[^>]+>/, "", desc)
    # Remove trailing parenthetical
    sub(/ \([^)]*\)$/, "", desc)
    return desc
}

BEGIN {
    thread = ""
    count = 0
}

/^## / {
    thread = substr($0, 4)
    next
}

/^- \[x\]/ {
    ds = extract_date($0)
    if (ds == "") next
    ep = date_to_epoch(ds)
    days_ago = int((today - ep) / 86400)
    if (days_ago >= 0 && days_ago <= window) {
        desc = $0
        sub(/^- \[x\] /, "", desc)
        desc = shorten(desc)
        tasks[count] = desc
        threads[count] = thread
        days[count] = days_ago
        count++
    }
    next
}

/^  - \[x\]/ {
    ds = extract_date($0)
    if (ds == "") next
    ep = date_to_epoch(ds)
    days_ago = int((today - ep) / 86400)
    if (days_ago >= 0 && days_ago <= window) {
        desc = $0
        sub(/^  - \[x\] /, "", desc)
        desc = shorten(desc)
        tasks[count] = desc " (sub-task)"
        threads[count] = thread
        days[count] = days_ago
        count++
    }
    next
}

END {
    if (count == 0) {
        print "No completed tasks in the last " window " days."
        exit
    }

    # Sort by days_ago ascending (most recent first)
    for (i = 0; i < count - 1; i++) {
        for (j = i + 1; j < count; j++) {
            if (days[j] < days[i]) {
                tmp = tasks[i]; tasks[i] = tasks[j]; tasks[j] = tmp
                tmp = threads[i]; threads[i] = threads[j]; threads[j] = tmp
                tmp = days[i]; days[i] = days[j]; days[j] = tmp
            }
        }
    }

    print "| Task | Thread | Days ago |"
    print "|------|--------|----------|"
    for (i = 0; i < count; i++) {
        printf "| %s | %s | %d |\n", tasks[i], threads[i], days[i]
    }
    print ""
    print count " wins in the last " window " days"
}
' "$THREADS"
