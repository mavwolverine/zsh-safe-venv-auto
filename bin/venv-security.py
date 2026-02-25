#!/usr/bin/env python3
"""
Venv security whitelist/blocklist manager.

Usage:
    venv-security check <venv-path>   # Check and prompt if unknown
    venv-security trust <venv-path>   # Add to trusted list
    venv-security block <venv-path>   # Add to blocked list
    venv-security list                # Show current config
    venv-security remove <venv-path>  # Remove from both lists

Exit codes:
    0 = trusted (activate)
    1 = blocked or declined (don't activate)
    2 = error
"""
import json
import sys
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "zsh-safe-venv-auto"
CONFIG_FILE = CONFIG_DIR / "config.json"


def load_config() -> dict:
    if not CONFIG_FILE.exists():
        return {"trusted": [], "blocked": []}
    try:
        return json.loads(CONFIG_FILE.read_text())
    except (json.JSONDecodeError, IOError):
        return {"trusted": [], "blocked": []}


def save_config(config: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(config, indent=2) + "\n")


def resolve_path(path: str) -> str:
    return str(Path(path).resolve())


def check_venv(venv_path: str) -> int:
    """Check venv status, prompt if unknown. Returns exit code."""
    path = resolve_path(venv_path)
    config = load_config()

    if path in config["trusted"]:
        return 0

    if path in config["blocked"]:
        return 1

    # Unknown venv - prompt user
    print(f"\n🔒 Unknown virtual environment detected:")
    print(f"   {path}\n")

    try:
        response = input("Trust and activate this venv? [y/N/block] ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        print()
        return 1

    if response in ("y", "yes"):
        config["trusted"].append(path)
        save_config(config)
        print(f"✓ Added to trusted list")
        return 0
    elif response in ("b", "block"):
        config["blocked"].append(path)
        save_config(config)
        print(f"✗ Added to blocked list (won't ask again)")
        return 1
    else:
        print(f"– Skipped (will ask again next time)")
        return 1


def trust_venv(venv_path: str) -> int:
    """Add venv to trusted list."""
    path = resolve_path(venv_path)
    config = load_config()

    # Remove from blocked if present
    if path in config["blocked"]:
        config["blocked"].remove(path)

    if path not in config["trusted"]:
        config["trusted"].append(path)
        save_config(config)
        print(f"✓ Trusted: {path}")
    else:
        print(f"Already trusted: {path}")
    return 0


def block_venv(venv_path: str) -> int:
    """Add venv to blocked list."""
    path = resolve_path(venv_path)
    config = load_config()

    # Remove from trusted if present
    if path in config["trusted"]:
        config["trusted"].remove(path)

    if path not in config["blocked"]:
        config["blocked"].append(path)
        save_config(config)
        print(f"✗ Blocked: {path}")
    else:
        print(f"Already blocked: {path}")
    return 0


def remove_venv(venv_path: str) -> int:
    """Remove venv from both lists."""
    path = resolve_path(venv_path)
    config = load_config()
    removed = False

    if path in config["trusted"]:
        config["trusted"].remove(path)
        removed = True

    if path in config["blocked"]:
        config["blocked"].remove(path)
        removed = True

    if removed:
        save_config(config)
        print(f"Removed: {path}")
    else:
        print(f"Not found in any list: {path}")
    return 0


def list_config() -> int:
    """Display current configuration."""
    config = load_config()

    print("Trusted venvs:")
    if config["trusted"]:
        for p in sorted(config["trusted"]):
            print(f" ✓ {p}")
    else:
        print(" (none)")

    print("\nBlocked venvs:")
    if config["blocked"]:
        for p in sorted(config["blocked"]):
            print(f" ✗ {p}")
    else:
        print(" (none)")
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    command = sys.argv[1]

    if command == "list":
        return list_config()

    if len(sys.argv) < 3 and command != "list":
        print(f"Usage: venv-security {command} <venv-path>")
        return 2

    venv_path = sys.argv[2] if len(sys.argv) > 2 else ""

    commands = {
        "check": check_venv,
        "trust": trust_venv,
        "block": block_venv,
        "remove": remove_venv,
    }

    if command not in commands:
        print(f"Unknown command: {command}")
        print(__doc__)
        return 2

    return commands[command](venv_path)


if __name__ == "__main__":
    sys.exit(main())
