"""六阶段植物成长直链管线(模式 B):生成 ComfyUI 可视化工作流 + 直接执行

用法:
  python flux_chain_gen.py --species hydrocotyle --batch 4 --seed 42
产物:
  1) tools/chain_{species}.workflow.json —— ComfyUI 画布格式,复制到用户工作流目录
  2) ai_samples/chains/{species}/ —— 6 阶段 × batch 张图
依赖: pip install requests pillow
"""
import argparse
import pathlib
import time

import requests

API_DEFAULT = "http://127.0.0.1:8188"
CKPT = "flux1-schnell-fp8.safetensors"
GUIDANCE = 3.5

# 逐边重绘幅度(steps: stage0 为文生图锚点用 4 步,边一律 8 步)
# v2:原 0.45~0.65 在 schnell 上近似恒等输出,上调;4→5 变化小保持较低
DENOISE = [1.00, 0.70, 0.75, 0.72, 0.78, 0.60]
STEPS = [4, 8, 8, 8, 8, 8]

STYLE = ("Flat vector illustration, minimal rounded shapes, matte solid colors, no gradients, "
         "no texture. Die-cut sticker style with a soft white outline, floating on a plain pure "
         "white background, no ground shadow, no drop shadow.")
POT = ("A soft pale milky mint green flower pot with a warm terracotta orange rim at the top "
       "and a small terracotta orange base tray, rounded tapered body with a wide rim.")
# v2:阶段提示语"目标状态优先",求同压缩为短尾——原版全篇 "the same" 导致低重绘下近似恒等输出
SAME = ("Same pale milky mint green flower pot with warm terracotta orange rim and base tray, "
        "same die-cut sticker style with soft white outline, plain white background, flat "
        "vector, matte solid colors, no gradients, no ground shadow.")

