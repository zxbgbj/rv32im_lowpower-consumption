from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


HEX_RE = re.compile(r"0x([0-9a-fA-F]+)|\b([0-9a-fA-F]{8})\b")


def load_signature(path: Path) -> list[str]:
    values: list[str] = []
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line:
            continue
        match = HEX_RE.search(line)
        if not match:
            continue
        value = match.group(1) or match.group(2)
        values.append(value.lower().zfill(8))
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare two signature files after normalizing word formatting.")
    parser.add_argument("--expected", required=True, help="Expected signature file")
    parser.add_argument("--actual", required=True, help="Actual signature file")
    args = parser.parse_args()

    expected = Path(args.expected)
    actual = Path(args.actual)

    if not expected.exists():
        print(f"Expected signature file not found: {expected}")
        return 2
    if not actual.exists():
        print(f"Actual signature file not found: {actual}")
        return 3

    expected_words = load_signature(expected)
    actual_words = load_signature(actual)
    if expected_words != actual_words:
        print("Signature mismatch")
        max_len = max(len(expected_words), len(actual_words))
        for idx in range(max_len):
            exp_val = expected_words[idx] if idx < len(expected_words) else "<missing>"
            act_val = actual_words[idx] if idx < len(actual_words) else "<missing>"
            if exp_val != act_val:
                print(f"  line {idx + 1}: expected={exp_val} actual={act_val}")
                break
        return 4

    print("Signature matches expected results")
    return 0


if __name__ == "__main__":
    sys.exit(main())
