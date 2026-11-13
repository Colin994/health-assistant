"""白底去底工具:边缘 flood-fill 抠除近白背景,输出带 alpha 的 PNG。
适用:低多边形渲染图(纯白背景、主体边缘清晰)。
用法: python white_cutout.py <输入.png> <输出.png> [阈值=238]
"""
import sys
from collections import deque

from PIL import Image


def cutout(src_path: str, dst_path: str, threshold: int = 238) -> None:
    img = Image.open(src_path).convert('RGB')
    w, h = img.size
    px = img.load()

    def is_background(x: int, y: int) -> bool:
        r, g, b = px[x, y]
        return r >= threshold and g >= threshold and b >= threshold

    seen = [[False] * w for _ in range(h)]
    queue = deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_background(x, y) and not seen[y][x]:
                seen[y][x] = True
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if is_background(x, y) and not seen[y][x]:
                seen[y][x] = True
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                if is_background(nx, ny):
                    seen[ny][nx] = True
                    queue.append((nx, ny))

    out = Image.open(src_path).convert('RGBA')
    out_px = out.load()
    removed = 0
    for y in range(h):
        for x in range(w):
            if seen[y][x]:
                out_px[x, y] = (255, 255, 255, 0)
                removed += 1
    out.save(dst_path)
    total = w * h
    print(f'{dst_path}: 去除 {removed}/{total} ({removed * 100 // total}%)')


if __name__ == '__main__':
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    thr = int(sys.argv[3]) if len(sys.argv) > 3 else 238
    cutout(sys.argv[1], sys.argv[2], thr)
