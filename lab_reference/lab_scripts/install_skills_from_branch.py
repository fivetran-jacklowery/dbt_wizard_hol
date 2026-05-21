#!/usr/bin/env python3
"""
Pull a selected remote branch and install repo skills into ~/.dbt/wizard/skills.

Workflow:
1. git fetch origin
2. prompt for a remote branch, defaulting to main when available
3. git checkout <branch>
4. git pull --ff-only origin <branch>
5. copy each skill from ./skills into ~/.dbt/wizard/skills, overwriting matches
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_SOURCE_DIR = REPO_ROOT / "skills"
SKILLS_DEST_DIR = Path.home() / ".dbt" / "wizard" / "skills"


class ScriptError(RuntimeError):
    """Expected operational failure with a user-facing message."""


def run_git(args: list[str], *, capture: bool = False) -> str:
    """Run a git command from the repo root."""
    command = ["git", *args]
    try:
        result = subprocess.run(
            command,
            cwd=REPO_ROOT,
            check=True,
            text=True,
            stdout=subprocess.PIPE if capture else None,
            stderr=subprocess.PIPE if capture else None,
        )
    except subprocess.CalledProcessError as exc:
        if capture:
            details = "\n".join(part for part in [exc.stdout, exc.stderr] if part)
            raise ScriptError(f"Command failed: {' '.join(command)}\n{details}".rstrip()) from exc
        raise ScriptError(f"Command failed: {' '.join(command)}") from exc

    return result.stdout.strip() if capture else ""


def ensure_clean_worktree() -> None:
    status = run_git(["status", "--porcelain"], capture=True)
    if status:
        raise ScriptError(
            "Working tree is not clean. Commit, stash, or discard local changes before switching branches.\n"
            f"\n{status}"
        )


def fetch_remote() -> None:
    print("Fetching latest branches from origin...")
    run_git(["fetch", "origin"])


def list_remote_branches() -> list[str]:
    output = run_git(
        [
            "for-each-ref",
            "--format=%(refname:short)",
            "refs/remotes/origin",
        ],
        capture=True,
    )
    branches: list[str] = []
    for line in output.splitlines():
        ref = line.strip()
        if not ref or ref == "origin/HEAD":
            continue
        if ref.startswith("origin/"):
            branches.append(ref.removeprefix("origin/"))

    unique = sorted(set(branches))
    if "main" in unique:
        unique.remove("main")
        return ["main", *unique]
    return unique


def prompt_for_branch(branches: list[str]) -> str:
    if not branches:
        raise ScriptError("No remote branches found under origin.")

    default_branch = "main" if "main" in branches else branches[0]

    print("\nAvailable origin branches:")
    for index, branch in enumerate(branches, start=1):
        default_marker = " (default)" if branch == default_branch else ""
        print(f"  {index:>2}. {branch}{default_marker}")

    while True:
        response = input(f"\nSelect a branch by number or name [{default_branch}]: ").strip()
        if not response:
            return default_branch

        if response.isdigit():
            selected_index = int(response)
            if 1 <= selected_index <= len(branches):
                return branches[selected_index - 1]
            print(f"Invalid number. Choose 1-{len(branches)}.")
            continue

        if response in branches:
            return response

        print(f"Branch not found on origin: {response}")


def local_branch_exists(branch: str) -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "--verify", f"refs/heads/{branch}"],
        cwd=REPO_ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


def checkout_and_pull(branch: str) -> None:
    print(f"\nChecking out {branch}...")
    if local_branch_exists(branch):
        run_git(["checkout", branch])
    else:
        run_git(["checkout", "--track", f"origin/{branch}"])

    print(f"Pulling latest changes for {branch}...")
    run_git(["pull", "--ff-only", "origin", branch])


def copy_skill(source: Path, destination: Path) -> None:
    if destination.exists() or destination.is_symlink():
        if destination.is_dir() and not destination.is_symlink():
            shutil.rmtree(destination)
        else:
            destination.unlink()

    if source.is_dir():
        shutil.copytree(
            source,
            destination,
            ignore=shutil.ignore_patterns(".DS_Store", "__pycache__", "*.pyc"),
        )
    else:
        shutil.copy2(source, destination)


def install_skills() -> list[Path]:
    if not SKILLS_SOURCE_DIR.exists():
        raise ScriptError(f"Skills source directory does not exist: {SKILLS_SOURCE_DIR}")

    SKILLS_DEST_DIR.mkdir(parents=True, exist_ok=True)

    installed: list[Path] = []
    for source in sorted(SKILLS_SOURCE_DIR.iterdir(), key=lambda p: p.name):
        if source.name in {".DS_Store", "__pycache__"}:
            continue
        destination = SKILLS_DEST_DIR / source.name
        copy_skill(source, destination)
        installed.append(destination)

    return installed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Pull a selected origin branch and install repo skills into ~/.dbt/wizard/skills."
    )
    parser.add_argument(
        "--skip-clean-check",
        action="store_true",
        help="Allow branch checkout even when the working tree has local changes.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        if not (REPO_ROOT / ".git").exists():
            raise ScriptError(f"Script must run from inside a git repo. Expected .git at: {REPO_ROOT / '.git'}")

        if not args.skip_clean_check:
            ensure_clean_worktree()

        fetch_remote()
        branch = prompt_for_branch(list_remote_branches())
        checkout_and_pull(branch)
        installed = install_skills()
    except ScriptError as exc:
        print(f"\nERROR: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nCancelled.", file=sys.stderr)
        return 130

    print(f"\nInstalled {len(installed)} skill(s) into {SKILLS_DEST_DIR}:")
    for path in installed:
        print(f"  - {path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
