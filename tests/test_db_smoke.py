from docsgen.config import DATABASE
from docsgen.db import get_connection, fetchone


def test_db_connection_smoke():
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT 1")
        assert cur.fetchone()[0] == 1
    finally:
        conn.close()


def test_db_name_smoke():
    assert fetchone("SELECT DB_NAME()") == DATABASE