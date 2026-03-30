from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Tuple


@dataclass(frozen=True)
class RunResult:
    ok: bool
    returncode: int
    stdout: str
    stderr: str
    cmd: List[str]


def chunks(items: List[Tuple[str, str]], size: int) -> Iterable[List[Tuple[str, str]]]:
    for i in range(0, len(items), size):
        yield items[i : i + size]


def log_failure(
    fail_log: Path,
    *,
    obj_type: str,
    db: str,
    schema: str,
    name: str,
    err: str,
) -> None:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    fail_log.parent.mkdir(parents=True, exist_ok=True)

    with fail_log.open("a", encoding="utf-8") as f:
        f.write(f"{ts}\n")
        f.write(f"type={obj_type}\n")
        f.write(f"db={db}\n")
        f.write(f"object={schema}.{name}\n")
        f.write("error:\n")
        f.write(err.rstrip() + "\n")
        f.write("-" * 80 + "\n")
