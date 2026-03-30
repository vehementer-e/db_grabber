import json
from pathlib import Path


def load_json(path: Path) -> dict:
    """
    Загрузить JSON из файла.
    """
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data: dict) -> None:
    """
    Сохранить JSON в файл.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def save_md(path: Path, content: str) -> None:
    """
    Сохранить markdown в файл.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")