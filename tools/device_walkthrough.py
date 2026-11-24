#!/usr/bin/env python3
"""One entry point for repeatable iOS/Android physical-device walkthroughs."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CASE_REGISTRY = ROOT / "quality/mobile-walkthrough.json"
TEST = ROOT / "app/integration_test/walkthrough_test.dart"
FIXTURE = ROOT / "app/integration_test/fixtures/walkthrough_seed.dart"


def read_case_registry():
    registry = json.loads(CASE_REGISTRY.read_text(encoding="utf-8"))
    if registry.get("schema") != 1:
        raise ValueError("不支持的走查用例清单版本")
    for group, pattern in (("automated", r"W\d{2}"), ("manual", r"M\d{2}-[a-z-]+")):
        entries = registry.get(group)
        if not isinstance(entries, dict) or not entries or any(
                not re.fullmatch(pattern, case) or not isinstance(description, str)
                or not description.strip() for case, description in entries.items()):
            raise ValueError(f"走查用例清单 {group} 无效")
    markers = re.findall(
        r"^\s*passed\(['\"](W\d{2})['\"]\);", TEST.read_text(encoding="utf-8"), re.M
    )
    if sorted(markers) != sorted(registry["automated"]):
        raise ValueError(
            f"Flutter 完成标记与共用用例清单不一致：{markers} != {list(registry['automated'])}"
        )
    if not FIXTURE.is_file():
        raise ValueError(f"缺少共用测试数据：{FIXTURE.relative_to(ROOT)}")
    return registry


def capture(args, timeout=45):
    return subprocess.check_output(args, cwd=ROOT, text=True, timeout=timeout)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--device", help="flutter devices 中的真机 ID")
    modes.add_argument("--check-contract", action="store_true", help="只检查共用用例和 Flutter 测试标记")
    parser.add_argument("--flutter", default=os.environ.get("FLUTTER", "flutter"))
    parser.add_argument("--flavor", choices=["master", "dev"], default="master")
    parser.add_argument("--design-ref", help="两端共用的已审阅设计版本；省略时报告仅供单机走查")
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/device-walkthrough")
    args = parser.parse_args()
    try:
        registry = read_case_registry()
    except (OSError, ValueError) as error:
        parser.error(str(error))
    cases = registry["automated"]
    if args.check_contract:
        print(f"PASS: {len(cases)} 个共用自动用例，{len(registry['manual'])} 个共用人工用例")
        return 0

    flutter = shutil.which(args.flutter)
    if not flutter:
        parser.error("找不到 Flutter；用 --flutter 指定 SDK 的 flutter 可执行文件")
    devices = json.loads(capture([flutter, "devices", "--machine"]))
    device = next((d for d in devices if d["id"] == args.device), None)
    if not device or device.get("emulator") or device.get("targetPlatform") not in (
            "ios", "android-arm", "android-arm64", "android-x64"):
        parser.error("请选择已连接的 iOS/Android 真机；模拟器不计为真机验收")

    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    folder = args.output.resolve() / stamp
    folder.mkdir(parents=True)
    command = [flutter, "test", str(TEST.relative_to(ROOT / "app")),
               "-d", args.device, "--no-pub", "--no-uninstall",
               "--reporter", "expanded"]
    if args.flavor == "dev":
        command += ["--dart-define=BUILD_ENV=dev"]
    if device["targetPlatform"].startswith("android"):
        command += ["--flavor", args.flavor]
    report = {
        "schema": 1, "startedUtc": stamp, "device": device,
        "flavor": args.flavor, "command": command,
        "designRef": args.design_ref,
        "fixture": "walkthrough-v1-memory-prefs",
        "fixtureSha256": hashlib.sha256(FIXTURE.read_bytes()).hexdigest(),
        "sourceHashes": {
            str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in [FIXTURE, TEST, CASE_REGISTRY, Path(__file__).resolve()]
        },
        "gitHead": capture(["git", "rev-parse", "HEAD"]).strip(),
        "gitStatus": capture(["git", "status", "--porcelain"]),
        "flutter": json.loads(capture([flutter, "--version", "--machine"])),
        "manual": {case: {"status": "pending", "evidence": ""} for case in registry["manual"]},
        "automatedStatus": "running", "overallStatus": "incomplete",
    }
    report_path = folder / "report.json"

    def save():
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")

    save()
    print(f"结果目录：{folder}", flush=True)
    log_path = folder / "flutter.log"
    try:
        with log_path.open("w") as log:
            process = subprocess.Popen(command, cwd=ROOT / "app", stdout=log,
                                       stderr=subprocess.STDOUT)
            try:
                code = process.wait(timeout=900)
            except (subprocess.TimeoutExpired, KeyboardInterrupt):
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                raise
        contents = log_path.read_text(errors="replace")
        conditions = re.findall(r"WALK_CONDITIONS:(\{[^\n]+\})", contents)
        report["displayConditions"] = json.loads(conditions[-1]) if conditions else None
        completed = set(re.findall(r"WALK_PASS:(W\d{2})", contents))
        report["cases"] = {case: "passed" if case in completed else "not_passed"
                           for case in cases}
        report["exitCode"] = code
        passed = code == 0 and set(cases) == completed
        report["automatedStatus"] = "passed" if passed else "failed"
        print(contents)
    except (subprocess.TimeoutExpired, KeyboardInterrupt) as error:
        report["automatedStatus"] = "interrupted"
        report["error"] = type(error).__name__
        passed = False
    finally:
        report["finishedUtc"] = dt.datetime.now(dt.timezone.utc).isoformat()
        save()
    print(f"自动化：{report['automatedStatus']}；人工项目待验收。报告：{report_path}")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
