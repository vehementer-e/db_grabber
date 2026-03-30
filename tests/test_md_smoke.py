from pathlib import Path

from docsgen.io import load_json
from docsgen.render.md import render_md


def test_md_smoke_procedure(tmp_path: Path):
    json_path = Path("build/json/procedures/collection.reportCollectionNonPaymentReason.json")
    assert json_path.exists(), f"Missing file: {json_path}"

    doc = load_json(json_path)
    md = render_md(doc)

    out_path = tmp_path / "alpha.md"
    out_path.write_text(md, encoding="utf-8")

    assert out_path.exists()
    assert out_path.stat().st_size > 0, "Generated MD is empty"

def test_md_smoke_table(tmp_path: Path):
    json_path = Path("build/json/tables/collection.CollectionNonPaymentReasonFullDetail.json")
    assert json_path.exists(), f"Missing file: {json_path}"

    doc = load_json(json_path)
    md = render_md(doc)

    out_path = tmp_path / "outta.md"
    out_path.write_text(md, encoding="utf-8")

    assert out_path.exists()
    assert out_path.stat().st_size > 0, "Generated MD is empty"



def test_md_smoke_function(tmp_path: Path):
    json_path = Path("build/json/functions/dbo.tvf_getBranchByCode.json")
    assert json_path.exists(), f"Missing file: {json_path}"

    doc = load_json(json_path)
    md = render_md(doc)

    out_path = tmp_path / "omega.md"
    out_path.write_text(md, encoding="utf-8")

    assert out_path.exists()
    assert out_path.stat().st_size > 0, "Generated MD is empty"