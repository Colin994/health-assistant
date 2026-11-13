"""通用批量文生图工具:按资产组批量出候选 + 生成选图拼图
用法: python flux_batch_gen.py --group all|scenes|decor|album
依赖: pip install requests pillow
"""
import argparse
import json
import pathlib
import time

import requests
from PIL import Image, ImageDraw, ImageFont

API_DEFAULT = "http://127.0.0.1:8188"
CKPT = "flux1-schnell-fp8.safetensors"
BASE = pathlib.Path(__file__).parent.parent  # design/game_art

STICKER = ("Die-cut sticker style with a soft white outline around the whole object, floating "
           "on a plain pure white background, no ground shadow. Flat vector illustration, "
           "minimal rounded shapes, matte solid colors, no gradients, no texture. Single "
           "centered object, generous empty space, calm friendly minimal health-app aesthetic.")

SCENE_BASE = ("Flat vector illustration, minimal rounded shapes, matte solid colors, no "
              "gradients, no texture, smooth clean edges. A cozy small garden background "
              "for a mobile app: a soft green grass lawn along the bottom, rounded "
              "rectangular planting beds in very light gray, a simple low white picket "
              "fence, small round bushes along the fence, a round tree canopy in the top "
              "corners, soft muted palette of pale mint green, deep teal green, dark "
              "charcoal green, pale cream yellow, muted terracotta. Calm friendly minimal "
              "health-app aesthetic. Generous empty space in the middle for UI, no potted "
              "plants, no characters, no text. Vertical composition.")

SCENES_V2_PROMPTS = {
    "morning": SCENE_BASE + " Early morning mood: soft pale mint tint over the sky area, low "
               "gentle light, fresh and calm.",
    "noon": SCENE_BASE + " Bright daylight mood: clean pale sky, crisp and lively.",
    "dusk": SCENE_BASE + " Dusk mood: a gentle warm pale lemon tint over the sky area, calm "
            "end-of-day feeling.",
    "night": SCENE_BASE + " Night mood: the sky area is dark charcoal green with tiny glowing "
             "pale yellow stars, foliage in deep muted greens, sleepy and quiet.",
}

JOBS = {
    "scenes": {  # 9:16 旧占位版(已被 scenesv2 取代,保留供对比)
        **{k: (v, 832, 1216) for k, v in SCENES_V2_PROMPTS.items()},
    },
    "decor": {  # 1024²,贴纸风,与植物同语言
        "fence": ("A short wooden picket fence segment with three rounded posts " + STICKER, 1024, 1024),
        "gnome": ("A tiny cute garden gnome with a muted terracotta pointed hat, mint green "
                  "body " + STICKER, 1024, 1024),
        "path": ("A single round stepping stone tile in soft warm gray with small mint green "
                 "moss dots " + STICKER, 1024, 1024),
        "hanging_pot": ("A small hanging flower pot in muted terracotta on a rope with two "
                        "tiny mint green leaves " + STICKER, 1024, 1024),
        "pavilion": ("A tiny cute garden pavilion with a warm terracotta roof and pale mint "
                     "green posts " + STICKER, 1024, 1024),
        "lantern": ("A small round garden lantern glowing soft warm yellow with a deep teal "
                    "green frame " + STICKER, 1024, 1024),
        "bench": ("A tiny wooden garden bench in muted terracotta brown " + STICKER, 1024, 1024),
        "wheelbarrow": ("A tiny cute wheelbarrow in muted terracotta with a mint green "
                        "handle " + STICKER, 1024, 1024),
    },
    "props": {  # 接阳光道具:篮子 + 阳光精灵(游戏内 2D 资产)
        "basket": (
            "A cute round woven wicker basket, warm terracotta brown weave with a "
            "pale mint green rim band, wide open top, empty, front view, hand-painted "
            "cartoon mobile game asset. " + STICKER, 1024, 1024),
        "sun_sprite": (
            "A cute round cartoon sun sprite with 8 short rounded triangular rays, "
            "pale lemon yellow body with a slightly deeper warm yellow center, simple "
            "friendly mobile game pick-up item, no face, front view. " + STICKER, 1024, 1024),
        "golden_sun": (
            "A cute round cartoon golden sun sprite with long pointed rays all around, "
            "rich golden yellow body with bright cream highlight center, sparkle accents, "
            "premium rare mobile game pick-up item, no face, front view. " + STICKER, 1024, 1024),
    },
    "scenesv2": {  # 场景 v2:完整插画花园(同构图四时段)
        **{k: (v[0], 832, 1216) for k, v in SCENES_V2_PROMPTS.items()},
    },
    "album": {  # 押花册底板模板
        "card": ("A pressed dried flower specimen card: one pale muted pressed flower laid "
                 "flat and centered on a soft cream rounded card, flat vector illustration, "
                 "matte solid colors, slightly desaturated palette of pale mint green, soft "
                 "warm yellow and muted terracotta, symmetric minimal composition, no text, "
                 "plain white background.", 1024, 1024),
    },
}


