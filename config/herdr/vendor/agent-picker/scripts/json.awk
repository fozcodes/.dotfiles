# Minimal JSON helpers for the compact one-line responses emitted by Herdr.
# Derived from solidsnakedev/herdr-jump (MIT); see THIRD_PARTY_NOTICES.md.

function jsplit(s,   i, n, c, in_string, escaped, previous, start, count) {
    delete JREC
    n = length(s); in_string = 0; escaped = 0; previous = ""; start = 1; count = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (in_string) {
            if (escaped) escaped = 0
            else if (c == "\\") escaped = 1
            else if (c == "\"") in_string = 0
            continue
        }
        if (c == "\"") { in_string = 1; previous = "\""; continue }
        if (c == "{" && (previous == "[" || previous == ",")) {
            JREC[++count] = substr(s, start, i - start)
            start = i
        }
        if (c != " " && c != "\t" && c != "\n") previous = c
    }
    JREC[++count] = substr(s, start)
    return count
}

function jstr(s, key,   remainder, i, n, c, value) {
    if (!match(s, "\"" key "\":\"")) return ""
    remainder = substr(s, RSTART + RLENGTH)
    n = length(remainder); value = ""
    for (i = 1; i <= n; i++) {
        c = substr(remainder, i, 1)
        if (c == "\"") break
        if (c != "\\") { value = value c; continue }
        i++; c = substr(remainder, i, 1)
        if (c == "n" || c == "r" || c == "t") value = value " "
        else if (c == "u") { value = value "?"; i += 4 }
        else value = value c
    }
    return value
}

function jint(s, key, default_value,   value) {
    if (!match(s, "\"" key "\":-?[0-9]+")) return default_value
    value = substr(s, RSTART, RLENGTH)
    sub(/^"[^"]*":/, "", value)
    return value + 0
}

function base(path) {
    if (path == "" || path == "/") return path
    sub(/\/+$/, "", path)
    sub(/^.*\//, "", path)
    return path
}

function is_response(line, request_id) {
    return index(line, "{\"id\":\"" request_id "\"") == 1
}
