"""植物 iso 产物收集:候选 A → 白底去底 → 母版(1024 RGBA)入库 + app 资产(512 RGBA) + 总览拼图。
用法: python collect_plant_iso.py [--candidate B]   (--candidate B 换选 B 候选)
"""
import argparse
import pathlib
import subprocess
import sys

from PIL import Image, ImageDraw

TOOLS = pathlib.Path(__file__).parent
AI = TOOLS.parent / 'ai_samples'
MASTER = TOOLS.parent / 'plants_iso'
APP_ASSETS = TOOLS.parent.parent.parent / 'app' / 'assets' / 'game'
SPECIES = ['cyperus', 'hydrocotyle', 'lavender', 'rose', 'sunflower']
STAGES = range(6)



def _deglass(img: Image.Image) -> None:
    """清除与透明区连通的浅色不透明像素(白底残留)。"""
    from collections import deque
    w, h = img.size
    px = img.load()

    def is_light(x: int, y: int) -> bool:
        r, g, b, a = px[x, y]
        return a > 0 and min(r, g, b) >= 200 and (max(r, g, b) - min(r, g, b)) <= 46

    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if not seen[y][x] and (px[x, y][3] == 0 or is_light(x, y)):
                seen[y][x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not seen[y][x] and (px[x, y][3] == 0 or is_light(x, y)):
                seen[y][x] = True
                q.append((x, y))
    while q:
        x, y = q.popleft()
        r, g, b, a = px[x, y]
        if a > 0:
            px[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                if px[nx, ny][3] == 0 or is_light(nx, ny):
                    seen[ny][nx] = True
                    q.append((nx, ny))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', default='A', choices=['A', 'B'])
    args = parser.parse_args()
    suffix = '_00001_.png' if args.candidate == 'A' else '_00002_.png'

    MASTER.mkdir(parents=True, exist_ok=True)
    cut_tmp = AI / 'plant_iso_cut'
    cut_tmp.mkdir(exist_ok=True)

    cells = []
    for species in SPECIES:
        for stage in STAGES:
            tag = f'{species}_stage{stage}'
            src_dir = AI / f'edit_plantiso_{tag}'
            # 取最大计数=最新生成(续跑批次的修正 prompt 产物落在更高编号)。
            candidates = sorted(src_dir.glob(f'edit_plantiso_{tag}_*.png'))
            src = candidates[-1] if candidates else src_dir / f'edit_plantiso_{tag}{suffix}'
            if not src.exists():
                print(f'缺失: {tag} ({src.name})', file=sys.stderr)
                continue
            cut = cut_tmp / f'{tag}.png'
            subprocess.run(
                [sys.executable, str(TOOLS / 'white_cutout.py'),
                 str(src), str(cut)],
                check=True, capture_output=True,
            )
            img = Image.open(cut)

            # 二次精修:清除与透明区连通的残留浅色底(白椭圆/白边)。
            _deglass(img)
            img.save(MASTER / f'{tag}.png')
            fit = img.copy()
            fit.thumbnail((512, 512), Image.LANCZOS)
            fit.save(APP_ASSETS / f'plant_iso_{tag}.png')
            cells.append((tag, Image.open(cut)))
            print('ok:', tag)

    # 总览拼图:5 行×6 列,灰底衬透明。
    cell = 210
    sheet = Image.new('RGB', (6 * cell, 5 * cell + 30), (230, 230, 230))
    draw = ImageDraw.Draw(sheet)
    for idx, (tag, img) in enumerate(cells):
        row, col = idx // 6, idx % 6
        img = Image.open(cut_tmp / f'{tag}.png')
        img.thumbnail((cell - 10, cell - 10))
        x = col * cell + (cell - img.width) // 2
        y = row * cell + (cell - img.height) // 2
        sheet.paste(img, (x, y), img)
        draw.text((col * cell + 6, row * cell + 4), tag, fill='black')
    sheet.save(AI / 'style3d' / 'plants_iso_review.png')
    print('总览:', AI / 'style3d' / 'plants_iso_review.png')


if __name__ == '__main__':
    main()
