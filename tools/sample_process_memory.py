#!/usr/bin/env python3
"""Sample a Linux simulator process; these are process totals, not MCU RAM."""
import argparse
import json
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pid", type=int)
    parser.add_argument("--seconds", type=int, default=60)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.pid <= 0 or args.seconds <= 0:
        parser.error("pid and seconds must be positive")

    proc = Path("/proc") / str(args.pid)
    def identity():
        # The command name can contain spaces and parentheses.
        return proc.joinpath("stat").read_text().rsplit(")", 1)[1].split()[19]

    started = time.monotonic()
    samples = []
    error = None
    try:
        process_start = identity()
        for _ in range(args.seconds):
            if identity() != process_start:
                raise RuntimeError("PID was reused by another process")
            sample = {"elapsed_s": round(time.monotonic() - started, 3)}
            for line in proc.joinpath("smaps_rollup").read_text().splitlines():
                key, _, value = line.partition(":")
                if key in ("Rss", "Pss", "Private_Clean", "Private_Dirty", "Swap"):
                    sample[key + "_KiB"] = int(value.split()[0])
            samples.append(sample)
            time.sleep(1)
    except (OSError, RuntimeError) as exc:
        error = str(exc)
    args.output.write_text(json.dumps({"pid": args.pid, "error": error,
                                      "samples": samples}, indent=2) + "\n")
    if error:
        raise SystemExit(error)
    print(f"Saved {len(samples)} samples to {args.output}")


if __name__ == "__main__":
    main()
