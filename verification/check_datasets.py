"""Recompute signed dot products and classify zero and precision events."""
from pathlib import Path
from collections import Counter

def words(path):
    values = []
    for line in path.read_text(encoding="ascii").splitlines():
        value = int(line.strip(),16)
        if not 0 <= value < 2**32:
            raise ValueError(f"Invalid 32-bit word in {path}")
        values.append(value if value < 2**31 else value - 2**32)
    return values

def width(a,b):
    for n in [8,16,32]:
        if -(2**(n-1)) <= min(a,b) and max(a,b) < 2**(n-1):
            return n

def main():
    root = Path(__file__).resolve().parents[1]/"datasets"
    for dataset, checkpoint in [("DNN",3995709172),("MEM_Files",-26017714596)]:
        a,b = [words(root/dataset/name) for name in ["activations.mem","weights.mem"]]
        if len(a)!=784 or len(b)!=784:
            raise ValueError("Expected 784 pairs")
        total = sum(x*y for x,y in zip(a,b))
        skips = sum(x==0 or y==0 for x,y in zip(a,b))
        active = Counter(width(x,y) for x,y in zip(a,b) if x and y)
        print(f"{dataset}: pairs={len(a)} skips={skips} sum={total} bits=0x{total % 2**65:017x} active={sorted(active.items())}")
        if total!=checkpoint or skips!=629:
            raise ValueError("Dataset checkpoint failed")
if __name__=="__main__":
    main()

