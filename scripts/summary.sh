#!/usr/bin/env bash
# summary.sh — Output tree view of work threads
# Usage: summary.sh [--thread "Name"] [--open-only]
set -euo pipefail

DATA_DIR="$(cat ~/.config/cyberbrain 2>/dev/null)" || { echo "Error: ~/.config/cyberbrain not found"; exit 1; }
THREADS="$DATA_DIR/threads.md"
[[ -f "$THREADS" ]] || { echo "Error: $THREADS not found"; exit 1; }

FILTER_THREAD=""
OPEN_ONLY="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --thread) FILTER_THREAD="$2"; shift 2 ;;
        --open-only) OPEN_ONLY="true"; shift ;;
        *) shift ;;
    esac
done

awk -v filter_thread="$FILTER_THREAD" -v open_only="$OPEN_ONLY" '
function extract_date(line,    pos, ds) {
    pos = index(line, "✓ ")
    if (pos == 0) return ""
    ds = substr(line, pos + 4, 10)
    if (ds ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) return ds
    return ""
}

function detect_source(line) {
    if (index(line, "sharepoint.com") > 0) return "SharePoint"
    if (index(line, "wiki.web.att.com") > 0) return "TWiki"
    if (index(line, "github.com") > 0) return "GitHub"
    if (index(line, "./notes/") > 0) return "local"
    return "link"
}

function extract_link_text(line,    start, end, text) {
    start = index(line, "[")
    if (start == 0) return ""
    end = index(line, "]")
    if (end <= start) return ""
    text = substr(line, start + 1, end - start - 1)
    return text
}

BEGIN {
    t = -1
    thread_count = 0
    open_count = 0
    done_count = 0
    skip = 0
}

/^# Work Threads/ { next }

/^## / {
    name = substr($0, 4)
    if (filter_thread != "" && name != filter_thread) {
        skip = 1
        next
    }
    skip = 0
    t++
    thread_count++
    tnames[t] = name
    tsummaries[t] = ""
    tcount[t] = 0
    next
}

skip { next }

/^Summary:/ {
    if (t < 0) next
    s = $0
    sub(/^Summary: */, "", s)
    tsummaries[t] = s
    next
}

/^- \[ \]/ {
    if (t < 0) next
    open_count++
    desc = $0
    sub(/^- \[ \] /, "", desc)
    n = tcount[t]
    items[t, n] = "○ " desc
    tcount[t] = n + 1
    next
}

/^- \[x\]/ {
    if (t < 0) next
    if (open_only == "true") next
    done_count++
    desc = $0
    sub(/^- \[x\] /, "", desc)
    ds = extract_date(desc)
    sub(/ ✓ [0-9]{4}-[0-9]{2}-[0-9]{2}$/, "", desc)
    n = tcount[t]
    if (ds != "") {
        items[t, n] = "✅ " desc " (" ds ")"
    } else {
        items[t, n] = "✅ " desc
    }
    tcount[t] = n + 1
    next
}

/^  - \[ \]/ {
    if (t < 0) next
    open_count++
    desc = $0
    sub(/^  - \[ \] /, "", desc)
    n = tcount[t]
    items[t, n] = "    ○ " desc
    tcount[t] = n + 1
    next
}

/^  - \[x\]/ {
    if (t < 0) next
    if (open_only == "true") next
    done_count++
    desc = $0
    sub(/^  - \[x\] /, "", desc)
    ds = extract_date(desc)
    sub(/ ✓ [0-9]{4}-[0-9]{2}-[0-9]{2}$/, "", desc)
    n = tcount[t]
    if (ds != "") {
        items[t, n] = "    ✅ " desc " (" ds ")"
    } else {
        items[t, n] = "    ✅ " desc
    }
    tcount[t] = n + 1
    next
}

/^  - See:/ {
    if (t < 0) next
    source = detect_source($0)
    text = extract_link_text($0)
    if (text != "") {
        n = tcount[t]
        items[t, n] = "    See: " text " (" source ")"
        tcount[t] = n + 1
    }
    next
}

/^  - / {
    if (t < 0) next
    # Other context lines
    desc = $0
    sub(/^  - /, "", desc)
    n = tcount[t]
    items[t, n] = "    " desc
    tcount[t] = n + 1
    next
}

END {
    print "📋 Work Threads"

    for (i = 0; i <= t; i++) {
        is_last = (i == t)
        branch = is_last ? "└── " : "├── "
        prefix = is_last ? "    " : "│   "

        if (tsummaries[i] != "") {
            printf "%s%s — %s\n", branch, tnames[i], tsummaries[i]
        } else {
            printf "%s%s\n", branch, tnames[i]
        }

        n = tcount[i]
        if (n == 0) {
            printf "%s└── (no tasks)\n", prefix
        } else {
            for (j = 0; j < n; j++) {
                is_last_item = (j == n - 1)
                ib = is_last_item ? "└── " : "├── "
                printf "%s%s%s\n", prefix, ib, items[i, j]
            }
        }
    }

    print ""
    printf "%d threads · %d open · %d completed\n", thread_count, open_count, done_count
}
' "$THREADS"
