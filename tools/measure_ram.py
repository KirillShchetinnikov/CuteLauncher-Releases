"""Read-only, repeatable Android process measurements. No installs, launches or force-stops."""
import argparse
import datetime
import json
import re
import subprocess
from pathlib import Path


def parse_meminfo(text):
    result = {"pss_bytes": None, "rss_bytes": None}
    for name, pattern in [("pss_bytes", r"TOTAL PSS:\s*(\d+)"),
                          ("rss_bytes", r"TOTAL RSS:\s*(\d+)")]:
        match = re.search(pattern, text)
        if match:
            result[name] = int(match[1]) * 1024
    if result["pss_bytes"] is None:
        match = re.search(r"^\s*TOTAL\s+(\d+)\s", text, re.MULTILINE)
        if match:
            result["pss_bytes"] = int(match[1]) * 1024
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", required=True)
    parser.add_argument("--package", default="io.github.kirillshchetinnikov.cutelauncher")
    parser.add_argument("--scenario", required=True)
    parser.add_argument("--build", choices=["release", "profile", "debug"], required=True)
    parser.add_argument("--notes", default="")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_.]+", args.package):
        parser.error("Invalid package name")

    def adb(*command):
        result = subprocess.run([args.adb, "-s", args.serial, *command],
                                capture_output=True, text=True, timeout=30, encoding="utf-8", errors="replace")
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip())
        return result.stdout.strip()

    installed = adb("shell", "pm", "list", "packages", args.package).splitlines()
    if "package:" + args.package not in installed:
        parser.error("Requested app is not installed; no process measurement was made")
    raw = adb("shell", "dumpsys", "meminfo", args.package)
    memory = parse_meminfo(raw)
    if memory["pss_bytes"] is None:
        parser.error("App is not running or memory report is unavailable")
    total = adb("shell", "cat", "/proc/meminfo")
    match = re.search(r"MemTotal:\s*(\d+)", total)
    sample = {
        "measured_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "model": adb("shell", "getprop", "ro.product.model"),
        "android": adb("shell", "getprop", "ro.build.version.release"),
        "device_ram_bytes": int(match[1]) * 1024 if match else None,
        "package": args.package, "build": args.build, "scenario": args.scenario,
        "package_details": adb("shell", "dumpsys", "package", args.package),
        "installed_package_count": len(adb("shell", "pm", "list", "packages").splitlines()),
        "process": memory, "dart_heap_bytes": None, "dart_external_bytes": None,
        "cache_bytes": None, "notes": args.notes, "raw_meminfo": raw,
    }
    target = Path(args.output)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(sample, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"scenario": args.scenario, **memory}, ensure_ascii=False))


if __name__ == "__main__":
    main()
