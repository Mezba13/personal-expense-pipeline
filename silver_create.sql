drop table if exists silver.transactions;
-- 

create table silver.transactions(
transaction_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
transaction_date timestamp,
payment_method text,
category text,
description text,
inr_amount numeric not null,
transaction_type text,
amount numeric,
currency text
);