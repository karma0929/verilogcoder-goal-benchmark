#!/usr/bin/env python3
import sys, re

def is_01(v: str) -> bool:
    return all(ch in "01" for ch in v)

def main(vcd_path: str):
    # id -> (name, width)
    id2sig = {}
    # id -> last value (string of 0/1, vector MSB..LSB), None if unknown
    last = {}
    toggles = {}  # id -> toggle count (bit toggles summed)
    cur_time = None
    in_header = True

    # Some VCD lines:
    # $var wire 1 ! clk $end
    # $var wire 4 " q [3:0] $end
    var_re = re.compile(r'^\$var\s+\S+\s+(\d+)\s+(\S+)\s+(.+?)\s+\$end')

    with open(vcd_path, "r", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            if in_header:
                if line.startswith("$var"):
                    m = var_re.match(line)
                    if m:
                        width = int(m.group(1))
                        vid = m.group(2)
                        name = m.group(3).strip()
                        id2sig[vid] = (name, width)
                        last[vid] = None
                        toggles[vid] = 0
                elif line == "$enddefinitions $end":
                    in_header = False
                continue

            if line.startswith("#"):
                cur_time = int(line[1:])
                continue

            # scalar: 0! 1!
            if line[0] in "01xzXZ":
                val = line[0].lower()
                vid = line[1:].strip()
                if vid not in id2sig:
                    continue
                if val not in "01":
                    last[vid] = None
                    continue
                prev = last[vid]
                if prev is None:
                    last[vid] = val
                else:
                    if prev != val:
                        toggles[vid] += 1
                    last[vid] = val
                continue

            # vector: b1010 "
            if line[0] in "bB":
                parts = line.split()
                if len(parts) != 2:
                    continue
                bits = parts[0][1:].lower()
                vid = parts[1]
                if vid not in id2sig:
                    continue
                # ignore x/z vectors
                if not is_01(bits):
                    last[vid] = None
                    continue
                prev = last[vid]
                if prev is None:
                    last[vid] = bits
                else:
                    # count bit flips
                    if len(prev) != len(bits):
                        # width mismatch; reset
                        last[vid] = bits
                    else:
                        flips = sum(1 for a,b in zip(prev, bits) if a != b)
                        toggles[vid] += flips
                        last[vid] = bits
                continue

    # Summaries
    # total bit toggles across all signals
    total = sum(toggles.values())

    # Print top signals by toggles
    ranked = sorted(toggles.items(), key=lambda kv: kv[1], reverse=True)
    print(f"VCD: {vcd_path}")
    print(f"Signals parsed: {len(id2sig)}")
    print(f"Total bit-toggles (proxy dynamic activity): {total}")
    print("")
    print("Top 20 signals by bit-toggles:")
    for vid, t in ranked[:20]:
        name, width = id2sig.get(vid, ("?", 0))
        print(f"{t:10d}  width={width:<4d}  {name}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: vcd_toggle.py <wave.vcd>", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1])
