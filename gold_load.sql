TRUNCATE TABLE
    gold.dim_category,
    gold.dim_payment_method,
    gold.dim_date,
    gold.fact_transaction
RESTART IDENTITY;

insert into gold.dim_category (category_name)
select distinct category
from silver.transactions
where category is not null
order by category;

insert into gold.dim_payment_method (payment_method_name)
select distinct payment_method
from silver.transactions
where payment_method is not null
order by payment_method;

select * from gold.dim_payment_method;
select * from gold.dim_category;



INSERT INTO gold.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
	is_weekend
)
SELECT
    TO_CHAR(calendar_date, 'YYYYMMDD')::INTEGER,
    calendar_date,
    EXTRACT(YEAR FROM calendar_date)::INTEGER,
    EXTRACT(QUARTER FROM calendar_date)::INTEGER,
    EXTRACT(MONTH FROM calendar_date)::INTEGER,
    TO_CHAR(calendar_date, 'FMMonth'),
    EXTRACT(DAY FROM calendar_date)::INTEGER,
    EXTRACT(ISODOW FROM calendar_date)::INTEGER,
    TO_CHAR(calendar_date, 'FMDay'),
	EXTRACT(ISODOW FROM calendar_date) IN (6, 7)
FROM GENERATE_SERIES(
     (SELECT MIN(transaction_date)::DATE
     FROM silver.transactions),
    (SELECT MAX(transaction_date)::DATE
     FROM silver.transactions),
    INTERVAL '1 day'
) AS calendar_date;

SELECT * FROM gold.dim_date limit 5;

SELECT MIN(full_date), MAX(full_date) FROM gold.dim_date;
select * from gold.dim_date where full_date='2022-03-02';

insert into gold.fact_transaction (
    transaction_id,
    date_key,
    category_id,
    payment_id,
    transaction_timestamp,
    description,
    transaction_type,
    inr_amount,
    amount,
    currency
)
select
    s.transaction_id,
    d.date_key,
    c.category_id,
    p.payment_id,
    s.transaction_date,
    s.description,
    s.transaction_type,
    s.inr_amount,
    s.amount,
    s.currency
	
from silver.transactions s

join gold.dim_category c
on s.category=c.category_name

join gold.dim_date d
on s.transaction_date::date=d.full_date

join gold.dim_payment_method p
on s.payment_method=p.payment_method_name;