#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Report pairwise bbox overlaps of top-level children in each screen frame."""
import importlib.util, json
spec = importlib.util.spec_from_file_location('b', 'build_pixso_design.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

script = r"""
const p = pixso.getNodeById('%s');
const report = {};
for (const fr of p.children) {
  const items = [];
  for (const n of fr.children) {
    items.push({name: n.name, x: Math.round(n.x), y: Math.round(n.y),
                w: Math.round(n.width), h: Math.round(n.height)});
  }
  const ov = [];
  for (let i = 0; i < items.length; i++) for (let j = i + 1; j < items.length; j++) {
    const a = items[i], b = items[j];
    const ix = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);
    const iy = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
    if (ix > 2 && iy > 2) ov.push(a.name + ' ∩ ' + b.name + ' (' + ix + 'x' + iy + ')');
  }
  // out-of-frame check
  const oob = [];
  for (const it of items) {
    if (it.x < 0 || it.y < 0 || it.x + it.w > 390 || it.y + it.h > 844)
      oob.push(it.name + ' [' + it.x + ',' + it.y + ' ' + it.w + 'x' + it.h + ']');
  }
  report[fr.name] = {overlaps: ov, outOfFrame: oob};
}
return report;
""" % m.PAGE_ID

out = m.call_tool("eval_script", {"script": script})
rep = json.loads(out)
for name, r in rep.items():
    print("=" * 8, name)
    if r["outOfFrame"]:
        print("  越界:", "; ".join(r["outOfFrame"]))
    if r["overlaps"]:
        for o in r["overlaps"]:
            print("  重叠:", o)
    if not r["overlaps"] and not r["outOfFrame"]:
        print("  ✓ 无问题")
