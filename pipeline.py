import csv
import os
from pathlib import Path
from dotenv import load_dotenv
import psycopg
import logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
Base_Dir=Path(__file__).resolve().parent

load_dotenv(Base_Dir / os.getenv("ENV_FILE", ".env"))

def run_sql_file(conn,path):
    sql_text=Path(path).read_text(encoding='utf-8')

    with conn.cursor() as cur:
        cur.execute(sql_text)

def load_bronze(conn,file_path):
    with open(file_path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)
        rows = list(reader)
        logging.info("Read %d rows from CSV file.", len(rows))

    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE bronze.expenses_raw;")
        cur.executemany(
            "INSERT INTO bronze.expenses_raw VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
            rows
        )
    return len(rows)

def get_count(conn,query):
    with conn.cursor() as cur:
        cur.execute(query)
        return cur.fetchone()[0]

def check_count(conn,query,expected,label):
    db_count = get_count(conn, query)
    if db_count != expected:
            raise ValueError(f"Expected {expected} rows for {label}, but got {db_count}")
    logging.info("%s passed: %s", label, db_count)
    return db_count


def main():
    logging.info("Connecting to host: %s", os.getenv("DB_HOST"))
    conn=psycopg.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    sslmode=os.getenv("DB_SSLMODE", "prefer"),)
    
    csv_path=os.getenv("CSV_PATH")
    csv_path =Base_Dir / csv_path
    try:
   
        bronze_count=load_bronze(conn,csv_path)
        logging.info("Bronze loaded: %s rows", bronze_count)
        check_count(conn,"select count(*) from bronze.expenses_raw;",bronze_count,"Bronze Row Count")
        run_sql_file(conn,Base_Dir / "silver_load.sql")
        silver_count=check_count(conn,"SELECT COUNT(*) FROM silver.transactions;", bronze_count, "silver.transactions")
        check_count(conn,"""
        select count(*) 
        from silver.transactions 
        where currency='INR'
        and inr_amount<>amount""",0,"Silver INR Mismatches")

        check_count(conn,"""
        select count(*) 
        from silver.transactions
        where transaction_type not in('Income','Expense') 
        or transaction_type is null""",0,"Silver invalid transaction_type")

        run_sql_file(conn, Base_Dir / "gold_load.sql")
        gold_count=check_count(conn, "SELECT COUNT(*) FROM gold.fact_transaction;", silver_count, "gold.fact_transaction")
        
        check_count(conn,"""
        SELECT
        (SELECT COALESCE(SUM(inr_amount), 0)
         FROM silver.transactions)
        -
        (SELECT COALESCE(SUM(inr_amount), 0)
         FROM gold.fact_transaction);""",0,"Silver vs Gold INR sum difference")   
         
        conn.commit()
        logging.info("Pipeline finished")
    except Exception:
        if conn:
            conn.rollback()
        logging.exception("Pipeline failed, rolled back")
        raise
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()