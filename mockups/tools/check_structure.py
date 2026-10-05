#!/usr/bin/env python3
"""Lightweight HTML tag-balance check for the mockup screens (no browser needed)."""
import sys
from html.parser import HTMLParser
from pathlib import Path

VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link',
        'meta', 'param', 'source', 'track', 'wbr'}
HTML_FILES = sorted(Path(__file__).resolve().parents[1].glob('screens/*.html')) + \
             [Path(__file__).resolve().parents[1] / 'index.html']


class Balance(HTMLParser):
    def __init__(self, name):
        super().__init__(convert_charrefs=True)
        self.name = name
        self.stack = []
        self.errors = []

    def handle_starttag(self, tag, attrs):
        if tag not in VOID:
            self.stack.append((tag, self.getpos()[0]))

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if not self.stack:
            self.errors.append(f'line {self.getpos()[0]}: closing </{tag}> with empty stack')
            return
        open_tag, line = self.stack.pop()
        if open_tag != tag:
            self.errors.append(f'line {self.getpos()[0]}: </{tag}> closes <{open_tag}> opened at line {line}')


def main() -> int:
    failed = 0
    for page in HTML_FILES:
        if not page.exists():
            continue
        parser = Balance(page.name)
        parser.feed(page.read_text())
        for tag, line in parser.stack:
            parser.errors.append(f'unclosed <{tag}> opened at line {line}')
        if parser.errors:
            failed = 1
            print(f'{page.name}:')
            for e in parser.errors:
                print(f'  {e}')
        else:
            print(f'{page.name}: ok')
    return failed


if __name__ == '__main__':
    sys.exit(main())
