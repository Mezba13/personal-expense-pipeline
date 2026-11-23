DROP TABLE IF EXISTS gold.fact_transaction;
DROP TABLE IF EXISTS gold.dim_date;
DROP TABLE IF EXISTS gold.dim_payment_method;
DROP TABLE IF EXISTS gold.dim_category;

create table gold.dim_category(
category_id integer generated always as identity primary key,
category_name text not null unique
);

create table gold.dim_payment_method (
payment_id integer generated always as identity primary key,
payment_method_name text not null unique
);


CREATE TABLE gold.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name TEXT NOT NULL,
	is_weekend BOOLEAN NOT NULL
);

CREATE TABLE gold.fact_transaction (
    transaction_id INTEGER PRIMARY KEY,

    date_key INTEGER NOT NULL
        REFERENCES gold.dim_date(date_key),

    category_id INTEGER NOT NULL
        REFERENCES gold.dim_category(category_id),

    payment_id INTEGER NOT NULL
        REFERENCES gold.dim_payment_method(payment_id),

    transaction_timestamp TIMESTAMP NOT NULL,

    description TEXT,

    transaction_type TEXT NOT NULL
        CHECK (transaction_type IN ('Income', 'Expense')),

    inr_amount NUMERIC NOT NULL,

    amount NUMERIC,

    currency TEXT
);