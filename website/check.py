#!/usr/bin/env python3
"""Check generated links, bilingual coverage, argument coverage and R syntax."""
from pathlib import Path
from urllib.parse import urlsplit, unquote, parse_qs
import hashlib
import json
import csv
import re
import subprocess
import tempfile
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parents[1]
SITE=ROOT/'_site'
errors=[]
version=re.search(r'^Version: (.+)$',(ROOT/'DESCRIPTION').read_text(),re.M)[1]
pages={p:BeautifulSoup(p.read_text(),'html.parser') for p in SITE.rglob('*.html')}
functions=json.loads((ROOT/'website/.build/api/functions.json').read_text())
# Cover legacy package-help images as well as the website's bundled figures.
with (ROOT/'docs/results/manual-figure-inventory.csv').open() as handle:
    inventory=list(csv.DictReader(handle))
actual={p.relative_to(ROOT).as_posix() for directory in ['docs/figures','man/figures']
        for p in (ROOT/directory).rglob('*') if p.suffix.lower() in ('.png','.svg')}
if actual != {row['path'] for row in inventory}:
    errors.append('Manual figure inventory does not cover all image assets')
for row in inventory:
    asset=ROOT/row['path']
    if not asset.exists() or hashlib.sha256(asset.read_bytes()).hexdigest()!=row['sha256']:
        errors.append('Manual figure inventory is stale: '+row['path'])
blocks=[]
for path,soup in pages.items():
    name=path.relative_to(SITE).as_posix()
    for paragraph in soup.select('main p'):
        prose=''.join(str(part) for part in paragraph.find_all(string=True)
                      if part.find_parent(['code','pre']) is None)
        if r'\n\n' in prose:
            errors.append(f'{name}: escaped paragraph break is visible in prose')
    if name in ('index.html','zh/index.html'):
        current=soup.select_one('.current-version')
        if current is None or current.get_text(strip=True)!=version:
            errors.append(f'{name}: installation version must match DESCRIPTION ({version})')
        if '{{VERSION}}' in soup.get_text():errors.append(f'{name}: unresolved version placeholder')
    if not soup.find('h1') or len(soup.find_all('h1'))!=1:errors.append(f'{name}: expected one h1')
    ids=[n['id'] for n in soup.select('[id]')]
    if len(ids)!=len(set(ids)):errors.append(f'{name}: duplicate anchor IDs')
    for node in soup.select('a[href], img[src], script[src], link[href]'):
        value=node.get('href',node.get('src','')); u=urlsplit(value)
        if u.scheme or u.netloc:continue
        target=(path.parent/unquote(u.path)).resolve() if u.path else path
        if target.is_dir():target=target/'index.html'
        if not target.exists():errors.append(f'{name}: missing {value}')
        elif u.fragment and target.suffix=='.html' and target in pages:
            if not pages[target].find(id=unquote(u.fragment)):errors.append(f'{name}: missing anchor {value}')
        if node.name=='img' and not node.get('alt'):errors.append(f'{name}: image without alt')
        if node.name=='img' and target.is_file() and '/assets/manual/figures/' in target.as_posix():
            digest=hashlib.sha256(target.read_bytes()).hexdigest()[:12]
            if parse_qs(u.query).get('v') != [digest]:
                errors.append(f'{name}: stale or missing figure content version: {value}')
    for pre in soup.select('main .highlight pre'):
        # Usage blocks restate the signature; they are not calls to check.
        heading=pre.find_previous(['h2','h3'])
        if heading is None or heading.get('id')!='usage': blocks.append((name,pre.get_text()))
    switch=soup.select_one('#language-switch')
    if not switch:errors.append(f'{name}: missing language switch')
    else:
        counterpart=(path.parent/urlsplit(switch['href']).path).resolve()
        if counterpart not in pages:errors.append(f'{name}: missing translated counterpart')
        elif {h['id'] for h in soup.select('main h2[id], main h3[id]')} != {h['id'] for h in pages[counterpart].select('main h2[id], main h3[id]')}:
            errors.append(f'{name}: section anchors do not match the translated page')
    if not name.startswith('zh/'):
        main=soup.select_one('main')
        if re.search('[\u3400-\u9fff]',main.get_text()):errors.append(f'{name}: untranslated Chinese in English content')
        if re.search('[\u3000-\u303f\uff00-\uffef]',main.get_text()):errors.append(f'{name}: full-width punctuation in English content')
for language in ['','zh/']:
    for f in functions:
        path=SITE/(language+'reference/'+f['name']+'.html')
        soup=pages.get(path)
        if not soup:errors.append(f'Missing function {path}');continue
        documented={x.get_text(strip=True) for x in soup.select('table.arguments tbody th')}
        if documented!=set(f['defaults'] or {}):errors.append(f'{path}: argument coverage mismatch')
        for section in ['usage','arguments','value','details','examples','see-also']:
            if not soup.find(id=section):errors.append(f'{path}: missing {section}')
    search=json.loads((SITE/(language+'search.json')).read_text())
    for entry in search:
        if not (SITE/language/entry['url']).exists():errors.append('Invalid search entry '+entry['url'])

