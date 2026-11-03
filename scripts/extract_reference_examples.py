#!/usr/bin/env python3
"""Extract the actual bilingual reference setup and example, without building the site."""
import ast
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def reference_examples(names):
    tree = ast.parse((ROOT / 'website/build.py').read_text(encoding='utf-8'))
    required = {'choose', 'code_language', 'example_setup'}
    definitions = [node for node in tree.body
                   if isinstance(node, ast.FunctionDef) and node.name in required]
    if {node.name for node in definitions} != required:
        raise RuntimeError('Website example-generation helpers have changed')
    context = {'re': re}
    exec(compile(ast.Module(body=definitions, type_ignores=[]),
                 'website/build.py', 'exec'), context)
    pieces = re.split(r'<a id="([^"]+)"></a>',
                      (ROOT / 'docs/FUNCTION_REFERENCE.md').read_text(encoding='utf-8'))
    sections = dict(zip(pieces[1::2], pieces[2::2]))
    examples = []
    for name in names:
        section = sections[name].split('**示例 / Example:**', 1)[1]
        code = re.search(r'```r\n(.*?)```', section, re.S)[1]
        for lang in ('en', 'zh'):
            examples.append(dict(name=name, language=lang,
                                 setup=context['example_setup'](name, lang),
                                 example=context['code_language'](code, lang)))
    return examples


if __name__ == '__main__':
    print(json.dumps(reference_examples(sys.argv[1:] or ['plot_compare_growth']),
                     ensure_ascii=True))
