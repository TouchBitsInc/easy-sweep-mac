#!/usr/bin/env python3
"""Builds the translated product pages from the English one.

    python3 i18n/build.py extract   list every string on web/index.html in i18n/en.json
    python3 i18n/build.py           write web/<lang>/index.html for every language,
                                    and the language links and hreflang into all pages

web/index.html is the only page anyone edits. A string is a whole piece of text
as a reader sees it: a heading, a paragraph with its <strong> and <a> inside, a
link's words, an alt text, the title and descriptions. i18n/<lang>.json maps each
English string, whitespace collapsed, to its translation; one that is missing
falls back to English and is listed, so a change to the English page shows up as
work to do rather than as a page in two languages.

The languages are the app's own (EasySweep/Resources/Localizable.xcstrings in
the app repository). Support, privacy and terms stay English.
"""
import html.parser, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(HERE, '..', 'web')
SITE = 'https://easysweep.app'

# hreflang code, URL folder, name in that language — in the order the menu lists them
LANGS = [
    ('en', '', 'English'),
    ('de', 'de', 'Deutsch'),
    ('es', 'es', 'Español'),
    ('fr', 'fr', 'Français'),
    ('it', 'it', 'Italiano'),
    ('nl', 'nl', 'Nederlands'),
    ('pl', 'pl', 'Polski'),
    ('pt-BR', 'pt-br', 'Português (Brasil)'),
    ('tr', 'tr', 'Türkçe'),
    ('ru', 'ru', 'Русский'),
    ('uk', 'uk', 'Українська'),
    ('ja', 'ja', '日本語'),
    ('ko', 'ko', '한국어'),
    ('zh-Hans', 'zh-hans', '简体中文'),
    ('zh-Hant', 'zh-hant', '繁體中文（台灣）'),
    ('zh-HK', 'zh-hk', '繁體中文（香港）'),
]

INLINE = {'a', 'strong', 'em', 'b', 'i', 'br', 'code', 'span', 'abbr', 'small'}
VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr'}
SKIP = {'script', 'style', 'svg'}
ATTRS = ('alt', 'aria-label', 'title', 'placeholder')
META = ('description', 'og:title', 'og:description', 'twitter:title', 'twitter:description')


class Node:
    def __init__(self, tag, start, inner_start, parent):
        self.tag, self.start, self.inner_start, self.parent = tag, start, inner_start, parent
        self.end = self.inner_end = None
        self.children = []   # Node, or (start, end) for a run of text


class Tree(html.parser.HTMLParser):
    """The page as a tree of elements, each with its offsets in the source."""

    def __init__(self, source):
        super().__init__(convert_charrefs=False)
        self.source = source
        self.lines = [0]
        for line in source.splitlines(keepends=True):
            self.lines.append(self.lines[-1] + len(line))
        self.root = Node('#root', 0, 0, None)
        self.open = self.root
        self.feed(source)
        self.close()

    def at(self):
        line, col = self.getpos()
        return self.lines[line - 1] + col

    def handle_starttag(self, tag, attrs):
        start = self.at()
        node = Node(tag, start, start + len(self.get_starttag_text()), self.open)
        self.open.children.append(node)
        if tag in VOID:
            node.end = node.inner_end = node.inner_start
        else:
            self.open = node

    def handle_startendtag(self, tag, attrs):
        start = self.at()
        node = Node(tag, start, start + len(self.get_starttag_text()), self.open)
        node.end = node.inner_end = node.inner_start
        self.open.children.append(node)

    def handle_endtag(self, tag):
        node = self.open
        while node is not self.root and node.tag != tag:
            node = node.parent
        if node is self.root:
            return
        node.inner_end = self.at()
        node.end = self.source.index('>', node.inner_end) + 1
        self.open = node.parent

    def _text(self, raw):
        start = self.at()
        self.open.children.append((start, start + len(raw)))

    def handle_data(self, data): self._text(data)
    def handle_entityref(self, name): self._text(f'&{name};')
    def handle_charref(self, name): self._text(f'&#{name};')


def collapse(text):
    return re.sub(r'\s+', ' ', text).strip()


def has_words(text):
    return re.search(r'[^\W\d_]', re.sub(r'<[^>]*>|&\w+;', ' ', text)) is not None


def units(source):
    """(start, end) of every translatable run in the source, in order."""
    found = []

    def own_text(node):
        return any(isinstance(c, tuple) and has_words(source[c[0]:c[1]]) for c in node.children)

    def all_inline(node):
        return all(isinstance(c, tuple) or (c.tag in INLINE and all_inline(c)) for c in node.children)

    def walk(node):
        if node.tag in SKIP:
            return
        if node.tag not in ('#root', 'html', 'body', 'head') and own_text(node) and all_inline(node):
            found.append((node.inner_start, node.inner_end))
            return
        for child in node.children:
            if isinstance(child, tuple):
                if has_words(source[child[0]:child[1]]):
                    found.append(child)
            elif child.tag not in SKIP:
                walk(child)

    walk(Tree(source).root)
    # attributes, and the meta descriptions
    for m in re.finditer(r'<(?:img|a|button|input|nav|ul|div|section|span)\b[^>]*>', source):
        for attr in ATTRS:
            a = re.search(r'\s%s="([^"]*)"' % attr, m.group(0))
            if a and has_words(a.group(1)):
                found.append((m.start() + a.start(1), m.start() + a.end(1)))
    for m in re.finditer(r'<meta\s+(?:name|property)="([^"]+)"\s+content="([^"]*)"', source):
        if m.group(1) in META:
            found.append((m.start(2), m.end(2)))
    return sorted(set(found))


