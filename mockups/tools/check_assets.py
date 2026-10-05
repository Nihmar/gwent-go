#!/usr/bin/env python3
"""Check that every image referenced by a mockup screen exists on disk."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # repo root
PATTERN = re.compile(r"url\(['\"]?([^'\")]+)['\"]?\)")

def check(path: Path) -> int:
    text = path.read_text()
    missing = []
    for ref in sorted(set(PATTERN.findall(text))):
        if ref.startswith(('http', 'data:')) or '$' in ref or '...' in ref:
            continue
        target = (path.parent / ref).resolve()
        if not target.exists():
            missing.append(ref)
    # also check CSS files referenced by <link>
    for css in re.findall(r'<link[^>]+href="([^"]+)"', text):
        if css.startswith(('http', 'data:')):
            continue
        css_path = (path.parent / css).resolve()
        if not css_path.exists():
            missing.append(css)
            continue
        for ref in sorted(set(PATTERN.findall(css_path.read_text()))):
            if ref.startswith(('http', 'data:')) or '$' in ref or '...' in ref:
                continue
            target = (css_path.parent / ref).resolve()
            if not target.exists():
                missing.append(f'{css} -> {ref}')
    if missing:
        print(f'{path}:')
        for m in missing:
            print(f'  MISSING {m}')
        return 1
    print(f'{path}: ok')
    return 0

if __name__ == '__main__':
    files = [Path(a) for a in sys.argv[1:]]
    sys.exit(max(check(f) for f in files))
