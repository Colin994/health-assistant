#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Aggregate design tokens from Pixso node DSL (pixso_last_result.json)."""
import json, collections

raw = json.load(open('pixso_last_result.json', encoding='utf-8'))
roots = raw.get('roots') or raw['result']['content'] and json.loads(
    next(c['text'] for c in raw['result']['content'] if c.get('type') == 'text'))['roots']

colors = collections.Counter()
texts = []      # (font, size, weight, lineHeight, color, sample)
radii = collections.Counter()
effects = collections.Counter()
spacing = collections.Counter()

def paint_value(p):
    if isinstance(p, str):
        return p
    if isinstance(p, dict):
        return p.get('value') or p.get('color')
    return None

def walk(n, depth=0):
    for f in n.get('fills', []) or []:
        v = paint_value(f)
        if isinstance(v, str) and v.startswith('rgba'):
            colors[v] += 1
    for s in n.get('strokes', []) or []:
        v = paint_value(s)
        if isinstance(v, str) and v.startswith('rgba'):
            colors['(stroke) ' + v] += 1
    r = n.get('radius')
    if isinstance(r, (int, float)) and r > 0:
        radii[r] += 1
    for e in n.get('effects', []) or []:
        effects[json.dumps(e, ensure_ascii=False)[:160]] += 1
    t = n.get('text')
    if t:
        c = ''
        for f in n.get('fills', []) or []:
            v = paint_value(f)
            if isinstance(v, str):
                c = v; break
        texts.append((t.get('fontFamily'), t.get('fontSize'), t.get('fontWeight'),
                      t.get('lineHeight'), c, (t.get('content') or '')[:18]))
    al = n.get('autoLayout') or {}
    g = al.get('gap')
    if isinstance(g, (int, float)) and g > 0:
        spacing[g] += 1
    for ch in n.get('children', []) or []:
        walk(ch, depth + 1)

for root in roots:
    walk(root)

def rgba_hex(v):
    v = v.replace('(stroke) ', '')
    import re
    m = re.match(r'rgba\((\d+),(\d+),(\d+),([\d.]+)\)', v)
    if not m: return v
    r, g, b, a = int(m.group(1)), int(m.group(2)), int(m.group(3)), float(m.group(4))
    h = '#%02X%02X%02X' % (r, g, b)
    return h + (' (%d%%)' % round(a * 100) if a < 1 else '')

print('=== COLOR PALETTE (by usage) ===')
for v, c in colors.most_common(30):
    print('%-28s x%d   %s' % (rgba_hex(v), c, v))

print()
print('=== TYPOGRAPHY (font / size / weight / lineH / color / sample) ===')
seen = set()
for t in sorted(texts, key=lambda x: -(x[1] or 0)):
    key = t[:5]
    if key in seen: continue
    seen.add(key)
    print('%-16s %5s  w%-4s lh%-5s %-22s %s' % (
        t[0], t[1], t[2], t[3], rgba_hex(t[4]) if t[4].startswith(('rgba', '(s')) else t[4], t[5]))

print()
print('=== RADII ===')
for r, c in radii.most_common(15):
    print('r=%-6s x%d' % (r, c))

print()
print('=== LAYOUT GAPS ===')
for g, c in spacing.most_common(15):
    print('gap=%-5s x%d' % (g, c))

print()
print('=== EFFECTS ===')
for e, c in effects.most_common(10):
    print('%s  x%d' % (e, c))
