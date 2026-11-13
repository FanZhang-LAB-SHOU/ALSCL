"""Build the bilingual Wiki book from versioned Markdown. Python standard library only.
从仓库根目录运行 / Run from repo root: python3 scripts/build_wiki.py
Use --check to compare the generated text without writing files.
"""
from pathlib import Path
import re,posixpath,hashlib,argparse,sys
from build_manual import USER_GUIDE,DOCUMENTS
root=Path(__file__).resolve().parents[1]; docs=root/'docs'; out=docs/'wiki'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check', action='store_true', help='Fail on stale outputs without writing files.')
check_only=parser.parse_args().check if __name__ == '__main__' else False
outputs={}
def write_output(path,text):
 outputs[path]=text
base='https://github.com/FanZhang-LAB-SHOU/ALSCL'
version=re.search(r'^Version: (.+)$', (root/'DESCRIPTION').read_text(encoding='utf-8'), re.M)[1]
read=lambda name:(docs/name).read_text(encoding='utf-8')
g=read('USER_GUIDE.md')
sections={}
parts=re.split(r'<a id="([a-z]+)"></a>\n',g)
for i in range(1,len(parts),2):sections[parts[i]]=parts[i+1]
# Strip just the chapter heading; leave code comments and subsections intact.
def no_title(s):return re.sub(r'^#{1,2} [^\n]+\n','',s.strip(),count=1).strip()
def linkify(s,source='docs/USER_GUIDE.md'):
 return re.sub(r']\(([^\s()]*(?:\([^)]*\))?[^\s()]*)\)',lambda m: fix_url(m.group(1),source),s)
def fix_url(url,source):
 if url.startswith(('http:','https:','mailto:','#')):return ']('+url+')'
 path,sep,anchor=url.partition('#'); path=posixpath.normpath(posixpath.join(posixpath.dirname(source),path))
 resolved=root/path
 dest=base+('/tree/main/' if resolved.is_dir() else '/blob/main/')+path
 if resolved.suffix.lower() in ('.png','.svg','.jpg'):dest+='?raw=true&v='+hashlib.sha256(resolved.read_bytes()).hexdigest()[:12]
 return ']('+dest+('#'+anchor if sep else '')+')'
# Map the gallery's numbered sections, keeping function anchors and executable code.
gallery=read('PLOT_GALLERY.md'); marks=list(re.finditer(r'(?m)^## (\d+)\. ',gallery));blocks={}
for i,m in enumerate(marks):
 block=gallery[m.start():marks[i+1].start() if i+1<len(marks) else len(gallery)]
 # trailing anchors belong to the next page and are redundant in the Wiki.
 block=re.sub(r'<a id="[^"]+"></a>\s*','',block)
 blocks[int(m[1])]=block
# Gallery sections of each plot chapter. Sections 42 and 43 are the retrospective
# figures, which chapter 11 already shows from USER_GUIDE.md. A gallery section
# that is neither placed nor listed as omitted stops the build, so that a new
# section cannot be dropped from the Wiki and the book without notice.
gallery_chapters={'08-Population-Plots':list(range(1,19)),'09-Growth-and-Mortality':list(range(19,33)),
 '10-Model-Comparisons':list(range(33,42))+[44]}
gallery_omitted=[42,43]
placed=[n for numbers in gallery_chapters.values() for n in numbers]+gallery_omitted
if len(placed)!=len(set(placed)) or set(placed)!=set(blocks):
 sys.exit('docs/PLOT_GALLERY.md sections and the Wiki chapters disagree. Not assigned in scripts/build_wiki.py: '
  +(', '.join(map(str,sorted(set(blocks)-set(placed)))) or 'none')+'. Assigned but absent from the gallery: '
  +(', '.join(map(str,sorted(set(placed)-set(blocks)))) or 'none')+'. Assigned twice: '
  +(', '.join(map(str,sorted({n for n in placed if placed.count(n)>1}))) or 'none')+'.')
