# Personal Expense Data Pipeline

An end-to-end data engineering project using Python and PostgreSQL to transform raw personal financial transactions into an analytical data model.

## Overview

This project processes personal income and expense records from a CSV dataset using a Bronze-Silver-Gold data architecture. Python and PostgreSQL handle data ingestion, transformation, validation, and analytical modelling. The resulting data model supports analysis of spending by category, monthly spending trends, payment methods, average daily expenses, and running balance.

## Architecture

The pipeline follows a three-layer architecture:

- **Bronze Layer:** Loads the original CSV records into PostgreSQL, preserving all 11 source columns as TEXT.
- **Silver Layer:** Cleans and transforms the raw records, converts dates and numeric values into appropriate data types, and retains the fields required for analysis.
- **Gold Layer:** Organises the transformed data into a star schema for analytical queries.

### Gold Star Schema

The Gold layer consists of three dimension tables and one fact table.

| Table | Description |
|---|---|
| `gold.dim_date` | Date attributes such as year, quarter, month, day, weekday, and weekend indicator. |
| `gold.dim_category` | Unique transaction categories. |
| `gold.dim_payment_method` | Unique payment methods. |
| `gold.fact_transaction` | Transaction-level facts connected to the dimension tables. |

**Fact table grain:** One row represents one individual transaction.

The fact table stores transaction details, including the date key, category ID, payment ID, transaction type, INR amount, original amount, and currency.

## Technology Stack

- **Programming Language:** Python
- **Database:** PostgreSQL
- **Database Connectivity:** Psycopg 3
- **Environment Configuration:** python-dotenv
- **Data Ingestion:** Python CSV module
- **Transformation and Analytics:** SQL
- **Version Control:** Git and GitHub

## Project Structure

```text
personal-expense-pipeline/
│
├── bronze_create.sql
├── silver_create.sql
├── gold_create.sql
│
├── silver_load.sql
├── gold_load.sql
├── gold_analysis.sql
├── silver_checks.sql
│
├── setup.py
├── pipeline.py
├── load_bronze.py
├── test_connection.py
│
├── requirements.txt
├── .gitignore
├── .env
│
└── README.md
```

The CSV dataset and `.env` file are kept outside the public repository.

## How to Run

### Prerequisites

- Python 3
- PostgreSQL
- Git

### 1. Clone the repository

```bash
git clone https://github.com/Mezba13/personal-expense-pipeline.git

cd personal-expense-pipeline
```

### 2. Create a virtual environment

```bash
python -m venv .venv
```

Activate it on Windows:

```bash
.venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure environment variables

Create a `.env` file in the project root:

```env
DB_HOST=localhost
DB_PORT=5433
DB_NAME=finance_de
DB_USER=postgres
DB_PASSWORD=your_password

CSV_PATH=data/expense_data_1.csv
```

Replace the example values with your PostgreSQL connection details. Keep `.env` private and never commit database credentials.

### 5. Add the dataset

Place the source CSV file in the project directory according to the `CSV_PATH` setting.

The dataset is not included in this repository. You will need to obtain the original CSV from the source application used to record the transactions.

### 6. Set up the database

Create an empty PostgreSQL database, then execute:

```bash
python setup.py
```

This creates the Bronze, Silver, and Gold schemas and their respective tables.

**Important:** The creation scripts contain `DROP TABLE IF EXISTS` statements. Running setup again will recreate the tables and remove their existing data.

### 7. Execute the pipeline

```bash
python pipeline.py
```

The pipeline performs the following operations:

1. Reads the CSV file and loads records into Bronze.
2. Transforms Bronze records into Silver.
3. Performs Silver data-quality checks.
4. Loads the Gold dimensions and fact table.
5. Validates Gold row counts and reconciles INR amounts.
6. Commits the transaction if all validations pass.

If an operation or validation fails, the transaction is rolled back.

### Using Neon PostgreSQL

The project can also connect to a Neon PostgreSQL database.

1. Create a Neon project and database.
2. Obtain the PostgreSQL connection details.
3. Update the database settings in `.env`.
4. Set `DB_SSLMODE=require`.
5. Keep `CSV_PATH` pointing to your local CSV file.
6. Run `python setup.py`.
7. Run `python pipeline.py`.

The same Python and SQL scripts are used for both local PostgreSQL and Neon.

## Design Decisions

### 1. Store raw Bronze data as TEXT

**Decision:** All 11 source columns are stored as TEXT in Bronze.

**Reason:** This preserves the original CSV values and avoids premature type-conversion errors. Data types are applied during Silver transformation.

### 2. Drop unused columns

**Decision:** `subcategory` and `empty_note` are excluded from Silver because they contain no meaningful data. `raw_account` is also excluded because it duplicates the original `amount` value.

**Evidence to verify:** Check that `subcategory` and `empty_note` contain no non-empty values and that `raw_account` matches `amount` after numeric conversion.

### 3. Use INR for financial analysis

**Decision:** `inr_amount` is used for financial aggregation instead of mixing original currency amounts.

**Reason:** The dataset contains 276 INR transactions and one USD transaction. The source application provides an INR-converted amount for the USD transaction.

### 4. Maintain transaction-level fact grain

**Decision:** The Gold fact table stores one row per transaction rather than pre-aggregated daily totals.

**Reason:** Transaction-level data preserves descriptions, categories, payment methods, and transaction types, allowing different analytical aggregations later.

### 5. Include inactive dates in dim_date

**Decision:** The date dimension includes all 102 calendar days between the minimum and maximum transaction dates, including days without transactions.

**Reason:** There are 87 active days. Keeping the remaining 15 inactive days makes it possible to calculate average spending across the complete calendar period, including zero-spending days.

### 6. Avoid an artificial parent-category hierarchy

**Decision:** Categories are stored as individual values without a parent-category dimension.

**Reason:** The source dataset does not provide a reliable parent-category relationship. Introducing one would require assumptions not supported by the data.

### 7. Keep amounts positive

**Decision:** Income and expense amounts remain positive, while `transaction_type` identifies their meaning.

**Reason:** This preserves the source amount values and separates transaction classification from the amount.

**Analytical consideration:** Every financial aggregation must distinguish Income from Expense. Net balance calculations must add income and subtract expenses.

### 8. Make data reloads repeatable

**Decision:** Each layer is truncated and reloaded instead of appending duplicate records.

**Implementation:**
- Bronze: `TRUNCATE TABLE bronze.expenses_raw`
- Silver: `TRUNCATE TABLE silver.transactions`
- Gold: Truncates dimension and fact tables and reloads them in dependency order.

### 9. Use a single database transaction

**Decision:** The complete pipeline uses one database connection and commits only after all loading and validation steps succeed.

**Reason:** If a validation fails, the exception handler rolls back the transaction, preventing partially loaded data across the layers.

## Data Quality Checks

The pipeline enforces six checks:

| # | Validation | Expected Result |
|---|---|---:|
| 1 | Bronze row count matches the number of CSV records | 277 |
| 2 | Silver row count matches Bronze | 277 |
| 3 | Gold fact row count matches Silver | 277 |
| 4 | INR amount mismatches in Silver | 0 |
| 5 | Invalid or NULL transaction types in Silver | 0 |
| 6 | Difference between Silver and Gold `SUM(inr_amount)` | 0 |

The pipeline compares row counts between layers instead of relying on hardcoded row counts for its validation logic.

## Results

The processed dataset contains 277 transactions.

### Financial Summary

| Metric | Amount |
|---|---:|
| Total Income | ₹54,754 |
| Total Expenses | ₹59,024 |
| Combined Transaction Amount | ₹113,778 |
| Net Balance | -₹4,270 |

The combined transaction amount represents the sum of positive income and expense amounts. Net balance is calculated as income minus expenses.

### 1. Expense Analysis by Category

```sql
SELECT
    c.category_name,
    SUM(f.inr_amount) AS total_spent
