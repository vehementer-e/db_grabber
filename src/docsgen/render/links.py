from urllib.parse import quote
from docsgen.config import GITLAB_BASE, GITLAB_MID

TYPE_MAP = {
    "procedure": "procedures",
    "procedures": "procedures",
    "function": "functions",
    "functions": "functions",
    "table": "tables",
    "tables": "tables",
}



def object_doc_url(db: str, obj_type: str, schema: str, name: str) -> str:
    db_part = quote(db.lower())
    obj_part = TYPE_MAP.get(str(obj_type), str(obj_type))
    schema_part = quote(str(schema or ""))
    file_part = quote(f"{str(name)}.md")

    return f"{GITLAB_BASE}{db_part}{GITLAB_MID}{obj_part}/{schema_part}/{file_part}"


# print(object_doc_url("reports", "procedure", "dbo", "name"))