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
"""

from __future__ import annotations

import os

# ---------- SQL Server connection ----------
SERVER = os.getenv("DOCSGEN_SERVER", r"C3-DWH-DB01.carm.corp")
DEFAULT_DATABASE = os.getenv("DOCSGEN_DEFAULT_DB", "Reports")

# ---------- output ----------
OUT_DIR = os.getenv("DOCSGEN_OUT_DIR", "build/docs/autogen_docs")
DEFAULT_SCHEMA = os.getenv("DOCSGEN_DEFAULT_SCHEMA", "dbo")

# ---------- links ----------
GITLAB_BASE = os.getenv("DOCSGEN_GITLAB_BASE", "https://gitlab.carm.corp/dwh_team/dbs/pts/")
GITLAB_MID = os.getenv("DOCSGEN_GITLAB_MID", "/-/blob/master/docs/autogen_docs/")
