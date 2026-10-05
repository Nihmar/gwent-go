#!/usr/bin/env python3
"""Cross-check CSS class selectors against the classes used in the mockup HTML.

Catches typos in either direction:
  - classes used in HTML but defined nowhere (broken styling)
  - classes defined in CSS but used nowhere (usually a typo in the HTML)

Definitions are collected from the shared stylesheets and from every inline
<style> block, so each screen may own its layout classes.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HTML_FILES = sorted((ROOT / 'screens').glob('*.html')) + [ROOT / 'index.html']

CLASS_DEF = re.compile(r'\.([A-Za-z][A-Za-z0-9_-]*)')
CLASS_USE = re.compile(r'class="([^"]+)"')
STYLE_BLOCK = re.compile(r'<style[^>]*>(.*?)</style>', re.S)
URL_REF = re.compile(r'url\([^)]*\)')
JS_EXPR = re.compile(r'[\$\{\}\]?=]')


def strip_noise(text: str) -> str:
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    text = URL_REF.sub('', text)
    return text


def html_without_scripts(page: Path) -> str:
    return re.sub(r'<script[^>]*>.*?</script>', '', page.read_text(), flags=re.S)


def definitions() -> set:
    known = set()
    for css in (ROOT / 'css').glob('*.css'):
        known.update(CLASS_DEF.findall(strip_noise(css.read_text())))
    for page in HTML_FILES:
        if not page.exists():
            continue
        for block in STYLE_BLOCK.findall(page.read_text()):
            known.update(CLASS_DEF.findall(strip_noise(block)))
    return known


def usages() -> dict:
    used = {}
    for page in HTML_FILES:
        if not page.exists():
            continue
        for attr in CLASS_USE.findall(html_without_scripts(page)):
            for cls in attr.split():
                if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*', cls):
                    continue  # not a plain class name (template literal, etc.)
                used.setdefault(cls, set()).add(page.name)
    return used


def main() -> int:
    known = definitions()
    used = usages()

    unknown = {c: p for c, p in used.items() if c not in known}
    if unknown:
        print('USED BUT UNDEFINED:')
        for c, pages in sorted(unknown.items()):
            print(f'  .{c}  ({", ".join(sorted(pages))})')
    else:
        print('used-but-undefined: none')

    css_only = sorted(c for c in known if c not in used)
    if css_only:
        print('DEFINED BUT UNUSED:')
        for c in css_only:
            print(f'  .{c}')

    return 1 if unknown else 0


if __name__ == '__main__':
    sys.exit(main())
