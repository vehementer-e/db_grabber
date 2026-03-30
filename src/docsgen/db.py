from __future__ import annotations

import time
import pyodbc

from docsgen.config import (
    SERVER,
    DEFAULT_DATABASE,
    CONNECT_TIMEOUT,
    CONNECT_RETRIES,
    CONNECT_RETRY_BASE_DELAY,
    USE_ENV_DB_CREDENTIALS,
    DB_HOST,
    DB_PORT,
    DB_USER,
    DB_PASSWORD,
)


def _conn_str(database: str | None = None) -> str:
    db = database or DEFAULT_DATABASE

    if USE_ENV_DB_CREDENTIALS:
        server = f"{DB_HOST},{DB_PORT}"
        return (
            "DRIVER={ODBC Driver 17 for SQL Server};"
            f"SERVER={server};"
            f"DATABASE={db};"
            f"UID={DB_USER};"
            f"PWD={DB_PASSWORD};"
            "Encrypt=yes;"
            "TrustServerCertificate=yes;"
        )

    return (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={SERVER};"
        f"DATABASE={db};"
        "Trusted_Connection=yes;"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )


def _should_retry(exc: Exception) -> bool:
    # Под твой кейс: 08001 + prelogin delay / login timeout
    if isinstance(exc, pyodbc.OperationalError):
        msg = " ".join(str(x) for x in exc.args).lower()
        return ("08001" in msg) or ("login timeout" in msg) or ("prelogin" in msg) or ("timeout" in msg)
    return False


def get_connection(database: str | None = None) -> pyodbc.Connection:
    last_exc: Exception | None = None
    for attempt in range(CONNECT_RETRIES + 1):
        try:
            return pyodbc.connect(_conn_str(database), timeout=CONNECT_TIMEOUT)
        except Exception as e:
            last_exc = e
            if attempt >= CONNECT_RETRIES or not _should_retry(e):
                raise
            time.sleep(CONNECT_RETRY_BASE_DELAY * (2 ** attempt))
    raise last_exc  # pragma: no cover


def fetchall(sql: str, params=None, *, database: str | None = None) -> list[dict]:
    with get_connection(database) as conn:
        cur = conn.cursor()
        cur.execute(sql, params or ())
        cols = [c[0] for c in cur.description] if cur.description else []
        rows = cur.fetchall()
        return [dict(zip(cols, row)) for row in rows]


def fetchone(sql: str, params=None, *, database: str | None = None):
    with get_connection(database) as conn:
        cur = conn.cursor()
        cur.execute(sql, params or ())
        row = cur.fetchone()
        return row[0] if row else None