def queue(api, prompt, w, h, batch, seed, prefix):
    wf = {"prompt": {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["1", 1]}},
        "4": {"class_type": "FluxGuidance", "inputs": {"conditioning": ["2", 0], "guidance": 3.5}},
        "5": {"class_type": "EmptySD3LatentImage", "inputs": {"width": w, "height": h, "batch_size": batch}},
        "6": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["4", 0], "negative": ["3", 0],
                                                   "latent_image": ["5", 0], "seed": seed, "steps": 4, "cfg": 1.0,
                                                   "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["1", 2]}},
        "8": {"class_type": "SaveImage", "inputs": {"images": ["7", 0], "filename_prefix": prefix}},
    }}
    r = requests.post(f"{api}/prompt", json=wf, timeout=60).json()
    pid = r.get("prompt_id")
    if not pid:
        raise SystemExit(f"queue failed: {json.dumps(r)[:300]}")
    return pid


def wait_and_fetch(api, pid, out_dir):
    for _ in range(240):
        time.sleep(5)
        entry = requests.get(f"{api}/history/{pid}", timeout=30).json().get(pid, {})
        if entry.get("outputs"):
            break
    else:
        raise SystemExit("timeout")
    files = []
    for img in entry["outputs"]["8"]["images"]:
        r = requests.get(f"{api}/view", params={"filename": img["filename"],
                                                "subfolder": img.get("subfolder", ""),
                                                "type": img.get("type", "output")}, timeout=120)
        p = out_dir / img["filename"]
        p.write_bytes(r.content)
        files.append(p)
    return files


def contact_sheet(group, results, cell=360):
    """results: {name: [files]} -> 每行一个条目,列=候选 A-D"""
    font = ImageFont.truetype("arialbd.ttf", 36)
    names = list(results)
    canvas = Image.new("RGB", (4 * cell + 260, len(names) * cell + 20), "white")
    draw = ImageDraw.Draw(canvas)
    for r, name in enumerate(names):
        draw.text((10, r * cell + cell // 2 - 20), name[:10], fill="black", font=font)
        for c, f in enumerate(results[name][:4]):
            img = Image.open(f).convert("RGB")
            img.thumbnail((cell, cell))
            x = 260 + c * cell
            canvas.paste(img, (x + (cell - img.width) // 2, r * cell + (cell - img.height) // 2))
            draw.text((x + 8, r * cell + 8), "ABCD"[c], fill="black", font=font)
    out = BASE / "ai_samples" / f"pick_{group}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    print("sheet:", out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--group", default="all", choices=list(JOBS) + ["all"])
    ap.add_argument("--batch", type=int, default=4)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--api", default=API_DEFAULT)
    args = ap.parse_args()

    groups = list(JOBS) if args.group == "all" else [args.group]
    for g in groups:
        out_dir = BASE / "ai_samples" / g
        out_dir.mkdir(parents=True, exist_ok=True)
        results = {}
        for name, (prompt, w, h) in JOBS[g].items():
            pid = queue(args.api, prompt, w, h, args.batch, args.seed, f"slowplant/{g}_{name}")
            print(f"queued {g}/{name} -> {pid}")
            results[name] = wait_and_fetch(args.api, pid, out_dir)
            print(f"  done {len(results[name])} files")
        contact_sheet(g, results)


if __name__ == "__main__":
    main()
