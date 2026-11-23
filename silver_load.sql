TRUNCATE TABLE silver.transactions;

insert into silver.transactions(
    transaction_date,
    payment_method,
    category,
    description,
    inr_amount,
    transaction_type,
    amount,
    currency
)
select 
to_timestamp(transaction_date,'MM/DD/YYYY HH24:MI'),
payment_method,
coalesce(nullif(category,''),'Unknown'),
expense_item,
inr_amount::numeric,
transaction_type,
amount::numeric,
currency
from bronze.expenses_raw;

