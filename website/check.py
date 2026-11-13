#!/usr/bin/env python3
"""Check generated links, bilingual coverage, argument coverage and R syntax."""
from pathlib import Path
from urllib.parse import urlsplit, unquote, parse_qs
import hashlib
import json
import csv
import re
import subprocess
import sys
import tempfile
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parents[1]
SITE=ROOT/'_site'
# Report problems even when the console encoding cannot show a character.
for stream in (sys.stdout,sys.stderr):
    if hasattr(stream,'reconfigure'):stream.reconfigure(errors='replace')
errors=[]
for command in [
    [sys.executable, str(ROOT/'scripts/test_manual_builder.py')],
    [sys.executable, str(ROOT/'scripts/build_manual.py'), '--check'],
    [sys.executable, str(ROOT/'scripts/build_wiki.py'), '--check'],
    ['Rscript', str(ROOT/'scripts/test_tutorial_workflows.R')],
]:
    result=subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
    if result.returncode:
        errors.append('Documentation workflow check failed: '+command[1]+'\n'+result.stdout+result.stderr)
    else:
        output = (result.stdout + result.stderr).strip()
        if output:
            print(output)
version=re.search(r'^Version: (.+)$',(ROOT/'DESCRIPTION').read_text(encoding='utf-8'),re.M)[1].strip()
# Between releases main carries a development version: a fourth component of
# 9000 or more after the last release, for example 2.4.3.9000 after 2.4.3.
# The site and manuals describe that version; 'Latest release' and the first
# numbered NEWS entry name the release.
components=re.split(r'[.-]',version)
development=len(components)>3 and components[3].isdigit() and int(components[3])>=9000
release='.'.join(components[:3]) if development else version
minimum_r=re.search(r'R \(>= ([0-9.]+)\)',(ROOT/'DESCRIPTION').read_text(encoding='utf-8'))[1]
minimum_r=minimum_r[:-2] if minimum_r.endswith('.0') else minimum_r
for language,readme in [('en','README.md'),('zh','README.zh-CN.md')]:
    for name in [readme,f'website/content/{language}/articles/getting-started.md']:
        requirement=re.search(r'R ([0-9]+\.[0-9]+(?:\.[0-9]+)?)', (ROOT/name).read_text(encoding='utf-8'))
        if not requirement or requirement[1]!=minimum_r:
            errors.append(f'{name}: minimum R version must match DESCRIPTION ({minimum_r})')
pages={p:BeautifulSoup(p.read_text(encoding='utf-8'),'html.parser') for p in SITE.rglob('*.html')}
functions=json.loads((ROOT/'website/.build/api/functions.json').read_text(encoding='utf-8'))
# Cover legacy package-help images as well as the website's bundled figures.
with (ROOT/'docs/results/manual-figure-inventory.csv').open(encoding='utf-8',newline='') as handle:
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
    search=json.loads((SITE/(language+'search.json')).read_text(encoding='utf-8'))
    for entry in search:
        if not (SITE/language/entry['url']).exists():errors.append('Invalid search entry '+entry['url'])

# The reference index, the counts quoted in the manuals and the version strings.
reference=(ROOT/'docs/FUNCTION_REFERENCE.md').read_text(encoding='utf-8')
gallery=(ROOT/'docs/PLOT_GALLERY.md').read_text(encoding='utf-8')
deprecated=dict(re.findall(r'(\w+) *= *"(\w+)"',re.search(r'\.acl_deprecated_functions *<- *c\((.*?)\)',(ROOT/'R/deprecations.R').read_text(encoding='utf-8'),re.S)[1]))
# The Markdown manuals get the same code checks as the site, so that hand-written
# reference text cannot keep a former function or argument name. The book and
# the Wiki are generated from these files.
manual_sources=[p for p in sorted((ROOT/'docs').glob('*.md')) if p.name!='BOOK.md']+[ROOT/'README.md',ROOT/'README.zh-CN.md']
inline=[]
for md in manual_sources:
    name=md.relative_to(ROOT).as_posix(); text=md.read_text(encoding='utf-8')
    for code in re.findall(r'^```r[ \t]*\n(.*?)^```',text,re.S|re.M):
        # A usage block restates the signature as "name (arguments)"; it is not a call.
        if not re.match(r'[\w.]+ \(',code):blocks.append((name,code))
    # A deprecated function may be named in its own reference section and index line only.
    elsewhere=text
    for former,current in deprecated.items():
        elsewhere=re.sub(rf'<a id="{former}"></a>.*?(?=<a id="|\Z)','',elsewhere,flags=re.S)
        elsewhere=re.sub(rf'^- \[{former}\]\(#{former}\).*$','',elsewhere,flags=re.M)
        if re.search(rf'\b{former}\b',elsewhere):
            errors.append(f'{name}: deprecated function {former} is named outside its own reference section; use {current}')
    # Calls quoted in running text; those that are not complete R are skipped by the checker.
    prose=re.sub(r'^```.*?^```','',elsewhere,flags=re.S|re.M)
    inline+=[(name,span) for span in re.findall(r'`([A-Za-z.][\w.]*\([^`\n]*\))`',prose)]
for f in functions:
    if f'- [{f["name"]}](#{f["name"]})' not in reference:errors.append(f'docs/FUNCTION_REFERENCE.md: index lacks {f["name"]}')