SPECIES = {
    "hydrocotyle": [
        f"{POT} Planted in it, a tiny hydrocotyle seedling with exactly two small round "
        f"coin-shaped mint teal green leaves on short slender stems in dark soil, no flower, "
        f"very small plant. {STYLE}",
        "A young hydrocotyle plant with a few small round coin-shaped mint teal green leaves "
        "on short slender stems, slightly bigger than a seedling, no flowers. " + SAME,
        "A half-grown hydrocotyle plant: many round coin-shaped mint teal green leaves on "
        "slender stems, medium full size, no flowers. " + SAME,
        "A mature hydrocotyle plant: dense round coin-shaped mint teal green leaves filling the "
        "pot, full and lush but still contained inside, the pot rim clearly visible. " + SAME,
        "A hydrocotyle plant at peak overgrowth: extremely abundant round coin-shaped mint teal "
        "green leaves, much bigger than a mature plant, cascading over and half hiding the pot "
        "rim, a big overflowing mound of foliage. " + SAME,
        "A harvest-ready hydrocotyle plant: dense abundant coin leaves with only a few leaves "
        "turning soft warm yellow, leaf tips slightly drooping. " + SAME,
    ],
    "sunflower": [
        f"{POT} Planted in it, a tiny sunflower seedling with exactly two small rounded mint "
        f"teal green cotyledon leaves on a short slim stem in dark soil, no flower, very small "
        f"plant. {STYLE}",
        "A young sunflower seedling: two rounded cotyledon leaves plus two small true leaves "
        "beginning to unfold, on a slim upright stem clearly taller than a sprout, no flower "
        "at all. " + SAME,
        "A half-grown green sunflower plant: large rounded heart-shaped mint teal green leaves "
        "on a tall slim stem, clearly bigger and leafier than a seedling, pure foliage only, "
        "no flower, no bud. " + SAME,
        "A mature green sunflower plant with lush leaves and one tightly closed round green "
        "bud completely wrapped in small green sepals at the top, no petals visible at all. "
        + SAME,
        "A sunflower in full bloom: a single medium-sized open flower with pale lemon yellow "
        "petals radiating around a round dark charcoal green center, held upright facing "
        "forward on a sturdy stem, petals crisp and fresh, the flower in natural proportion "
        "to the potted plant. " + SAME,
        "A harvest-ready sunflower: the flower head bowed low toward the ground, a much "
        "smaller closed-looking bloom with shriveled pale yellow petals folded down tight "
        "around the dark center, a few petals falling off, leaves slightly drooping. " + SAME,
    ],
    "cyperus": [
        f"{POT} Planted in it, a tiny cyperus seedling with exactly two small narrow mint teal "
        f"green leaves on a short stem in dark soil, no flower, very small plant. {STYLE}",
        "A young cyperus plant: one short slim stem topped by a small flat umbrella-shaped "
        "cluster of narrow mint teal green leaves. " + SAME,
        "A half-grown papyrus plant: three tall thin bare mint teal green stems, each topped "
        "by a flat spreading umbrella of narrow deep teal green leaves like little paper "
        "umbrellas. " + SAME,
        "A mature papyrus plant: five tall thin bare mint teal green stems, each topped by a "
        "full flat umbrella of narrow deep teal green leaves. " + SAME,
        "A fully lush papyrus plant at peak growth: many more tall stems than a mature plant, "
        "all stems growing upward from the soil inside the pot, each stem topped by a dense "
        "round umbrella of narrow deep teal green leaves, forming a full abundant crown of "
        "umbrellas. " + SAME,
        "A harvest-ready papyrus plant: dense abundant umbrellas with only the outer tips of "
        "the leaves gently drooping downward. " + SAME,
    ],
    "lavender": [
        f"{POT} Planted in it, a tiny lavender seedling with exactly two small rounded mint "
        f"teal green leaves on a short slim stem in dark soil, no flower, very small plant. "
        f"{STYLE}",
        "An entirely green young lavender plant: only a few small narrow pale mint green "
        "leaves on short green stems, zero flowers, zero buds, zero purple anywhere. " + SAME,
        "An entirely green half-grown lavender plant: a neat rounded bush of narrow pale mint "
        "green foliage sitting in the pot, leaves only, zero flowers, zero buds, zero flower "
        "spikes, zero purple anywhere. " + SAME,
        "A mature lavender plant: several tall slender green spikes rising above bushy narrow "
        "pale mint green foliage, each spike carrying rows of tiny tightly closed round green "
        "buds, zero open flowers, zero purple. " + SAME,
        "A lavender plant in full bloom: many slender spikes of muted soft lavender purple "
        "flowers fully open, above bushy pale mint green narrow foliage. " + SAME,
        "A harvest-ready lavender plant: spikes of muted soft lavender purple flowers "
        "beginning to dry, gently drooping to one side. " + SAME,
    ],
    "rose": [
        f"{POT} Planted in it, a tiny rose seedling with exactly two small rounded mint teal "
        f"green leaves on a short slim stem in dark soil, no flower, very small plant. {STYLE}",
        "A young rose plant with a few small rounded pale mint green leaves on a slim stem, "
        "no flowers. " + SAME,
        "A half-grown bushy rose plant: lush pale mint green foliage on slim stems, no "
        "flowers, no buds. " + SAME,
        "A mature rose plant with lush mint green foliage and one tightly closed round rose "
        "bud in soft muted rose pink wrapped in green sepals, no open petals visible at all. "
        + SAME,
        "A rose plant in full bloom: one large open rose flower in soft muted rose pink with "
        "layered rounded petals, fully open. " + SAME,
        "A harvest-ready rose plant: one open soft muted rose pink rose flower with outer "
        "petals beginning to loosen and droop gently. " + SAME,
    ],
}


def build_api_graph(species: str, batch: int, seed: int, mode: str = "fanout") -> dict:
    p = SPECIES[species]
    g = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": batch}},
        "17": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["1", 1]}},
    }
    for i in range(6):
        g[str(11 + i)] = {"class_type": "CLIPTextEncode", "inputs": {"text": p[i], "clip": ["1", 1]}}
        g[str(21 + i)] = {"class_type": "FluxGuidance", "inputs": {"conditioning": [str(11 + i), 0], "guidance": GUIDANCE}}
        latent = ["2", 0] if (i == 0 or mode == "fanout") else [str(30 + i - 1), 0]
        den = 1.0 if mode == "fanout" else DENOISE[i]
        stp = 4 if mode == "fanout" else STEPS[i]
        g[str(30 + i)] = {"class_type": "KSampler", "inputs": {
            "model": ["1", 0], "positive": [str(21 + i), 0], "negative": ["17", 0],
            "latent_image": latent, "seed": seed, "steps": stp, "cfg": 1.0,
            "sampler_name": "euler", "scheduler": "simple", "denoise": den}}
        g[str(40 + i)] = {"class_type": "VAEDecode", "inputs": {"samples": [str(30 + i), 0], "vae": ["1", 2]}}
        g[str(50 + i)] = {"class_type": "SaveImage", "inputs": {
            "images": [str(40 + i), 0], "filename_prefix": f"slowplant/{mode}_{species}_s{i}"}}
    return {"prompt": g}


