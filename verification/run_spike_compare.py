from __future__ import annotations
import argparse
import os
import subprocess
import sys
from pathlib import Path


def load_signature(path: Path) -> list[str]:
    return [line.strip().lower() for line in path.read_text().splitlines() if line.strip()]


def run_spike(spike: str, isa: str, elf: Path, spike_sig: Path, style: str) -> int:
    if style == "option":
        cmd = [spike, f"--isa={isa}", f"--signature={spike_sig}", str(elf)]
    else:
        cmd = [spike, f"--isa={isa}", f"+signature={spike_sig}", str(elf)]
    print("Running Spike:", " ".join(str(x) for x in cmd))
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(proc.stdout)
    return proc.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Spike and compare signature output.")
    parser.add_argument("--elf", required=True, help="ELF to run on Spike")
    parser.add_argument("--rtl-signature", required=True, help="RTL generated signature file")
    parser.add_argument("--spike-signature", required=True, help="Spike generated signature file")
    parser.add_argument("--isa", default="rv32im_zicsr", help="Spike ISA string")
    parser.add_argument("--signature-style", choices=["auto", "option", "plus"], default=os.environ.get("SPIKE_SIGNATURE_STYLE", "auto"), help="How to pass signature output path to Spike")
    args = parser.parse_args()

    spike = os.environ.get("SPIKE_BIN")
    if not spike:
        print("SPIKE_BIN is not set.")
        return 1

    elf = Path(args.elf)
    rtl_sig = Path(args.rtl_signature)
    spike_sig = Path(args.spike_signature)
    spike_sig.parent.mkdir(parents=True, exist_ok=True)

    styles = [args.signature_style]
    if args.signature_style == "auto":
        styles = ["option", "plus"]

    rc = 1
    for style in styles:
        if spike_sig.exists():
            spike_sig.unlink()
        rc = run_spike(spike, args.isa, elf, spike_sig, style)
        if rc == 0 and spike_sig.exists():
            break
    if rc != 0:
        print("Spike execution failed")
        return rc
    if not rtl_sig.exists():
        print(f"RTL signature not found: {rtl_sig}")
        return 2
    if not spike_sig.exists():
        print(f"Spike signature not found: {spike_sig}")
        return 3

    rtl_lines = load_signature(rtl_sig)
    spike_lines = load_signature(spike_sig)
    if rtl_lines != spike_lines:
        print("Signature mismatch")
        max_len = max(len(rtl_lines), len(spike_lines))
        for idx in range(max_len):
            rtl_val = rtl_lines[idx] if idx < len(rtl_lines) else '<missing>'
            spike_val = spike_lines[idx] if idx < len(spike_lines) else '<missing>'
            if rtl_val != spike_val:
                print(f"  line {idx+1}: rtl={rtl_val} spike={spike_val}")
                break
        return 4

    print("Spike signature matches RTL signature")
    return 0


if __name__ == "__main__":
    sys.exit(main())