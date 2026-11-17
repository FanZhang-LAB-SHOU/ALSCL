#!/usr/bin/env python3
"""Record the documentation figures, the script that draws each and its hash.

Covers every PNG and SVG file under docs/figures, the folder the website copies.
This inventories files and rendering sources; it does not infer gridlines from pixels.
Run from any directory after the figure scripts, then run website/check.py.
"""
from pathlib import Path
import csv
import hashlib

root = Path(__file__).resolve().parents[1]
rows = []
for path in sorted((root / 'docs/figures').rglob('*')):
    if path.suffix.lower() not in ('.png', '.svg'):
        continue
    rel = path.relative_to(root).as_posix()
    if '/own-data-example/' in rel:
        source = 'scripts/refresh_manual_figures.R'
    elif '/sparse-panels/' in rel:
        source = 'scripts/plot_sparse_panels.R'
    elif '/ytf/' in rel:
        source = 'scripts/ytf_workflow.R'
    elif '/cases/' in rel:
        source = 'scripts/case_studies.R'
    elif '/whiting-case/' in rel:
        source = 'scripts/whiting_case_report.R'
    elif '/workflows/' in rel:
        source = ('scripts/model_validation.R'
                  if path.name in ('fitted-simulation.png', 'hindcast-predictions.png', 'self-test.png')
                  else 'scripts/assessment_workflow.R')
    elif '/speed/' in rel:
        source = 'scripts/plot_speed_benchmark.R'
    elif '/parallel/' in rel:
        source = 'scripts/plot_parallel_benchmark.R'
    elif '/palettes/' in rel:
        source = 'scripts/palette_swatches.R'
    else:
        raise ValueError(f'Unclassified manual image: {rel}')
    rows.append(dict(path=rel, source=source,
                     sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
with (root / 'docs/results/manual-figure-inventory.csv').open('w', newline='') as out:
    writer = csv.DictWriter(out, fieldnames=['path', 'source', 'sha256'], lineterminator='\n')
    writer.writeheader()
    writer.writerows(rows)
print(f'Inventoried {len(rows)} figures.')
