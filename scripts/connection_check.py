import pyodbc

SERVER = r"C3-DWH-DB01.carm.corp"
DATABASE = "dwh2"

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

print(conn_str)

with pyodbc.connect(conn_str, timeout=5) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT SUSER_SNAME();")
        print(cur.fetchone()[0])