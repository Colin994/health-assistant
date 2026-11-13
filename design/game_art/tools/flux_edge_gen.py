"""链式 img2img 单边生成工具 —— 多状态植物管线的执行单元(模式 A)

用法:
  python flux_edge_gen.py --anchor ../plants/plant_hydrocotyle_stage1.png \
      --prompt-file prompt.txt --denoise 0.55 --batch 8 --seed 42 \
      --prefix slowplant/edge_hy0 --out ../ai_samples/edges/hy0

依赖: pip install requests pillow
文档: docs/游戏美术资产生产指南.md §3.8
"""
import argparse
import json
import pathlib
import time

import requests

API_DEFAULT = "http://127.0.0.1:8188"
CKPT = "flux1-schnell-fp8.safetensors"

# 逐边 denoise 参考表(成长变化量越大,重绘幅度越高)
EDGE_DENOISE = {
    "0->1": 0.50, "1->2": 0.60, "2->3": 0.55, "3->4": 0.65, "4->5": 0.45,
    "reverse_younger": 0.55,  # 从后一阶段反向生成更早阶段
}


def build_workflow(image_name: str, prompt: str, denoise: float,
                   batch: int, seed: int, steps: int, prefix: str) -> dict:
    return {"prompt": {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "LoadImage", "inputs": {"image": image_name}},
        "3": {"class_type": "VAEEncode", "inputs": {"pixels": ["2", 0], "vae": ["1", 2]}},
        "4": {"class_type": "RepeatLatentBatch", "inputs": {"samples": ["3", 0], "amount": batch}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["1", 1]}},
        "7": {"class_type": "FluxGuidance", "inputs": {"conditioning": ["5", 0], "guidance": 3.5}},
        "8": {"class_type": "KSampler", "inputs": {
            "model": ["1", 0], "positive": ["7", 0], "negative": ["6", 0],
            "latent_image": ["4", 0], "seed": seed, "steps": steps, "cfg": 1.0,
            "sampler_name": "euler", "scheduler": "simple", "denoise": denoise}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"images": ["9", 0], "filename_prefix": prefix}},
    }}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--anchor", required=True, help="上一阶段定稿图路径")
    ap.add_argument("--prompt", default=None)
    ap.add_argument("--prompt-file", default=None)
    ap.add_argument("--denoise", type=float, default=0.55)
    ap.add_argument("--batch", type=int, default=8)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--steps", type=int, default=8, help="img2img 建议 6~8,蒸馏模型 4 步过粗")
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--api", default=API_DEFAULT)
    args = ap.parse_args()

    prompt = args.prompt or pathlib.Path(args.prompt_file).read_text(encoding="utf-8").strip()

    up = requests.post(f"{args.api}/upload/image",
                       files={"image": open(args.anchor, "rb")},
                       data={"overwrite": "true"}, timeout=60).json()
    image_name = up["name"] if not up.get("subfolder") else f"{up['subfolder']}/{up['name']}"
    print("anchor uploaded:", image_name)

    wf = build_workflow(image_name, prompt, args.denoise, args.batch, args.seed, args.steps, args.prefix)
    pid = requests.post(f"{args.api}/prompt", json=wf, timeout=60).json()["prompt_id"]
    print("queued:", pid)

    for _ in range(120):
        time.sleep(5)
        hist = requests.get(f"{args.api}/history/{pid}", timeout=30).json()
        entry = hist.get(pid, {})
        if entry.get("outputs"):
            break
    else:
        raise SystemExit("timeout waiting for generation")

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    n = 0
    for img in entry["outputs"]["10"]["images"]:
        r = requests.get(f"{args.api}/view", params={
            "filename": img["filename"], "subfolder": img.get("subfolder", ""),
            "type": img.get("type", "output")}, timeout=120)
        (out_dir / img["filename"]).write_bytes(r.content)
        n += 1
    print(f"DONE {n} files -> {out_dir}")


if __name__ == "__main__":
    main()
