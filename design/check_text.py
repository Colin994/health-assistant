#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Per-screen audit: text wrap risk, rendered-height overflow, partial overlaps, OOB.

Fetches every node's box + (for texts) characters/fontSize/lineHeight via plugin API,
then estimates real rendered size (CJK char ~= 1em, latin/digit ~= 0.58em) and re-runs
collision detection with effective boxes. Containment (text inside its own shape) is
whitelisted; partial overlaps are reported.
"""
import importlib.util, json, math, unicodedata

spec = importlib.util.spec_from_file_location('b', 'build_pixso_design.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

FETCH = r"""
const p = pixso.getNodeById('%s');
const out = {};
for (const fr of p.children) {
  const nodes = [];
  const walk = (n) => {
    const item = {name: n.name, x: n.x, y: n.y, w: n.width, h: n.height};
    if (n.type === 'TEXT') {
      item.text = true;
      item.chars = n.characters;
      item.fs = n.fontSize;
      try { item.lh = (n.lineHeight && n.lineHeight.unit === 'PIXELS') ? n.lineHeight.value : null; } catch(e){ item.lh = null; }
    }
    nodes.push(item);
    for (const c of n.children || []) walk(c);
  };
  walk(fr);
  out[fr.name] = nodes;
}
return out;
""" % m.PAGE_ID

def char_w(ch, fs):
    if unicodedata.east_asian_width(ch) in ('F', 'W'):
        return fs
    if ch == ' ':
        return fs * 0.3
    return fs * 0.58

def est_line_w(line, fs):
    return sum(char_w(c, fs) for c in line)

def eff_size(item):
    """Return (w, h) of rendered text incl. wrapping."""
    w, h = item['w'], item['h']
    if not item.get('text'):
        return w, h
    fs = item['fs'] or 14
    lh = item['lh'] or round(fs * 1.4)
    lines = item['chars'].split('\n')
    total = 0
    for ln in lines:
        est = est_line_w(ln, fs)
        total += max(1, math.ceil(est / max(w, 1) - 0.02)) if est > w else 1
    return w, total * lh

def main():
    raw = m.call_tool("eval_script", {"script": FETCH})
    rep = json.loads(raw)
    problems = 0
    for screen, items in rep.items():
        items = [it for it in items if not it['name'].startswith(screen.split(' ')[0] + ' ')] or items
        issues = []
        # text wrap / overflow
        for it in items:
            if not it.get('text'):
                continue
            fs = it['fs'] or 14
            for ln in it['chars'].split('\n'):
                est = est_line_w(ln, fs)
                if est > it['w'] + 1:
                    issues.append("换行风险 %s: 「%s」估宽 %d > 框宽 %d" % (it['name'], ln[:16], est, it['w']))
            w2, h2 = eff_size(it)
            if h2 > it['h'] + 2:
                issues.append("高度溢出 %s: 渲染高 %d > 框高 %d (y=%d)" % (it['name'], h2, it['h'], it['y']))
        # partial overlap with effective boxes
        boxes = []
        for it in items:
            w2, h2 = eff_size(it)
            boxes.append((it['name'], it['x'], it['y'], it['x'] + w2, it['y'] + h2))
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                a, b = boxes[i], boxes[j]
                ix = min(a[3], b[3]) - max(a[1], b[1])
                iy = min(a[4], b[4]) - max(a[2], b[2])
                if ix > 2 and iy > 2:
                    a_in_b = a[1] >= b[1] - 2 and a[2] >= b[2] - 2 and a[3] <= b[3] + 2 and a[4] <= b[4] + 2
                    b_in_a = b[1] >= a[1] - 2 and b[2] >= a[2] - 2 and b[3] <= a[3] + 2 and b[4] <= a[4] + 2
                    if not (a_in_b or b_in_a):  # containment whitelisted
                        # 01 屏：通知浮卡有意压在脉冲圆环上；06 屏：ring 为插图低透明度背景
                        pair = {a[0], b[0]}
                        deco = lambda n: (len(n) == 2 and n[0] == 'r' and n[1].isdigit()) or n in ('nb', 'nbt', 'nbs', 'ring')
                        if (deco(a[0]) and deco(b[0])) or 'ring' in (a[0], b[0]):
                            continue
                        issues.append("部分重叠 %s ∩ %s (%dx%d)" % (a[0], b[0], ix, iy))
        # out of frame
        for it in items:
            w2, h2 = eff_size(it)
            if it['x'] < 0 or it['y'] < 0 or it['x'] + w2 > 390 or it['y'] + h2 > 844:
                issues.append("越界 %s [%d,%d %dx%d]" % (it['name'], it['x'], it['y'], w2, h2))
        print("=" * 8, screen)
        if issues:
            problems += len(issues)
            for s in issues:
                print("  ", s)
        else:
            print("   ✓ 无问题")
    print("\n总问题数:", problems)

if __name__ == "__main__":
    main()
