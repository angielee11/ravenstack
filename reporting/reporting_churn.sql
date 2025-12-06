--Monthly Usage Churn

WITH totals AS (

SELECT DATE_TRUNC(signup_date, MONTH) AS signup_month,
        COUNT(account_id) AS total_accounts
FROM    account_dim
GROUP BY ALL
),

usage AS (

SELECT  DATE_TRUNC(a.signup_date, MONTH) AS signup_month,
        CEILING(DATE_DIFF(m.reporting_month, a.signup_date, DAY)/30) AS month_number,
        COUNT(DISTINCT CASE WHEN usage_flag IS FALSE THEN m.account_id END) AS usage_churn

FROM reporting_monthly m 

INNER JOIN account_dim a
ON a.account_id = m.account_id

GROUP BY ALL
ORDER BY 1,2

)


SELECT usage.signup_month,
        month_number,
        total_accounts,
        usage_churn,
        ROUND(SAFE_DIVIDE(usage_churn, total_accounts), 2) AS usage_churn_rate

FROM usage

INNER JOIN totals ON totals.signup_month = usage.signup_month;
