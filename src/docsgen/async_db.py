from __future__ import annotations

import asyncio
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Callable, TypeVar

import pyodbc

from docsgen.config import (
    DEFAULT_DATABASE,
    CONNECT_TIMEOUT,
    CONNECT_RETRIES,
    CONNECT_RETRY_BASE_DELAY,
)
from docsgen.db import _conn_str  # используем тот же conn string

T = TypeVar("T")


class AsyncODBCExecutor:
    """
    Async-friendly wrapper around blocking pyodbc using a bounded ThreadPoolExecutor.

    Key idea:
      - max_connections == max worker threads
      - each thread keeps its own persistent connection (thread-local)
      - no connect/close per object
    """

    def __init__(self, *, max_connections: int = 10):
        if max_connections < 1:
            raise ValueError("max_connections must be >= 1")
        self.max_connections = max_connections
        self._executor = ThreadPoolExecutor(
            max_workers=max_connections,
            thread_name_prefix="docsgen-db",
        )
        self._local = threading.local()
        self._closed = False

    def _should_retry(self, exc: Exception) -> bool:
        if isinstance(exc, pyodbc.OperationalError):
            msg = " ".join(str(x) for x in exc.args).lower()
            return ("08001" in msg) or ("login timeout" in msg) or ("prelogin" in msg) or ("timeout" in msg)
        return False

    def _connect(self, database: str) -> pyodbc.Connection:
        last_exc: Exception | None = None
        for attempt in range(CONNECT_RETRIES + 1):
            try:
                return pyodbc.connect(_conn_str(database), timeout=CONNECT_TIMEOUT)
            except Exception as e:
                last_exc = e
                if attempt >= CONNECT_RETRIES or not self._should_retry(e):
                    raise
                time.sleep(CONNECT_RETRY_BASE_DELAY * (2 ** attempt))
        raise last_exc  # pragma: no cover

    def _get_conn(self, database: str) -> pyodbc.Connection:
        conns = getattr(self._local, "conns", None)
        if conns is None:
            conns = {}
            setattr(self._local, "conns", conns)

        conn = conns.get(database)
        if conn is None:
            conn = self._connect(database)
            conns[database] = conn
        return conn

    def _run(self, database: str, fn: Callable[..., T], *args, **kwargs) -> T:
        conn = self._get_conn(database)
        return fn(conn, *args, **kwargs)

    async def run(self, database: str | None, fn: Callable[..., T], *args, **kwargs) -> T:
        if self._closed:
            raise RuntimeError("AsyncODBCExecutor is closed")
        db = database or DEFAULT_DATABASE
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(self._executor, self._run, db, fn, *args, **kwargs)

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        self._executor.shutdown(wait=False, cancel_futures=False)
