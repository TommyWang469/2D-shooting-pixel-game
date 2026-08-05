#!/usr/bin/env python3
"""Run the release-critical Godot drivers in an isolated temporary project."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "new-game-project"
DRIVERS = (
    ("smoke", "SMOKE RESULT: ALL PASS"),
    ("meta", "META RESULT: ALL PASS"),
    ("bosses", "BOSSES RESULT: ALL PASS"),
    ("combat", "PASS: organic combat kills="),
    ("stall", "PASS: stall failsafe teleported straggler"),
)


def find_godot() -> str:
    configured = os.environ.get("GODOT_BIN")
    candidates = (
        configured,
        shutil.which("godot"),
        shutil.which("godot4"),
        str(Path.home() / "Downloads/Godot.app/Contents/MacOS/Godot"),
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    raise SystemExit("Godot 4.7 not found. Set GODOT_BIN to the executable path.")


def run(command: list[str], timeout: int, success_marker: str | None = None) -> int:
    print("+", " ".join(command), flush=True)
    try:
        result = subprocess.run(
            command,
            timeout=timeout,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        print(result.stdout, end="")
        if success_marker and success_marker not in result.stdout:
            return result.returncode or 1
        relevant_output = (
            result.stdout.split(success_marker, 1)[0]
            if success_marker
            else result.stdout
        )
        if any(marker in relevant_output for marker in ("ERROR:", "SCRIPT ERROR:", "FAIL:")):
            return result.returncode or 1
        return result.returncode
    except subprocess.TimeoutExpired:
        print(f"FAIL: timed out after {timeout}s", file=sys.stderr)
        return 124


def audit_user_dirs(name: str) -> list[Path]:
    paths = [
        Path.home() / "Library/Application Support" / name,
        Path.home() / ".local/share/godot/app_userdata" / name,
    ]
    if appdata := os.environ.get("APPDATA"):
        paths.append(Path(appdata) / "Godot/app_userdata" / name)
    return paths


def main() -> int:
    godot = find_godot()
    audit_name = "ThreefoldArsenalChecks-" + uuid.uuid4().hex[:8]

    with tempfile.TemporaryDirectory(prefix="threefold-arsenal-checks-") as temp:
        project = Path(temp) / "project"
        shutil.copytree(
            SOURCE,
            project,
            ignore=shutil.ignore_patterns(".godot", "logs", "build"),
        )
        config_path = project / "project.godot"
        base = config_path.read_text()
        base = base.replace(
            'config/custom_user_dir_name="Pixel Dungeon Blaster"',
            f'config/custom_user_dir_name="{audit_name}"',
            1,
        )
        config_path.write_text(base)

        failed: list[str] = []
        if run([godot, "--headless", "--editor", "--path", str(project), "--quit"], 120):
            return 1

        for driver, success_marker in DRIVERS:
            config = base.replace(
                "[autoload]\n\n",
                "[autoload]\n\n" + f'AuditTest="*res://tests/{driver}.gd"\n',
                1,
            )
            config_path.write_text(config)
            code = run(
                [
                    godot,
                    "--headless",
                    "--path",
                    str(project),
                    "res://scenes/main/main.tscn",
                ],
                180,
                success_marker,
            )
            if code:
                failed.append(driver)

        for path in audit_user_dirs(audit_name):
            shutil.rmtree(path, ignore_errors=True)

    if failed:
        print("FAILED RELEASE CHECKS:", ", ".join(failed), file=sys.stderr)
        return 1
    print("ALL RELEASE CHECKS PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