def gallery_chapter(slug):return plot_context+'\n\n'.join(blocks[n] for n in gallery_chapters[slug])
# Keep plot chapters independently runnable after the fitting chapter.
plot_context='''先完成第 04 章的 YTF 拟合，得到输入列表 `x` 和拟合结果 `a`、`b`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。第 11 章建立回溯对象 `ra` 和 `rb`。
First complete chapter 04 to create the input bundle `x` and the fits `a` and `b`. Define `dat <- x$data.CatL`, and load ggplot2 and patchwork. Chapter 11 creates the retrospective objects `ra` and `rb`.

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

'''
chapters=[
('01-Start','安装与第一次拟合 · Install and run a first fit',no_title(sections['start'])),
('02-Theory','模型原理与时间尺度 · Model principles',no_title(sections['theory'])),
('03-Data-and-Excel','准备调查数据 · Prepare your survey data',no_title(sections['excel'])),
('04-Built-in-YTF','理解第一次拟合 · Understand your first fit',no_title(sections['builtin'])),
('05-Simulation','模拟与批量实验 · Simulation',no_title(sections['simulation'])),
('06-Fitting','选择拟合设置 · Choose the fitting settings',no_title(sections['fitting'])),
('07-Diagnostics','判断拟合是否可用 · Judge whether a fit can be used',no_title(sections['diagnostics'])),
('08-Population-Plots','调查与种群图 · Survey and population plots',gallery_chapter('08-Population-Plots')),
('09-Growth-and-Mortality','生长、死亡与残差图 · Growth, mortality and residuals',gallery_chapter('09-Growth-and-Mortality')),
('10-Model-Comparisons','模型比较与真值 · Model comparisons',gallery_chapter('10-Model-Comparisons')),
('11-Retrospectives','回溯分析 · Retrospectives',no_title(sections['retrospective'])),
('12-Case-Studies','年度与季度案例 · Annual and quarterly cases',no_title(read('CASE_STUDIES.md'))),
('13-Colors-and-Export','ggsci 配色与导出 · Colors and export',no_title(read('PLOT_STYLE.md'))),
('14-Function-Reference','全部函数与参数 · Complete function reference',no_title(read('FUNCTION_REFERENCE.md'))),
('15-Reproducibility','复现与故障处理 · Reproducibility and troubleshooting',no_title(read('ADVANCED_WORKFLOWS.md'))),
('16-Assessment-Workflows','评估工作流 · Assessment workflows',no_title(read('ASSESSMENT_WORKFLOWS.md'))),
('17-Model-Validation','模型模拟与预测验证 · Model simulation and prediction checks',no_title(read('MODEL_VALIDATION.md'))),
('18-Worked-Cases','应用案例 · Worked cases',no_title(read('CASES.md')))]
# Every generated page names the files to edit instead. The manuals carry the
# banner of scripts/build_manual.py; it is replaced, because a Wiki page is one step further.
article_pairs=lambda slugs:', '.join('website/content/{en,zh}/articles/'+slug+'.md' for slug in slugs)
guide_source={anchor:article_pairs(slugs) for anchor,slugs in USER_GUIDE}
document_source={name:article_pairs(slugs) for name,_,slugs in DOCUMENTS}
edit_source={'01-Start':guide_source['start'],'02-Theory':guide_source['theory'],'03-Data-and-Excel':guide_source['excel'],
 '04-Built-in-YTF':guide_source['builtin'],'05-Simulation':guide_source['simulation'],'06-Fitting':guide_source['fitting'],
 '07-Diagnostics':guide_source['diagnostics'],'08-Population-Plots':'docs/PLOT_GALLERY.md',
 '09-Growth-and-Mortality':'docs/PLOT_GALLERY.md','10-Model-Comparisons':'docs/PLOT_GALLERY.md',
 '11-Retrospectives':guide_source['retrospective'],'12-Case-Studies':document_source['CASE_STUDIES.md'],
 '13-Colors-and-Export':document_source['PLOT_STYLE.md'],'14-Function-Reference':'docs/FUNCTION_REFERENCE.md',
 '15-Reproducibility':document_source['ADVANCED_WORKFLOWS.md'],'16-Assessment-Workflows':document_source['ASSESSMENT_WORKFLOWS.md'],
 '17-Model-Validation':document_source['MODEL_VALIDATION.md'],'18-Worked-Cases':document_source['CASES.md']}
