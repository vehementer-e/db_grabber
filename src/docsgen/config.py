"""Project configuration.

Historically this project kept most settings hard-coded.
For batch generation, CI and local runs it is more convenient to allow
overrides via environment variables.

Supported environment variables:
- DOCSGEN_SERVER: SQL Server host
- DOCSGEN_DEFAULT_DB: default database name
- DOCSGEN_OUT_DIR: base output directory
- DOCSGEN_DEFAULT_SCHEMA: default schema name
- DOCSGEN_GITLAB_BASE: base GitLab URL used for links
- DOCSGEN_GITLAB_MID: path segment used for links

DB connection variables for SQL authentication mode:
- DB_HOST
- DB_PORT
- DB_USER
- DB_PASSWORD
"""

from __future__ import annotations

import os

# ---------- SQL Server connection ----------
SERVER = os.getenv("DOCSGEN_SERVER", r"C3-DWH-DB01.carm.corp")
DEFAULT_DATABASE = os.getenv("DOCSGEN_DEFAULT_DB", "Reports")
DATABASE = DEFAULT_DATABASE  # backward compatibility

# if all auth env vars are provided, switch from Trusted Connection to SQL auth
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
USE_ENV_DB_CREDENTIALS = all([DB_HOST, DB_PORT, DB_USER, DB_PASSWORD])

# ---------- output ----------
OUT_DIR = os.getenv("DOCSGEN_OUT_DIR", "build/docs/autogen_docs")
PROCEDURE_SOURCES_DIR = os.getenv("DOCSGEN_PROC_SRC_DIR", "build/sql/procedures")
JOB_SOURCES_DIR = os.getenv("DOCSGEN_JOB_SRC_DIR", "build/sql/jobs")
DEFAULT_SCHEMA = os.getenv("DOCSGEN_DEFAULT_SCHEMA", "dbo")

# ---------- links ----------
GITLAB_BASE = os.getenv("DOCSGEN_GITLAB_BASE", "https://gitlab.carm.corp/dwh_team/dbs/pts/")
GITLAB_MID = os.getenv("DOCSGEN_GITLAB_MID", "/-/blob/master/docs/autogen_docs/")

# ---------- connection retry ----------
CONNECT_TIMEOUT = int(os.getenv("DOCSGEN_CONNECT_TIMEOUT", "10"))
CONNECT_RETRIES = int(os.getenv("DOCSGEN_CONNECT_RETRIES", "3"))
CONNECT_RETRY_BASE_DELAY = float(os.getenv("DOCSGEN_CONNECT_RETRY_BASE_DELAY", "0.8"))