n_functions=len(functions)
n_plots=len([f for f in functions if f['name'].startswith('plot_') and f['name'] not in deprecated])
n_figures=len(re.findall(r'^## \d+\. ',gallery,re.M))
quoted=[('docs/FUNCTION_REFERENCE.md',reference,[f'对应 ALSCL {version}，覆盖 **{n_functions} 个公开函数**',f'All **{n_functions} exported functions** of ALSCL {version}']),
        ('README.md',(ROOT/'README.md').read_text(encoding='utf-8'),[f'Latest release: {release}',f'all {n_functions} functions',f'{n_figures} figures with their code']),
        ('README.zh-CN.md',(ROOT/'README.zh-CN.md').read_text(encoding='utf-8'),[f'最新版本：{release}',f'{n_functions} 个函数的参考',f'{n_figures} 张示例图']),
        ('docs/PLOT_GALLERY.md',gallery,[f'**{n_figures} 张图，覆盖 {n_plots} 个公开绘图函数及主要类型。{n_figures} figures covering all {n_plots} public plotting functions and major variants.**']),
        ('website/content/en/index.md',(ROOT/'website/content/en/index.md').read_text(encoding='utf-8'),[f'ALSCL {version}']),
        ('website/content/zh/index.md',(ROOT/'website/content/zh/index.md').read_text(encoding='utf-8'),[f'ALSCL {version}'])]
for name,text,needles in quoted:
    for needle in needles:
        if needle not in text:errors.append(f'{name}: expected {needle.strip()!r}')
for name,level in [('NEWS.md','#'),('website/content/en/news.md','##'),('website/content/zh/news.md','##')]:
    text=(ROOT/name).read_text(encoding='utf-8')
    numbered=list(re.finditer(rf'^{level} ALSCL (\d\S*)',text,re.M))
    # A development version may have its own numbered heading above the release.
    if development and numbered and numbered[0][1]==version:numbered=numbered[1:]
    if not numbered or numbered[0][1]!=release:errors.append(f'{name}: the first release entry is not {release}')
    elif development and not re.search(rf'^{level} (Unreleased|未发布|ALSCL \(development version\)|ALSCL {re.escape(version)})\s*$',text[:numbered[0].start()],re.M):
        errors.append(f'{name}: DESCRIPTION has the development version {version}, so the changes since {release} need an "Unreleased" heading above the {release} entry')
    elif not development and re.search(rf'^{level} (Unreleased|未发布|ALSCL \(development version\))\s*$',text[:numbered[0].start()],re.M):
        errors.append(f'{name}: unreleased changes are listed above {release}; use a development version such as {release}.9000 in DESCRIPTION, or give them the heading of the new release')

# Parse all displayed code and verify explicitly named arguments to direct
# public-function calls. This does not execute expensive models or file writes.
with tempfile.TemporaryDirectory(prefix='alscl-doc-code-') as directory:
    directory=Path(directory)
    examples=directory/'examples';examples.mkdir()
    quoted=directory/'inline';quoted.mkdir()
    for i,(name,code) in enumerate(blocks):
        (examples/f'{i:04d}.R').write_text(code,encoding='utf-8')
    for i,(name,code) in enumerate(inline):
        (quoted/f'{i:04d}.R').write_text(code,encoding='utf-8')
    script=r'''
args <- commandArgs(trailingOnly=TRUE)
env <- new.env(parent=baseenv())
for (p in list.files("R", "\\.R$", full.names=TRUE)) {
 for (x in parse(p, encoding="UTF-8")) {
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
 tryCatch({ expr <- parse(p, encoding="UTF-8"); check_call(expr) },error=function(e) {
  cat(basename(p),conditionMessage(e),"\n"); failed <<- TRUE
 })
}
# Calls quoted in running text: check those that parse, skip fragments.
for (p in list.files(args[2],"\\.R$",full.names=TRUE)) {
 expr <- tryCatch(parse(p, encoding="UTF-8"), error=function(e) NULL)
 if (is.null(expr)) next
 tryCatch(check_call(expr),error=function(e) {
  cat("inline",basename(p),conditionMessage(e),"\n"); failed <<- TRUE
 })
}
if (failed) quit(status=1)
'''
    test_script=directory/'check.R';test_script.write_text(script,encoding='utf-8')
    # The checker stays outside the folders scanned for examples.
    result=subprocess.run(['Rscript',str(test_script),str(examples),str(quoted)],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    if result.returncode:
        for line in result.stdout.splitlines():
            match=re.match(r'(inline )?(\d+)\.R (.*)',line)
            if not match:errors.append(line)
            elif match[1]:errors.append(inline[int(match[2])][0]+': `'+inline[int(match[2])][1]+'`: '+match[3])
            else:errors.append(blocks[int(match[2])][0]+': '+match[3])
        if result.stderr:errors.append(result.stderr)

# Relative links and anchors inside the Markdown manuals, the README and NEWS.
def slug(text):
    text = re.sub(r'`|\*|\[|\]|\(.*?\)', '', text).strip().lower()
    text = re.sub(r'[^\w\u3000-\u9fff\- ]', '', text)
    return text.replace(' ', '-')
markdown = [p for p in (ROOT/'docs').glob('*.md')] + [ROOT/'README.md', ROOT/'README.zh-CN.md', ROOT/'NEWS.md']
anchors = {}
for md in markdown:
    text = md.read_text(encoding='utf-8')
    ids = set(re.findall(r'<(?:a|h[1-6])[^>]*\bid="([^"]+)"', text))
    ids |= {slug(h) for h in re.findall(r'^#{1,6} +(.+?)\s*$', text, re.M)}
    anchors[md] = ids
link_count = 0
for md in markdown:
    text = re.sub(r'```.*?```', '', md.read_text(encoding='utf-8'), flags=re.S)
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
print(f'PASS: {len(pages)} pages; bilingual counterparts; local links/assets/anchors; {len(functions)} functions and all arguments per language; {len(blocks)} R code blocks parsed (site and Markdown manuals) and {len(inline)} calls quoted in text screened, direct named calls and former names checked; {link_count} Markdown manual links resolved; reference index, quoted counts and version strings verified.')