FROM gold.fact_transaction AS f
JOIN gold.dim_category AS c
    ON f.category_id = c.category_id
WHERE f.transaction_type = 'Expense'
GROUP BY c.category_name
ORDER BY total_spent DESC;
```

**Insight:** Food accounts for ₹24,502.48, approximately 41.51% of the total ₹59,024 expenses.

### 2. Income and Expenses by Payment Method

```sql
SELECT
    p.payment_method_name,

    COALESCE(
        SUM(f.inr_amount) FILTER (
            WHERE f.transaction_type = 'Income'
        ), 0
    ) AS total_income,

    COALESCE(
        SUM(f.inr_amount) FILTER (
            WHERE f.transaction_type = 'Expense'
        ), 0
    ) AS total_expenses

FROM gold.fact_transaction AS f
JOIN gold.dim_payment_method AS p
    ON f.payment_id = p.payment_id
GROUP BY p.payment_method_name
ORDER BY total_expenses DESC;
```

**Insight:** This query compares income and expenses separately for each payment method instead of combining both transaction types into one amount.

### 3. Average Daily Spending

```sql
WITH daily_spending AS (
    SELECT
        d.full_date,
        COALESCE(
            SUM(
                CASE
                    WHEN f.transaction_type = 'Expense'
                    THEN f.inr_amount
                    ELSE 0
                END
            ), 0
        ) AS daily_expense,
        COUNT(f.transaction_id) AS transaction_count
    FROM gold.dim_date AS d
    LEFT JOIN gold.fact_transaction AS f
        ON d.date_key = f.date_key
    GROUP BY d.full_date
)
SELECT
    COUNT(*) AS total_calendar_days,

    COUNT(*) FILTER (
        WHERE transaction_count > 0
    ) AS active_days,

    SUM(daily_expense) AS total_expenses,

    ROUND(AVG(daily_expense), 2)
        AS average_spending_all_days,

    ROUND(
        AVG(daily_expense) FILTER (
            WHERE transaction_count > 0
        ), 2
    ) AS average_spending_active_days

FROM daily_spending;
```

**Insight:** Average daily spending is ₹578.67 across all 102 calendar days and ₹678.44 across the 87 active days. Including inactive days provides a more representative calendar-day average.

## Known Limitations

- **Partial months:** The dataset covers 21 November through 2 March. The first and last months are incomplete, so their spending totals should not be compared directly with full months.
- **Transactions involving friends:** Money lent to friends and money returned by friends are classified as expenses and income respectively. This affects income, expense, and net-balance calculations.
- **Other category:** The `Other` category contains 60 transactions and mixes income and expenses, limiting category-level interpretation.
- **USD conversion:** One transaction is recorded in USD. Its INR equivalent was converted by the source application, but the exchange rate and conversion timestamp are unavailable.
- **Opening balance:** The running balance is calculated from the available transactions and assumes a zero opening balance. It does not necessarily represent the actual account balance.
- **Dataset scope:** The analysis is limited to the transactions available in the supplied CSV file.

## Column Mapping

The original CSV fields are mapped to the Bronze table in their source order.

| CSV Column | Bronze Column |
|---|---|
| transaction_date | transaction_date |
| payment_method | payment_method |
| category | category |
| subcategory | subcategory |
| expense_item | expense_item |
| inr_amount | inr_amount |
| transaction_type | transaction_type |
| empty_note | empty_note |
| amount | amount |
| currency | currency |
| raw_account | raw_account |

All 11 source columns are preserved in Bronze. The Silver layer retains the fields required for transaction-level analysis.