def build_ui_workflow(species: str, batch: int, seed: int, mode: str = "fanout") -> dict:
    nodes, links = [], []
    lid = [1]

    def add_link(src, sslot, dst, dslot, typ):
        links.append([lid[0], src, sslot, dst, dslot, typ])
        lid[0] += 1
        return lid[0] - 1

    def add_node(nid, ntype, pos, size, title=None, inputs=None, outputs=None, widgets=None):
        n = {"id": nid, "type": ntype, "pos": pos, "size": size, "flags": {}, "order": len(nodes), "mode": 0}
        if title:
            n["title"] = title
        if inputs:
            n["inputs"] = inputs
        if outputs:
            n["outputs"] = outputs
        if widgets is not None:
            n["widgets_values"] = widgets
        n["properties"] = {}
        nodes.append(n)
        return n

    n1 = add_node(1, "CheckpointLoaderSimple", [40, 430], [315, 98], "Flux.1 schnell FP8",
                  outputs=[
                      {"name": "MODEL", "type": "MODEL", "links": [], "slot_index": 0},
                      {"name": "CLIP", "type": "CLIP", "links": [], "slot_index": 1},
                      {"name": "VAE", "type": "VAE", "links": [], "slot_index": 2}],
                  widgets=[CKPT])
    n2 = add_node(2, "EmptySD3LatentImage", [40, 160], [315, 106], "锚点潜空间(batch=候选数)",
                  outputs=[{"name": "LATENT", "type": "LATENT", "links": [], "slot_index": 0}],
                  widgets=[1024, 1024, batch])
    n17 = add_node(17, "CLIPTextEncode", [40, 640], [300, 80], "负向(Flux 留空)",
                   inputs=[{"name": "clip", "type": "CLIP", "link": None}],
                   outputs=[{"name": "CONDITIONING", "type": "CONDITIONING", "links": [], "slot_index": 0}],
                   widgets=[""])

    for i in range(6):
        x = 420 + i * 440
        den = 1.0 if mode == "fanout" else DENOISE[i]
        stp = 4 if mode == "fanout" else STEPS[i]
        clip = add_node(11 + i, "CLIPTextEncode", [x, 40], [400, 190], f"stage{i} 提示语",
                        inputs=[{"name": "clip", "type": "CLIP", "link": None}],
                        outputs=[{"name": "CONDITIONING", "type": "CONDITIONING", "links": [], "slot_index": 0}],
                        widgets=[SPECIES[species][i]])
        fg = add_node(21 + i, "FluxGuidance", [x + 20, 260], [200, 80],
                      inputs=[{"name": "conditioning", "type": "CONDITIONING", "link": None}],
                      outputs=[{"name": "CONDITIONING", "type": "CONDITIONING", "links": [], "slot_index": 0}],
                      widgets=[GUIDANCE])
        ks_inputs = [
            {"name": "model", "type": "MODEL", "link": None},
            {"name": "positive", "type": "CONDITIONING", "link": None},
            {"name": "negative", "type": "CONDITIONING", "link": None},
            {"name": "latent_image", "type": "LATENT", "link": None},
        ]
        ks = add_node(30 + i, "KSampler", [x, 380], [315, 262],
                      f"stage{i} · denoise={den} steps={stp}",
                      inputs=ks_inputs,
                      outputs=[{"name": "LATENT", "type": "LATENT", "links": [], "slot_index": 0}],
                      widgets=[seed, "fixed", stp, 1.0, "euler", "simple", den])
        dec_inputs = [
            {"name": "samples", "type": "LATENT", "link": None},
            {"name": "vae", "type": "VAE", "link": None},
        ]
        dec = add_node(40 + i, "VAEDecode", [x + 40, 700], [210, 46], inputs=dec_inputs,
                       outputs=[{"name": "IMAGE", "type": "IMAGE", "links": [], "slot_index": 0}])
        sv = add_node(50 + i, "SaveImage", [x + 40, 790], [315, 250],
                      inputs=[{"name": "images", "type": "IMAGE", "link": None}],
                      widgets=[f"slowplant/{mode}_{species}_s{i}"])

        clip["inputs"][0]["link"] = add_link(1, 1, 11 + i, 0, "CLIP")
        clip["outputs"][0]["links"].append(add_link(11 + i, 0, 21 + i, 0, "CONDITIONING"))
        fg["outputs"][0]["links"].append(add_link(21 + i, 0, 30 + i, 1, "CONDITIONING"))
        n17["outputs"][0]["links"].append(add_link(17, 0, 30 + i, 2, "CONDITIONING"))
        n1["outputs"][0]["links"].append(add_link(1, 0, 30 + i, 0, "MODEL"))
        n1["outputs"][2]["links"].append(add_link(1, 2, 40 + i, 1, "VAE"))
        ks["outputs"][0]["links"].append(add_link(30 + i, 0, 40 + i, 0, "LATENT"))
        dec["outputs"][0]["links"].append(add_link(40 + i, 0, 50 + i, 0, "IMAGE"))
        src_latent = 2 if (i == 0 or mode == "fanout") else 30 + i - 1
        ks["inputs"][3]["link"] = add_link(src_latent, 0, 30 + i, 3, "LATENT")

    return {"last_node_id": max(n["id"] for n in nodes), "last_link_id": lid[0] - 1,
            "nodes": nodes, "links": links,
            "groups": [{"id": 1, "title": f"六阶段{mode} · {species}(共享锚点潜空间 → 并联生成)",
                        "bounding": [20, 0, 700 + 6 * 440, 1080], "color": "#88A", "font_size": 24, "flags": {}}],
            "config": {}, "extra": {}, "version": 0.4}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--species", default="hydrocotyle", choices=list(SPECIES))
    ap.add_argument("--batch", type=int, default=4)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--mode", default="fanout", choices=["fanout", "chain"],
                    help="fanout=六分支共享锚点(默认);chain=串联(蒸馏模型已验证不适用,留档)")
    ap.add_argument("--api", default=API_DEFAULT)
    args = ap.parse_args()

    tools_dir = pathlib.Path(__file__).parent
    base = tools_dir.parent.parent / "game_art"  # design/game_art
    wf_path = tools_dir / f"{args.mode}_{args.species}.workflow.json"
    ui = build_ui_workflow(args.species, args.batch, args.seed, args.mode)
    wf_path.write_text(__import__("json").dumps(ui, ensure_ascii=False), encoding="utf-8")
    comfy_wf = pathlib.Path(r"C:\Users\Jackson\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\user\default\workflows")
    comfy_wf.mkdir(parents=True, exist_ok=True)
    (comfy_wf / f"slowplant_{args.mode}_{args.species}.json").write_text(
        __import__("json").dumps(ui, ensure_ascii=False), encoding="utf-8")
    print("UI workflow:", wf_path)

    wf = build_api_graph(args.species, args.batch, args.seed, args.mode)
    pid = requests.post(f"{args.api}/prompt", json=wf, timeout=60).json()["prompt_id"]
    print("queued:", pid)

    for _ in range(240):
        time.sleep(5)
        entry = requests.get(f"{args.api}/history/{pid}", timeout=30).json().get(pid, {})
        if entry.get("outputs"):
            break
    else:
        raise SystemExit("timeout")

    out = base / "ai_samples" / "chains" / args.species
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    for node_id in [str(50 + i) for i in range(6)]:
        for img in entry["outputs"][node_id]["images"]:
            r = requests.get(f"{args.api}/view", params={
                "filename": img["filename"], "subfolder": img.get("subfolder", ""),
                "type": img.get("type", "output")}, timeout=120)
            (out / img["filename"]).write_bytes(r.content)
            n += 1
    print(f"DONE {n} files -> {out}")


if __name__ == "__main__":
    main()