assert set(edit_source)=={slug for slug,_,_ in chapters}
manual_banner=re.compile(r'<!-- Generated by scripts/build_manual\.py.*?-->\n*')
generated=lambda source:f'<!-- Generated by scripts/build_wiki.py. Edit {source}, then rebuild; do not edit this file. -->'
chapters=[(slug,title,manual_banner.sub('',body)) for slug,title,body in chapters]
# Internal anchor links inherited from a source refer to that source if not on this chapter.
for i,(slug,title,body) in enumerate(chapters):
 if slug=='02-Theory':body=re.sub(r'(?m)^### 1[.]', '### 2.', body)
 body=linkify(body)
 local_ids=set(re.findall(r'<a id="([^"]+)"',body))
 def anchor(m):
  target=m[1]
  if target in local_ids:return m[0]
  if target in sections:return ']('+base+'/blob/main/docs/USER_GUIDE.md#'+target+')'
  return m[0]
 body=re.sub(r']\(#([^)]*)\)',anchor,body)
 nav=[f'[目录 · Contents]({base}/wiki)']
 if i:nav.insert(0,f'[← 上一章 · Previous]({base}/wiki/{chapters[i-1][0]})')
 if i<len(chapters)-1:nav.append(f'[下一章 · Next →]({base}/wiki/{chapters[i+1][0]})')
 navigation=' · '.join(nav)
 content=f'# {i+1:02d} {title}\n\n{generated(edit_source[slug])}\n\n{navigation}\n\n**ALSCL {version} · 简体中文 / English**\n\n'+body+'\n\n---\n\n'+navigation+'\n'
 write_output(out/(slug+'.md'),content)
