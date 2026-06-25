#!/usr/bin/env node
// tap.js — 按 text/id/xy 定位点击（读 layout.json）
// 消歧：--exact 精确匹配(避免子串误命中, 如"设置"被帖子标题《..设置..》命中)；
//       多个同名用 --nth N 或 --region=x1,y1,x2,y2 指定；否则报 AMBIGUOUS 并 exit 2
const { execSync } = require("child_process");
const fs = require("fs");
process.env.MSYS_NO_PATHCONV = "1";
const d = JSON.parse(fs.readFileSync("layout.json", "utf8"));
const args = process.argv.slice(2);

function walk(cb){ const st=[d]; while(st.length){ const n=st.pop(); cb(n.attributes||{}); (n.children||[]).forEach(c=>st.push(c)); } }
function parseBounds(b){ const m=String(b||"").match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/); return m?{x:(+m[1]+ +m[3])/2,y:(+m[2]+ +m[4])/2}:null; }
function ctr(b){ const c=parseBounds(b); return c?`${Math.round(c.x)},${Math.round(c.y)}`:"?"; }
function click(x,y){ execSync(`hdc shell uitest uiInput click ${Math.round(x)} ${Math.round(y)}`, {stdio:"inherit"}); }

// 解析可选参数 --exact / --nth / --region
const exact = args.includes("--exact");
const nthIdx = args.indexOf("--nth");
const nth = nthIdx !== -1 ? +args[nthIdx+1] : null;
const regionArg = args.find(x => x.startsWith("--region="));
let region = null;
if (regionArg) { const m = regionArg.replace("--region=","").split(","); region = {x1:+m[0],y1:+m[1],x2:+m[2],y2:+m[3]}; }
const inRegion = b => { if(!region) return true; const c=parseBounds(b); return c && c.x>=region.x1 && c.x<=region.x2 && c.y>=region.y1 && c.y<=region.y2; };

// --xy：直接坐标点击
if (args[0] === "--xy") { click(+args[1], +args[2]); process.exit(0); }

// text / id 定位：收集所有匹配（exact 精确 / includes 子串 + region 过滤）
const mode = args[0] === "--id" ? "id" : "text";
const key = mode === "id" ? args[1] : args[0];
const matches = [];
walk(a => {
  const hit = mode === "id"
    ? (a.id === key)
    : (a.text && (exact ? String(a.text) === key : String(a.text).includes(key)));
  if (hit && inRegion(a.bounds)) matches.push(a);
});
if (matches.length === 0) { console.error(`tap: target not found '${key}'`+(exact?" (exact)":"")+(region?" in region":"")); process.exit(1); }

// 多匹配：未消歧 → AMBIGUOUS exit 2；--nth 越界 → exit 1
if (matches.length > 1 && nth === null) {
  console.error(`AMBIGUOUS: ${matches.length} matches for '${key}'`+(exact?" (exact)":""));
  matches.forEach((a,i) => console.error(`  [${i+1}] ${a.type||"?"}  (${ctr(a.bounds)})  bounds=${a.bounds}`));
  console.error("  → 用 --nth N / --region=x1,y1,x2,y2 消歧");
  process.exit(2);
}
if (nth !== null && (nth < 1 || nth > matches.length)) { console.error(`tap: --nth ${nth} 超出范围(共 ${matches.length} 匹配)`); process.exit(1); }
const target = nth !== null ? matches[nth-1] : matches[0];
const c = parseBounds(target.bounds);
if (!c) { console.error("tap: no bounds"); process.exit(1); }
click(c.x, c.y);
process.exit(0);
