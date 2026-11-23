import csv
import psycopg
import os
from dotenv import load_dotenv
load_dotenv() 
host = os.getenv("DB_HOST")
port = os.getenv("DB_PORT")
dbname = os.getenv("DB_NAME")
user = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")  

file_path=r'C:\Users\Lenovo\Desktop\DE\Personal Project\personal_expense\expense_data_1.csv'

with open(file_path, newline="", encoding="utf-8") as f:
    reader = csv.reader(f)
    header = next(reader)   
    rows = list(reader)
    print(len(rows), "rows read from CSV file.")

with psycopg.connect(host=host, port=port, dbname=dbname, user=user, password=password) as conn:
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE bronze.expenses_raw;")
        cur.executemany(
            "INSERT INTO bronze.expenses_raw VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
            rows
        )
        cur.execute("SELECT COUNT(*) FROM bronze.expenses_raw;")  
        db_count=cur.fetchone()[0]
        print("Row count after loading data into bronze.expenses_raw table:", db_count)
        if db_count != len(rows):
            raise Exception("Row count mismatch after loading data into bronze.expenses_raw table.")
print(f"Successfully loaded {len(rows)} rows.")