contents='\n'.join(f'| {i+1:02d} | [{title}]({base}/wiki/{slug}) |' for i,(slug,title,_) in enumerate(chapters))
home=f'''# ALSCL 完整使用手册 · Complete user manual

<img src="{base}/blob/main/ALSCLlogo.png?raw=true" alt="ALSCL logo" align="right" height="140" />

**调查体长数据的种群评估 · Survey catch-at-length stock assessment**

**ALSCL {version} · 简体中文与英文 · {len(chapters)} 章 / chapters**

本手册按主题整理模型原理、数据、拟合、诊断、绘图、模拟与预测验证。第一次使用可按下面的路线完成操作，再查阅需要的技术细节。本手册对应 ALSCL {version}。

This manual groups model principles, data, fitting, diagnostics, plotting, simulation and prediction checks by task. Follow a reading path below, then consult the technical sections you need. The manual describes ALSCL {version}.

[开始使用 · Getting started]({base}/wiki/01-Start) · [仓库主页 · Repository]({base}/tree/main) · [单页书稿 · Single-page book]({base}/blob/main/docs/BOOK.md) · [Excel 示例 · Workbook]({base}/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)

## 选择阅读路线 · Choose a reading path

| 你的任务 / Your task | 建议顺序 / Suggested order |
|---|---|
| 第一次使用 / First run | [安装 / Install]({base}/wiki/01-Start) → [内置拟合 / First fit]({base}/wiki/04-Built-in-YTF) → [诊断 / Diagnostics]({base}/wiki/07-Diagnostics) |
| 拟合自己的数据 / Your own data | [准备数据 / Prepare data]({base}/wiki/03-Data-and-Excel) → [参数与 map / Parameters and maps]({base}/wiki/06-Fitting) → [诊断 / Diagnostics]({base}/wiki/07-Diagnostics) |
| 整理和评估拟合结果 / Work with fitted results | [结果、敏感性与情景 / Results, sensitivity and scenarios]({base}/wiki/16-Assessment-Workflows) |
| 模拟或检验未来预测 / Simulation or prediction checks | [模型验证完整案例 / Model-validation case]({base}/wiki/17-Model-Validation) |
| 选择图形与导出 / Plot and export | [种群图 / Population plots]({base}/wiki/08-Population-Plots) → [配色和导出 / Style and export]({base}/wiki/13-Colors-and-Export) |

这些是按任务选择的入口，不必按章节编号从头读起。需要逐项查参数时使用第 14 章；想用单一语言连续阅读时，访问 [English website](https://fanzhang-lab-shou.github.io/ALSCL/) 或 [简体中文网站](https://fanzhang-lab-shou.github.io/ALSCL/zh/)。

Use these task-based entry points without reading every chapter in numerical order. Chapter 14 is an argument reference. The website provides continuous reading in either language.

## 目录 · Contents

| 章 / Chapter | 内容 / Contents |
|---|---|
{contents}

## 相关链接 · Links

**张帆教授 · Prof. Fan Zhang**

- [个人主页 · Faculty homepage](https://hyxy.shou.edu.cn/2021/0721/c18717a291861/page.htm)
- [GitHub · fzhang-shou](https://github.com/fzhang-shou)
- 邮箱 · Email: [f-zhang@shou.edu.cn](mailto:f-zhang@shou.edu.cn)

**董思宋 · Sisong Dong**

- [GitHub · dongworks97](https://github.com/dongworks97)
- [南极磷虾评估论文 · Antarctic krill assessment (Dong, Zhang & Zhu, 2025)](https://doi.org/10.3354/meps14923)

理论来源 / Reference: Zhang & Cadigan (2022), *Fish and Fisheries* 23,1121–1135. [Paper and Appendix S1](https://doi.org/10.1111/faf.12673).
'''
write_output(out/'Home.md',home.replace('\n\n','\n\n'+generated('scripts/build_wiki.py')+'\n\n',1))
write_output(out/'_Sidebar.md','**ALSCL · 使用手册 / Manual**\n\n'+f'[首页与目录 · Home]({base}/wiki)\n\n'+'\n'.join(f'- [{i+1:02d} {title}]({base}/wiki/{slug})' for i,(slug,title,_) in enumerate(chapters))+f'\n\n[代码与数据 · Code and data]({base}/tree/main)\n')
write_output(out/'_Footer.md',f'[目录 · Contents]({base}/wiki) · [代码 · Code]({base}/tree/main) · [问题反馈 · Issues]({base}/issues)\n\nALSCL {version} · 简体中文 / English · [Zhang & Cadigan (2022)](https://doi.org/10.1111/faf.12673)\n')
book=[home.split('## 目录 · Contents')[0].replace('\n\n','\n\n'+generated('the sources named at the top of each docs/wiki chapter')+'\n\n',1), '## 全书目录 · Book contents','']
book+= [f'- [{i+1:02d} {title}](#chapter-{i+1:02d})' for i,(_,title,_) in enumerate(chapters)]
for i,(slug,title,body) in enumerate(chapters):
 if slug=='02-Theory':body=re.sub(r'(?m)^### 1[.]', '### 2.', body)
 body=linkify(body)
 body=re.sub(r']\(#(theory|builtin|simulation|excel|observations|fitting|diagnostics|plotting|retrospective)\)', lambda m: ']('+base+'/blob/main/docs/USER_GUIDE.md#'+m[1]+')', body)
 book+=['',f'<a id="chapter-{i+1:02d}"></a>',f'## {i+1:02d} {title}','',body]
write_output(docs/'BOOK.md','\n'.join(book)+'\n')
# Preserve the normal generation behavior for any additional Wiki pages too.
for p in out.glob('*.md'):
 outputs.setdefault(p,p.read_text(encoding='utf-8'))
stale=[]
if not check_only:out.mkdir(exist_ok=True)
for p,text in outputs.items():
 text='\n'.join(line.rstrip() for line in text.splitlines()).rstrip()+'\n'
 if check_only:
  if not p.is_file() or p.read_text(encoding='utf-8') != text:stale.append(p.relative_to(root))
 else:p.write_text(text,encoding='utf-8')
if stale:
 print('Stale generated book/Wiki files: '+', '.join(map(str,stale)),file=sys.stderr)
 print('Run python3 scripts/build_wiki.py to regenerate them.',file=sys.stderr)
 sys.exit(1)
print('Checked' if check_only else 'Built',len(chapters),'chapters plus Home, sidebar and footer.')
