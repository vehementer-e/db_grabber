from __future__ import annotations
from pathlib import Path
from typing import Iterable
from ..render.md_renderer import render_procedure
from ..io.writer import write_text

def _out_path_for(doc: dict, out_dir: str | Path) -> Path:
    """
    Формирует имя файла:
    - если есть schema и name -> <schema>.<name>.md
    - иначе: title.md
    - иначе: random-like резервное имя (не должно понадобиться в норме)
    """
    out_dir = Path(out_dir)
    schema = (doc.get("schema") or "").strip()
    name = (doc.get("name") or "").strip()
    title = (doc.get("title") or "").strip()
    if schema and name:
        fname = f"{schema}.{name}.md"
    elif title:
        fname = f"{title}.md"
    else:
        fname = "document.md"
    return out_dir / fname

def run_mvp(docs: Iterable[dict], out_dir: str | Path) -> int:
    """Мини-конвейер: dict -> render -> write."""
    count = 0
    for d in docs:
        md = render_procedure(d)
        out_path = _out_path_for(d, out_dir)
        write_text(out_path, md)
        count += 1
    return count
