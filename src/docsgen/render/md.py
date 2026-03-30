from __future__ import annotations
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, select_autoescape

from docsgen.render.links import object_doc_url

TEMPLATES_DIR = Path(__file__).parent / "templates"

_env = Environment(
    loader=FileSystemLoader(TEMPLATES_DIR),
    autoescape=select_autoescape(disabled_extensions=("md",), default_for_string=False),
    trim_blocks=True,
    lstrip_blocks=True,
)

def render_md(doc: dict) -> str:
    templates_dir = Path(__file__).parent / "templates"
    env = Environment(loader=FileSystemLoader(str(templates_dir)))
    env.filters["doc_url"] = object_doc_url

    obj_type = doc["object_type"]
    template = env.get_template(f"{obj_type}.md.j2")
    return template.render(**doc)
