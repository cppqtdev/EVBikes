import re, sys, os, io

IND = "    "
SKIP_GENERATED = {
    "RpmBar.qml", "PowerBar.qml", "HexGauge.qml", "BatteryColumn.qml",
}

def scan(s):
    out, i, q, depth = [], 0, None, 0
    while i < len(s):
        c = s[i]
        if q:
            if c == "\\":
                out.append((i, c, True, depth)); i += 1
                if i < len(s): out.append((i, s[i], True, depth)); i += 1
                continue
            if c == q: q = None
            out.append((i, c, True, depth)); i += 1; continue
        if c in "\"'":
            q = c; out.append((i, c, True, depth)); i += 1; continue
        if c in "{[(": out.append((i, c, False, depth)); depth += 1; i += 1; continue
        if c in "}])": depth -= 1; out.append((i, c, False, depth)); i += 1; continue
        out.append((i, c, False, depth)); i += 1
    return out, q, depth

def balanced(s):
    toks, q, depth = scan(s)
    if q is not None or depth != 0: return False
    return not any(d < 0 for _, _, instr, d in toks if not instr)

def split_members(body):
    toks, _, _ = scan(body)
    parts, start = [], 0
    for i, c, instr, depth in toks:
        if c == ";" and not instr and depth == 0:
            parts.append(body[start:i]); start = i + 1
    parts.append(body[start:])
    return [p.strip() for p in parts if p.strip()]

# an element declaration, optionally introduced by "prop:" (transform: Rotation { ... })
ELEM = re.compile(
    r'^((?:[a-z][A-Za-z0-9_.]*\s*:\s*)?'          # optional "prop: "
    r'[A-Z][A-Za-z0-9_.]*'                        # Type
    r'(?:\s+on\s+[A-Za-z_][A-Za-z0-9_.]*)?)'      # optional "on prop"
    r'\s*\{(.*)\}$', re.S)

def expand(text, indent):
    t = text.strip()
    m = ELEM.match(t)
    if not m or not balanced(t):
        return [indent + t]
    head, body = m.group(1), m.group(2)
    if not balanced(body):
        return [indent + t]
    members = split_members(body)
    if not members:
        return [indent + re.sub(r'\s+', ' ', head) + " {}"]
    lines = [indent + re.sub(r'\s*:\s*', ": ", head) + " {"]
    for mem in members:
        lines += expand(mem, indent + IND)
    lines.append(indent + "}")
    return lines

def norm(s):
    toks, _, _ = scan(s)
    out = []
    for i, c, instr, _ in toks:
        if instr: out.append(c)
        elif c.isspace() or c == ";": continue
        else: out.append(c)
    return "".join(out)

ELEM_LINE = re.compile(r'^(\s*)([A-Z][A-Za-z0-9_.]*(?:\s+on\s+[A-Za-z_][A-Za-z0-9_.]*)?\s*\{.*\})\s*$')
PROP_LINE = re.compile(r'^(\s*)([a-z][A-Za-z0-9_.]*\s*:.*)$')

def rewrite(ln):
    """Return a list of lines, or None to leave the line alone."""
    m = ELEM_LINE.match(ln)
    if m:
        return expand(m.group(2), m.group(1))
    m = PROP_LINE.match(ln)
    if m:
        indent, text = m.group(1), m.group(2).rstrip()
        if text.startswith(("property", "readonly", "function", "signal")): return None
        if not balanced(text): return None
        members = split_members(text)
        if len(members) < 2:
            # single member: only worth touching if it is an expandable element value
            out = expand(text, indent)
            return out if len(out) > 1 else None
        out = []
        for mem in members: out += expand(mem, indent)
        return out
    return None

def process(path, apply):
    src = io.open(path, encoding="utf-8").read()
    out, changed = [], 0
    for ln in src.split("\n"):
        new = rewrite(ln)
        if new is None or new == [ln]:
            out.append(ln); continue
        if norm("\n".join(new)) != norm(ln):
            print("  SKIP (not faithful) %s: %s" % (path, ln.strip())); out.append(ln); continue
        out += new; changed += 1
    if changed and apply:
        io.open(path, "w", encoding="utf-8").write("\n".join(out))
    return changed

apply = "--apply" in sys.argv
total_f = total_l = 0
for dirpath, _, names in os.walk(sys.argv[1]):
    for n in sorted(names):
        if not n.endswith(".qml"): continue
        if n in SKIP_GENERATED: print("  skipped (generated): %s" % n); continue
        p = os.path.join(dirpath, n)
        c = process(p, apply)
        if c: total_f += 1; total_l += c
print("%s: %d lines in %d files" % ("applied" if apply else "would change", total_l, total_f))
