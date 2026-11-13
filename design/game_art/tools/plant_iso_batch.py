"""植物 iso 风批量重生成:5 物种×6 阶段,以贴纸图为锚点走 Qwen 编辑管线。
用法: python plant_iso_batch.py   (输出 ai_samples/plant_iso/{species}_stage{n}_{A|B}.png)
"""
import pathlib
import subprocess
import sys

TOOLS = pathlib.Path(__file__).parent
ANCHORS = TOOLS.parent / 'ai_samples' / 'plant_anchors'
OUT = TOOLS.parent / 'ai_samples' / 'plant_iso'
API = 'http://127.0.0.1:8188'

STAGE_DESC = {
    0: 'a tiny sprout with two small seed leaves just emerging from the soil',
    1: 'a young seedling with a few small true leaves',
    2: 'a growing leafy plant with abundant foliage and no flowers',
    3: 'a plant with tightly closed green buds, no petals open yet',
    4: 'a plant in full bloom with vivid open flowers',
    5: 'a lush harvest-ready plant with dense foliage and fully open flowers, slightly drooping abundant leaves',
}
NO_FLOWER_SPECIES = {'cyperus', 'hydrocotyle'}

SPECIES_DESC = {
    'sunflower': 'sunflower',
    'hydrocotyle': 'hydrocotyle (coin-leaf water plant with round shield-shaped leaves)',
    'cyperus': 'cyperus papyrus (umbrella plant with whorled grass-like leaves)',
    'lavender': 'lavender with narrow grey-green leaves and purple flower spikes',
    'rose': 'rose bush with compound leaves and layered roses',
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    anchors = sorted(ANCHORS.glob('plant_*_stage*_1024.png'))
    print(f'{len(anchors)} anchors')
    for anchor in anchors:
        stem = anchor.name.replace('_1024.png', '')
        species = stem.replace('plant_', '').rsplit('_stage', 1)[0]
        stage = int(stem.rsplit('_stage', 1)[1])
        stage_desc = STAGE_DESC[stage]
        if species in NO_FLOWER_SPECIES and stage >= 3:
            stage_desc = ('a lush mature foliage plant with dense leaves only, '
                          'absolutely no flowers, no buds')
        prompt = (
            f'Transform this potted {SPECIES_DESC[species]} illustration into a soft '
            f'low-poly 3D style plant at the {stage_desc}. The plant grows '
            'directly in a small neat mound of dark rich soil at the base, no flower '
            'pot, no exposed roots. Matte clay-like materials, soft studio lighting, '
            'gentle ambient occlusion, matching a cozy isometric garden diorama. '
            'Keep the exact same plant species, leaf shapes, colors and growth '
            'stage. Plain solid white background. No text.'
        )
        prompt_file = TOOLS / '_plant_prompt.txt'
        prompt_file.write_text(prompt, encoding='utf-8')
        out_name = f'{species}_stage{stage}'
        if list(OUT.glob(f'{out_name}_*.png')):
            print('skip (exists):', out_name)
            continue
        print('gen:', out_name, flush=True)
        subprocess.run(
            [sys.executable, str(TOOLS / 'qwen_edit_gen.py'),
             '--image', str(anchor),
             '--prompt-file', str(prompt_file),
             '--tag', f'plantiso_{out_name}', '--batch', '2',
             '--api', API],
            check=False, capture_output=True,
        )
    print('all done')


if __name__ == '__main__':
    main()
