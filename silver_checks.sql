SELECT COUNT(*), MIN(transaction_id), MAX(transaction_id) FROM silver.transactions;
SELECT transaction_id, transaction_date, description
FROM silver.transactions
WHERE description IN ('Brownie', 'Metro', 'To barath');
select min(transaction_date), max(transaction_date) from silver.transactions;

select * 
from silver.transactions
where description='Brownie' 
and transaction_type='Expense' 
and inr_amount=50;

select count(*) 
from silver.transactions
where currency = 'INR' 
and inr_amount <> amount;

select count(*)
from silver.transactions
where inr_amount <= 0;

select count(*)
from silver.transactions
where transaction_type not in ('Income', 'Expense');