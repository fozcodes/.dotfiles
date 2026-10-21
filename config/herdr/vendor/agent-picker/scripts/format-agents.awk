# Render agent rows as display text plus a hidden "pane_id tab_id" selection.
# Derived from solidsnakedev/herdr-jump (MIT); see THIRD_PARTY_NOTICES.md.

function priority(status) {
    if (status == "blocked") return 1
    if (status == "done") return 2
    if (status == "idle") return 3
    if (status == "working") return 4
    return 5
}

function marker(status) {
    if (status == "blocked") return "!"
    if (status == "done") return "+"
    if (status == "idle") return "."
    if (status == "working") return ">"
    return "?"
}

function pane_number(pane_id) {
    if (!match(pane_id, /p[0-9]+$/)) return 0
    return substr(pane_id, RSTART + 1) + 0
}

function pane_label(title, agent, cwd) {
    if (title != "") return title
    if (agent != "") return agent
    return base(cwd)
}

function sort_rows(count,   item, cursor, key, row) {
    for (item = 2; item <= count; item++) {
        key = SORT_KEY[item]; row = ROW[item]
        for (cursor = item - 1; cursor >= 1 && SORT_KEY[cursor] > key; cursor--) {
            SORT_KEY[cursor + 1] = SORT_KEY[cursor]
            ROW[cursor + 1] = ROW[cursor]
        }
        SORT_KEY[cursor + 1] = key
        ROW[cursor + 1] = row
    }
}

is_response($0, "cli:workspace:list") {
    count = jsplit($0)
    for (item = 2; item <= count; item++) {
        record = JREC[item]
        workspace_id = jstr(record, "workspace_id")
        if (workspace_id == "") continue
        WORKSPACE_LABEL[workspace_id] = jstr(record, "label")
        WORKSPACE_NUMBER[workspace_id] = jint(record, "number", 0)
    }
    next
}

is_response($0, "cli:agent:list") { AGENTS = $0; next }

END {
    if (AGENTS == "") exit 0
    count = jsplit(AGENTS)
    row_count = 0
    for (item = 2; item <= count; item++) {
        record = JREC[item]
        pane_id = jstr(record, "pane_id")
        if (pane_id == "") continue

        status = jstr(record, "agent_status")
        if (status == "") status = "unknown"
        workspace_id = jstr(record, "workspace_id")
        workspace_number = (workspace_id in WORKSPACE_NUMBER) ? WORKSPACE_NUMBER[workspace_id] : 0
        workspace_label = (workspace_id in WORKSPACE_LABEL) ? WORKSPACE_LABEL[workspace_id] : workspace_id
        agent = jstr(record, "agent")
        cwd = jstr(record, "foreground_cwd")
        if (cwd == "") cwd = jstr(record, "cwd")
        tab_id = jstr(record, "tab_id")

        row_count++
        SORT_KEY[row_count] = sprintf("%d %06d %06d %s", priority(status), workspace_number, pane_number(pane_id), pane_id)
        ROW[row_count] = sprintf("%s %-7s %2d %-20s %-8s %s\t%s %s",
            marker(status), status, workspace_number, workspace_label,
            (agent != "" ? agent : "-"), pane_label(jstr(record, "terminal_title_stripped"), agent, cwd),
            pane_id, tab_id)
    }
    sort_rows(row_count)
    for (item = 1; item <= row_count; item++) print ROW[item]
}
