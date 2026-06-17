#!/usr/bin/env node
// parse.js — 控件树查询: find / count / attr / region
// 依赖当前目录 layout.json（先 dump.sh）
const fs = require("fs");
const d = JSON.parse(fs.readFileSync("layout.json", "utf8"));
const args = process.argv.slice(2);
const cmd = args[0];

function walk(cb) {
  const st = [d];
  while (st.length) { const n = st.pop(); cb(n.attributes || {}); (n.children || []).forEach(c => st.push(c)); }
}
function parseBounds(b) {
  const m = String(b || "").match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
  return m ? { x1:+m[1], y1:+m[2], x2:+m[3], y2:+m[4] } : null;
}
function inRegion(b, r) {
  const p = parseBounds(b); if (!p) return false;
  return p.x1 >= r.x1 && p.y1 >= r.y1 && p.x2 <= r.x2 && p.y2 <= r.y2;
}
function regionArg() {
  const a = args.find(x => x.startsWith("--region="));
  if (!a) return null;
  const m = a.replace("--region=", "").split(",");
  return { x1:+m[0], y1:+m[1], x2:+m[2], y2:+m[3] };
}

if (cmd === "find") {
  const sub = args[1]; let out = "";
  walk(a => { if (!out && a.text && String(a.text).includes(sub)) out = a.bounds; });
  if (out) { console.log(out); process.exit(0); } else { console.error("find: not found"); process.exit(1); }
} else if (cmd === "count") {
  const type = args[1], r = regionArg(); let n = 0;
  walk(a => { if (a.type !== type) return; if (r && !inRegion(a.bounds, r)) return; n++; });
  console.log(n); process.exit(0);
} else if (cmd === "attr") {
  const sub = args[1], attr = args[2]; let v;
  walk(a => { if (v === undefined && a.text && String(a.text).includes(sub)) v = a[attr]; });
  if (v !== undefined && v !== "") { console.log(v); process.exit(0); } else { console.error("attr: not found"); process.exit(1); }
} else {
  console.error("usage: parse.js find <text> | count <type> [--region=x1,y1,x2,y2] | attr <text> <attr>");
  process.exit(2);
}
