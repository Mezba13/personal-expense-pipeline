import psycopg
import os
from dotenv import load_dotenv

load_dotenv()
with psycopg.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT current_database();")
        result = cur.fetchone()
        print(result)
        