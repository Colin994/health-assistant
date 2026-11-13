"""装饰 iso 产物收集:候选 A → 白底去底 → 母版 decor_iso/ + app 资产 deco_iso_*.png + 总览拼图。
用法: python collect_deco_iso.py [--candidate B]
"""
import argparse
import pathlib
import subprocess
import sys

from PIL import Image, ImageDraw

TOOLS = pathlib.Path(__file__).parent
AI = TOOLS.parent / 'ai_samples'
MASTER = TOOLS.parent / 'decor_iso'
APP_ASSETS = TOOLS.parent.parent.parent / 'app' / 'assets' / 'game'
DECOS = ['bench', 'fence', 'gnome', 'hanging_pot', 'lantern', 'path',
         'pavilion', 'wheelbarrow']


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', default='A', choices=['A', 'B'])
    args = parser.parse_args()

    MASTER.mkdir(parents=True, exist_ok=True)
    cut_tmp = AI / 'deco_iso_cut'
    cut_tmp.mkdir(exist_ok=True)

    cells = []
    for deco in DECOS:
        src_dir = AI / f'edit_decoiso_{deco}'
        candidates = sorted(src_dir.glob(f'edit_decoiso_{deco}_*.png'))
        if not candidates:
            print(f'缺失: {deco}', file=sys.stderr)
            continue
        src = candidates[-1]  # 最新计数=最新 prompt 产物
        cut = cut_tmp / f'{deco}.png'
        subprocess.run(
            [sys.executable, str(TOOLS / 'white_cutout.py'),
             str(src), str(cut)],
            check=True, capture_output=True,
        )
        img = Image.open(cut)
        img.save(MASTER / f'{deco}.png')
        img.thumbnail((512, 512))
        img.save(APP_ASSETS / f'deco_iso_{deco}.png')
        cells.append((deco, img))
        print('ok:', deco)

    cell = 220
    sheet = Image.new('RGB', (4 * cell, 2 * cell + 30), (230, 230, 230))
    draw = ImageDraw.Draw(sheet)
    for idx, (tag, img) in enumerate(cells):
        row, col = idx // 4, idx % 4
        img = Image.open(cut_tmp / f'{tag}.png')
        img.thumbnail((cell - 10, cell - 10))
        x = col * cell + (cell - img.width) // 2
        y = row * cell + (cell - img.height) // 2
        sheet.paste(img, (x, y), img)
        draw.text((col * cell + 6, row * cell + 4), tag, fill='black')
    sheet.save(AI / 'style3d' / 'deco_iso_review.png')
    print('总览:', AI / 'style3d' / 'deco_iso_review.png')


if __name__ == '__main__':
    main()
