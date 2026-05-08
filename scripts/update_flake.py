#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path


def replace_version(flake_path: Path, old_ver: str, new_ver: str) -> None:
    # 意図しない変更を防ぐため、version の置換は1回だけ行う
    s = flake_path.read_text()
    old = re.escape(old_ver)
    updated, n = re.subn(
        rf'version\s*=\s*"{old}";',
        f'version = "{new_ver}";',
        s,
        count=1,
    )
    if n != 1:
        raise SystemExit("failed to replace version uniquely")
    flake_path.write_text(updated)


def replace_block_hash(flake_path: Path, block_name: str, hash_value: str) -> None:
    # 指定ブロックを見つけて、その hash フィールドだけを1回更新する
    s = flake_path.read_text()
    name = re.escape(block_name)
    pat = re.compile(rf'({name}\s*\{{[\s\S]*?\n\s*hash\s*=\s*")[^"]+(";)', re.MULTILINE)
    updated, n = pat.subn(rf'\1{hash_value}\2', s, count=1)
    if n != 1:
        raise SystemExit(f"failed to replace hash in block: {block_name}")
    flake_path.write_text(updated)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update version/hash values in flake.nix")
    sub = parser.add_subparsers(dest="command", required=True)

    ver = sub.add_parser("replace-version")
    ver.add_argument("flake")
    ver.add_argument("old")
    ver.add_argument("new")

    h = sub.add_parser("replace-block-hash")
    h.add_argument("flake")
    h.add_argument("block")
    h.add_argument("hash")

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    flake_path = Path(args.flake)

    if args.command == "replace-version":
        replace_version(flake_path, args.old, args.new)
        return 0

    if args.command == "replace-block-hash":
        replace_block_hash(flake_path, args.block, args.hash)
        return 0

    # 防御的ガード。argparse により通常ここには到達しない。
    raise SystemExit("unknown command")


if __name__ == "__main__":
    sys.exit(main())
