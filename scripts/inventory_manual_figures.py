#!/usr/bin/env python3
"""Record manual asset coverage after rendering and visually reviewing figures.

This inventories files and rendering sources; it does not infer gridlines from pixels.
Run from any directory after the figure scripts, then run website/check.py.
"""
from pathlib import Path
import csv
import hashlib

root = Path(__file__).resolve().parents[1]
rows = []
for folder in ['docs/figures', 'man/figures']:
    for path in sorted((root / folder).rglob('*')):
        if path.suffix.lower() not in ('.png', '.svg'):
            continue
        rel = path.relative_to(root).as_posix()
        kind = 'plot'
        if path.name == 'ACLlogo.png':
            kind, source = 'logo', 'existing logo'
        elif path.name.startswith('excel_'):
            kind, source = 'worksheet', 'input table illustration (cell borders retained)'
        elif rel.startswith('man/figures/') or '/own-data-example/' in rel:
            source = 'scripts/refresh_manual_figures.R'
        elif '/ytf/' in rel:
            source = 'scripts/ytf_workflow.R'
        elif '/cases/' in rel:
            source = 'scripts/case_studies.R'
        elif '/speed/' in rel:
            source = 'scripts/plot_speed_benchmark.R'
        elif '/parallel/' in rel:
            source = 'scripts/plot_parallel_benchmark.R'
        elif path.name == 'convergence-2.2.2.png':
            source = 'scripts/plot_convergence_222.R'
        else:
            raise ValueError(f'Unclassified manual image: {rel}')
        rows.append(dict(path=rel, kind=kind, source=source,
                         sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
with (root / 'docs/results/manual-figure-inventory.csv').open('w', newline='') as out:
    writer = csv.DictWriter(out, fieldnames=['path', 'kind', 'source', 'sha256'], lineterminator='\n')
    writer.writeheader()
    writer.writerows(rows)
print(f'Inventoried {len(rows)} assets: {sum(r["kind"] == "plot" for r in rows)} plot files.')
