"""指令编辑出图工具:Qwen-Image-Edit-2511(GGUF + Lightning 8步)走 ComfyUI API
用法:
  python qwen_edit_gen.py --image app/assets/game/scene_noon.png --preset night
  python qwen_edit_gen.py --image <锚点图> --prompt-file p.txt --tag dusk_v2 --batch 2
依赖: pip install requests pillow
"""
import argparse
import json
import pathlib
import time

import requests
from PIL import Image, ImageDraw, ImageFont

API_DEFAULT = "http://127.0.0.1:8188"
UNET = "qwen_image_edit_2511_Q4_K_M.gguf"
CLIP = "qwen_2.5_vl_7b_fp8_scaled.safetensors"
VAE = "qwen_image_vae.safetensors"
LORA = "Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors"
BASE = pathlib.Path(__file__).parent.parent  # design/game_art

# 编辑提示语通用骨架:只改时段与光线,锁构图与风格
LOCK = ("Keep the exact same composition, camera angle, layout and every object in place. "
        "Flat vector illustration, matte solid colors, no gradients, no texture, smooth clean "
        "edges. Calm friendly minimal health-app aesthetic. No text.")

# 时段预设(颜色名沿用生产指南色板:亮薄荷绿/深茶绿/炭绿/柠檬黄/陶土)
PRESETS = {
    "night": "Change the time of day to night. The sky area becomes dark charcoal green with "
             "tiny glowing pale yellow stars. All grass, bushes and tree canopy turn into deep "
             "muted dark greens. Add a soft warm yellow glow from the garden lantern. Sleepy "
             "and quiet mood. " + LOCK,
    "dusk": "Change the time of day to dusk. The sky area gets a gentle warm pale lemon tint, "
            "light is soft and low. Foliage slightly darker and warmer than daylight. Calm "
            "end-of-day feeling. " + LOCK,
    "morning": "Change the time of day to early morning. A soft pale mint tint covers the sky "
               "area, light is fresh and gentle. Slightly dewy, fresh and calm mood. " + LOCK,
}


def upload(api, path):
    r = requests.post(f"{api}/upload/image",
                      files={"image": (path.name, path.read_bytes())},
                      data={"overwrite": "true"}, timeout=120).json()
    name, sub = r["name"], r.get("subfolder", "")
    return f"{sub}/{name}" if sub else name


def queue(api, prompt, image_ref, seed, prefix):
    wf = {"prompt": {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": UNET}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": CLIP, "type": "qwen_image"}},
        "3": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0], "lora_name": LORA,
                                                             "strength_model": 1.0}},
        "4": {"class_type": "VAELoader", "inputs": {"vae_name": VAE}},
        "5": {"class_type": "LoadImage", "inputs": {"image": image_ref}},
        "6": {"class_type": "TextEncodeQwenImageEditPlus",
              "inputs": {"clip": ["2", 0], "prompt": prompt, "vae": ["4", 0], "image1": ["5", 0]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["2", 0]}},
        "8": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["3", 0], "shift": 3.1}},
        "12": {"class_type": "VAEEncode", "inputs": {"pixels": ["5", 0], "vae": ["4", 0]}},
        "9": {"class_type": "KSampler", "inputs": {"model": ["8", 0], "positive": ["6", 0],
                                                   "negative": ["7", 0], "latent_image": ["12", 0],
                                                   "seed": seed, "steps": 8, "cfg": 1.0,
                                                   "sampler_name": "euler", "scheduler": "simple",
                                                   "denoise": 1.0}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["4", 0]}},
        "11": {"class_type": "SaveImage", "inputs": {"images": ["10", 0], "filename_prefix": prefix}},
    }}
    r = requests.post(f"{api}/prompt", json=wf, timeout=60).json()
    pid = r.get("prompt_id")
    if not pid:
        raise SystemExit(f"queue failed: {json.dumps(r)[:400]}")
    return pid


def wait_and_fetch(api, pid, out_dir):
    for _ in range(120):
        time.sleep(5)
        entry = requests.get(f"{api}/history/{pid}", timeout=30).json().get(pid, {})
        if entry.get("outputs"):
            break
    else:
        raise SystemExit("timeout")
    files = []
    for img in entry["outputs"]["11"]["images"]:
        r = requests.get(f"{api}/view", params={"filename": img["filename"],
                                                "subfolder": img.get("subfolder", ""),
                                                "type": img.get("type", "output")}, timeout=120)
        p = out_dir / img["filename"]
        p.write_bytes(r.content)
        files.append(p)
    return files


def contact_sheet(tag, results, cell=360):
    """results: {name: [files]} -> 行=预设/标签,列=候选 A-D"""
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
    out = BASE / "ai_samples" / f"pick_edit_{tag}.png"
    canvas.save(out)
    print("sheet:", out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, help="锚点图路径")
    ap.add_argument("--preset", choices=sorted(PRESETS))
    ap.add_argument("--prompt-file")
    ap.add_argument("--prompt")
    ap.add_argument("--tag", default="edit", help="输出目录/拼图标签")
    ap.add_argument("--batch", type=int, default=2, help="候选数(逐 seed 串行)")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--api", default=API_DEFAULT)
    args = ap.parse_args()

    if sum(bool(x) for x in (args.preset, args.prompt_file, args.prompt)) != 1:
        raise SystemExit("三选一: --preset / --prompt-file / --prompt")
    prompt = args.prompt or PRESETS.get(args.preset) or \
        pathlib.Path(args.prompt_file).read_text(encoding="utf-8")
    img_path = pathlib.Path(args.image)
    out_dir = BASE / "ai_samples" / f"edit_{args.tag}"
    out_dir.mkdir(parents=True, exist_ok=True)

    ref = upload(args.api, img_path)
    print(f"uploaded: {ref}")
    results = {"_": []}
    for i in range(args.batch):
        seed = args.seed + i
        pid = queue(args.api, prompt, ref, seed, f"slowplant/edit_{args.tag}")
        print(f"queued [{i}] seed={seed} -> {pid}")
        files = wait_and_fetch(args.api, pid, out_dir)
        results["_"] += files
        print(f"  done {len(files)}")
    contact_sheet(args.tag, results)


if __name__ == "__main__":
    main()
