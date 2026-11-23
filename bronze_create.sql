
DROP TABLE IF EXISTS bronze.expenses_raw;

CREATE TABLE bronze.expenses_raw (
    transaction_date TEXT,
    payment_method TEXT,
    category TEXT,
    subcategory TEXT,
    expense_item TEXT,
    inr_amount TEXT,
    transaction_type TEXT,
    empty_note TEXT,
    amount TEXT,
    currency TEXT,
    raw_account TEXT
);
