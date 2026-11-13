"""装饰 iso 风批量重生成:8 件,以贴纸图为锚点走 Qwen 编辑管线。
用法: python deco_iso_batch.py   (输出 ai_samples/deco_iso/{id}_{A|B}.png)
"""
import pathlib
import subprocess
import sys

TOOLS = pathlib.Path(__file__).parent
ANCHORS = TOOLS.parent / 'ai_samples' / 'deco_anchors'
OUT = TOOLS.parent / 'ai_samples' / 'deco_iso'
API = 'http://127.0.0.1:8188'

DECO_DESC = {
    'bench': 'a small wooden garden bench',
    'fence': 'a short wooden picket fence segment',
    'gnome': 'a tiny cute garden gnome with a pointed hat',
    'hanging_pot': 'a small hanging flower pot on a rope',
    'lantern': 'a small round garden lantern',
    'path': 'a single round stepping stone tile',
    'pavilion': 'a tiny cute garden pavilion',
    'wheelbarrow': 'a small wheelbarrow',
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    anchors = sorted(ANCHORS.glob('deco_*_1024.png'))
    print(f'{len(anchors)} anchors', flush=True)
    for anchor in anchors:
        deco_id = anchor.name.replace('deco_', '').replace('_1024.png', '')
        if list(OUT.glob(f'{deco_id}_*.png')):
            print('skip (exists):', deco_id)
            continue
        prompt = (
            f'Transform this {DECO_DESC[deco_id]} illustration into soft low-poly '
            '3D style matching a cozy isometric garden diorama: matte clay-like '
            'materials, soft studio lighting, gentle ambient occlusion and contact '
            'shadow. Keep the exact same object shape, colors and proportions. '
            'Plain solid white background. No text.'
        )
        prompt_file = TOOLS / '_deco_prompt.txt'
        prompt_file.write_text(prompt, encoding='utf-8')
        print('gen:', deco_id, flush=True)
        subprocess.run(
            [sys.executable, str(TOOLS / 'qwen_edit_gen.py'),
             '--image', str(anchor),
             '--prompt-file', str(prompt_file),
             '--tag', f'decoiso_{deco_id}', '--batch', '2',
             '--api', API],
            check=False, capture_output=True,
        )
    print('all done')


if __name__ == '__main__':
    main()