def strip_generated(source):
    """The English page without what this script writes into it."""
    source = re.sub(r'\n?<!-- i18n:alternates -->.*?<!-- /i18n:alternates -->', '', source, flags=re.S)
    source = re.sub(r'[ ]*<!-- i18n:langs -->.*?<!-- /i18n:langs -->\n', '', source, flags=re.S)
    source = re.sub(r'\n?\s*<!-- i18n:langs -->.*?<!-- /i18n:langs -->', '', source, flags=re.S)
    return source


def english():
    return strip_generated(open(os.path.join(WEB, 'index.html'), encoding='utf-8').read())


def extract():
    source = english()
    keys = []
    for start, end in units(source):
        key = collapse(source[start:end])
        if key not in keys:
            keys.append(key)
    with open(os.path.join(HERE, 'en.json'), 'w', encoding='utf-8') as f:
        json.dump(keys, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(f'{len(keys)} strings → i18n/en.json')


def url(folder):
    return f'{SITE}/{folder}/' if folder else f'{SITE}/'


def alternates():
    lines = [f'<link rel="alternate" hreflang="{code}" href="{url(folder)}">' for code, folder, _ in LANGS]
    lines.append(f'<link rel="alternate" hreflang="x-default" href="{url("")}">')
    return '\n<!-- i18n:alternates -->\n' + '\n'.join(lines) + '\n<!-- /i18n:alternates -->'


def menu(current):
    """The language menu at the top right of the nav: a globe and the page's own
    language, opening onto every language named in itself. A <details>, so it
    opens with no script; js/lang.js only closes it on an outside click."""
    name = next(n for c, _, n in LANGS if c == current)
    items = []
    for code, folder, label in LANGS:
        here = ' aria-current="true"' if code == current else ''
        items.append(f'        <a href="/{folder + "/" if folder else ""}" hreflang="{code}" lang="{code}" data-lang="{code}"{here}>{label}</a>')
    globe = ('<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" '
             'stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>')
    return ('    <!-- i18n:langs -->\n    <details class="langmenu">\n'
            f'      <summary aria-label="Language">{globe}<span>{name}</span></summary>\n'
            '      <nav class="langmenu__list" aria-label="Language">\n'
            + '\n'.join(items) + '\n      </nav>\n    </details>\n    <!-- /i18n:langs -->\n')


def decorate(source, code):
    """Adds the hreflang links and the language menu."""
    source = source.replace('<link rel="canonical"', alternates().lstrip('\n') + '\n<link rel="canonical"', 1)
    # last in the nav, at its far right, after the Download button
    source = re.sub(r'(    <a class="btn btn--primary btn--sm"[^\n]*\n)', lambda m: m.group(1) + menu(code), source, count=1)
    return source


def build():
    source = english()
    spans = units(source)
    with open(os.path.join(WEB, 'index.html'), 'w', encoding='utf-8') as f:
        f.write(decorate(source, 'en'))
    missing_total = 0
    for code, folder, _ in LANGS[1:]:
        path = os.path.join(HERE, f'{code}.json')
        table = json.load(open(path, encoding='utf-8')) if os.path.exists(path) else {}
        out, last, missing = [], 0, []
        for start, end in spans:
            raw = source[start:end]
            key = collapse(raw)
            text = table.get(key)
            if not text:
                missing.append(key)
                text = key
            lead = raw[:len(raw) - len(raw.lstrip())]
            trail = raw[len(raw.rstrip()):]
            out.append(source[last:start] + lead + text + trail)
            last = end
        page = ''.join(out) + source[last:]
        page = page.replace('<html lang="en">', f'<html lang="{code}">', 1)
        page = page.replace(f'<link rel="canonical" href="{SITE}/">', f'<link rel="canonical" href="{url(folder)}">')
        page = page.replace(f'<meta property="og:url" content="{SITE}/">', f'<meta property="og:url" content="{url(folder)}">')
        page = page.replace('<a class="brand" href="/">', f'<a class="brand" href="/{folder}/">')
        page = decorate(page, code)
        os.makedirs(os.path.join(WEB, folder), exist_ok=True)
        with open(os.path.join(WEB, folder, 'index.html'), 'w', encoding='utf-8') as f:
            f.write(page)
        if missing:
            missing_total += len(missing)
            print(f'{code}: {len(missing)} strings still English')
    write_sitemap()
    print(f'built {len(LANGS) - 1} languages' + (f', {missing_total} strings missing' if missing_total else ''))


def write_sitemap():
    path = os.path.join(WEB, 'sitemap.xml')
    sitemap = open(path, encoding='utf-8').read()
    sitemap = re.sub(r'\s*<!-- i18n -->.*?<!-- /i18n -->', '', sitemap, flags=re.S)
    entries = ''.join(f'\n  <url><loc>{url(folder)}</loc></url>' for _, folder, _ in LANGS[1:])
    sitemap = sitemap.replace('</urlset>', f'  <!-- i18n -->{entries}\n  <!-- /i18n -->\n</urlset>')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(sitemap)


if __name__ == '__main__':
    extract() if sys.argv[1:] == ['extract'] else build()