# Parse all displayed code and verify explicitly named arguments to direct
# public-function calls. This does not execute expensive models or file writes.
with tempfile.TemporaryDirectory(prefix='alscl-doc-code-') as directory:
    directory=Path(directory)
    for i,(name,code) in enumerate(blocks):
        (directory/f'{i:04d}.R').write_text(code)
    script=r'''
args <- commandArgs(trailingOnly=TRUE)
env <- new.env(parent=baseenv())
for (p in list.files("R", "\\.R$", full.names=TRUE)) {
 for (x in parse(p)) {
  if (is.call(x) && is.symbol(x[[1]]) && as.character(x[[1]]) %in% c("<-","=") &&
      is.symbol(x[[2]]) && is.call(x[[3]]) && (identical(x[[3]][[1]], as.name("function")) ||
      as.character(x[[2]]) %in% c(".acl_renamed_arguments", ".acl_deprecated_functions"))) eval(x,env)
 }
}
renamed <- get(".acl_renamed_arguments", env); deprecated_functions <- get(".acl_deprecated_functions", env)
check_call <- function(x) {
 if (!is.call(x) && !is.expression(x)) return(invisible(NULL))
 if (is.call(x) && is.symbol(x[[1]])) {
  name <- as.character(x[[1]])
  if (name %in% names(deprecated_functions))
   stop(name, ": deprecated function; use ", deprecated_functions[[name]])
  if (exists(name,env,inherits=FALSE)) {
   f <- get(name,env); formal <- names(formals(f)); actual <- names(as.list(x)[-1])
   former <- intersect(actual, names(renamed[[name]]))
   if (length(former)) stop(name, ": former argument name(s): ", paste(former, collapse=", "),
    "; use ", paste(renamed[[name]][former], collapse=", "))
   if (!"..." %in% formal && length(actual)) {
    invalid <- setdiff(actual[nzchar(actual)],formal)
    if (length(invalid)) stop(name, ": unknown named argument(s): ",paste(invalid,collapse=", "))
   }
  }
 }
 for (i in seq_along(x)) {
  if (identical(x[[i]],quote(expr=))) next
  check_call(x[[i]])
 }
 invisible(NULL)
}
failed <- FALSE
files <- list.files(args[1],"\\.R$",full.names=TRUE)
stopifnot(length(files) > 0, exists("run_acl", env, inherits=FALSE))
for (p in files) {
 tryCatch({ expr <- parse(p); check_call(expr) },error=function(e) {
  cat(basename(p),conditionMessage(e),"\n"); failed <<- TRUE
 })
}
if (failed) quit(status=1)
'''
    test_script=directory/'check.R';test_script.write_text(script)
    # Keep the checker outside the folder scanned for examples.
    examples=directory/'examples';examples.mkdir()
    for file in directory.glob('[0-9]*.R'):file.rename(examples/file.name)
    result=subprocess.run(['Rscript',str(test_script),str(examples)],cwd=ROOT,capture_output=True,text=True)
    if result.returncode:
        for line in result.stdout.splitlines():
            match=re.match(r'(\d+)\.R (.*)',line)
            errors.append((blocks[int(match[1])][0]+': '+match[2]) if match else line)
        if result.stderr:errors.append(result.stderr)

# Relative links and anchors inside the Markdown manuals, the README and NEWS.
def slug(text):
    text = re.sub(r'`|\*|\[|\]|\(.*?\)', '', text).strip().lower()
    text = re.sub(r'[^\w\u3000-\u9fff\- ]', '', text)
    return text.replace(' ', '-')
markdown = [p for p in (ROOT/'docs').glob('*.md')] + [ROOT/'README.md', ROOT/'NEWS.md']
anchors = {}
for md in markdown:
    text = md.read_text()
    ids = set(re.findall(r'<(?:a|h[1-6])[^>]*\bid="([^"]+)"', text))
    ids |= {slug(h) for h in re.findall(r'^#{1,6} +(.+?)\s*$', text, re.M)}
    anchors[md] = ids
link_count = 0
for md in markdown:
    text = re.sub(r'```.*?```', '', md.read_text(), flags=re.S)
    for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^)\s]+)\)', text) + re.findall(r'!\[[^\]]*\]\(([^)\s]+)\)', text):
        u = urlsplit(target)
        if u.scheme or u.netloc or target.startswith('#') and not u.path: 
            if target.startswith('#') and unquote(u.fragment) not in anchors[md]:
                errors.append(f'{md.relative_to(ROOT)}: missing anchor {target}')
            continue
        link_count += 1
        file = (md.parent/unquote(u.path)).resolve()
        if not file.exists():
            errors.append(f'{md.relative_to(ROOT)}: missing {target}')
        elif u.fragment and file in anchors and unquote(u.fragment) not in anchors[file]:
            errors.append(f'{md.relative_to(ROOT)}: missing anchor {target}')
if errors:
    print('\n'.join(errors));raise SystemExit(f'{len(errors)} documentation check(s) failed')
print(f'PASS: {len(pages)} pages; bilingual counterparts; local links/assets/anchors; {len(functions)} functions and all arguments per language; {len(blocks)} R code blocks parsed, direct named calls and former names checked; {link_count} Markdown manual links resolved.')
