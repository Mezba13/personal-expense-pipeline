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


def main():
    conn=None
    try:
        logging.info("Connecting to host: %s", os.getenv("DB_HOST"))
        conn=psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        sslmode=os.getenv("DB_SSLMODE", "prefer"),)

        logging.info("Database connection established successfully.")
        with conn.cursor() as cur:
            cur.execute("Create schema if not exists bronze;")
            cur.execute("Create schema if not exists silver;")
            cur.execute("Create schema if not exists gold;")
            logging.info("Schemas created successfully.")
   
        run_sql_file(conn,Base_Dir / "bronze_create.sql")
        logging.info("Bronze database created successfully.")
   
        run_sql_file(conn, Base_Dir / "silver_create.sql")
        logging.info("Silver database created successfully.")

        run_sql_file(conn, Base_Dir / "gold_create.sql")
        logging.info("Gold database created successfully.")
        
         
        conn.commit()
        logging.info("Database setup completed successfully.")
    except Exception:
        if conn:
            conn.rollback()
        logging.exception("Database setup failed, rolled back")
        raise
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    main()