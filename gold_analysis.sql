SELECT
    c.category_name,
    SUM(f.inr_amount) AS total_spent
FROM gold.fact_transaction AS f
JOIN gold.dim_category AS c
    ON f.category_id = c.category_id
WHERE f.transaction_type = 'Expense'
GROUP BY c.category_name
ORDER BY total_spent DESC;

SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.inr_amount) AS total_spent
FROM gold.fact_transaction AS f
JOIN gold.dim_date AS d
    ON f.date_key = d.date_key
WHERE f.transaction_type = 'Expense'
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;


select p.payment_method_name, count(f.transaction_id) as transaction_count,sum(inr_amount) as total_amount
from gold.fact_transaction f
join gold.dim_payment_method p
on f.payment_id=p.payment_id
group by p.payment_method_name
order by transaction_count desc;




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
            ),
            0
        ) AS daily_expense,

        COUNT(f.transaction_id) AS transaction_count

    FROM gold.dim_date AS d

    LEFT JOIN gold.fact_transaction AS f
        ON d.date_key = f.date_key

    GROUP BY
        d.full_date
)

SELECT
    COUNT(*) AS total_calendar_days,

    COUNT(*) FILTER (
        WHERE transaction_count > 0
    ) AS active_days,

    SUM(daily_expense) AS total_expenses,

    ROUND(
        AVG(daily_expense),
        2
    ) AS average_spending_all_days,

    ROUND(
        AVG(daily_expense) FILTER (
            WHERE transaction_count > 0
        ),
        2
    ) AS average_spending_active_days

FROM daily_spending;


WITH daily_net AS (
    SELECT
        d.full_date AS transaction_date,

        SUM(
            CASE
                WHEN f.transaction_type = 'Income'
                    THEN f.inr_amount
                WHEN f.transaction_type = 'Expense'
                    THEN -f.inr_amount
                ELSE 0
            END
        ) AS daily_net_amount

    FROM gold.dim_date AS d

    LEFT JOIN gold.fact_transaction AS f
        ON d.date_key = f.date_key

    GROUP BY
        d.full_date
)

SELECT
    transaction_date,
    daily_net_amount,

    SUM(daily_net_amount) OVER (
        ORDER BY transaction_date
    ) AS running_balance

FROM daily_net
ORDER BY transaction_date;
