--Usage Activation - first usage date from signup

WITH totals AS (

SELECT DATE_TRUNC(signup_date, MONTH) AS signup_month,
        COUNT(account_id) AS total_accounts
FROM    account_dim
GROUP BY ALL
),

usage_activation AS (

SELECT  DATE_TRUNC(a.signup_date, MONTH) AS signup_month,
        DATE_DIFF(a.first_usage_date, a.signup_date, MONTH) AS month_number,
        COUNT(DISTINCT m.account_id) AS usage_activated

FROM reporting_monthly m 

INNER JOIN account_dim a
ON a.account_id = m.account_id
AND first_usage_date IS NOT NULL

GROUP BY ALL
ORDER BY 1,2

)


SELECT usage_activation.signup_month,
        month_number,
        total_accounts,
        usage_activated,
        SUM(usage_activated) OVER (PARTITION BY usage_activation.signup_month ORDER BY month_number ASC) AS running_usage_activated,
        ROUND(SAFE_DIVIDE(SUM(usage_activated) OVER (PARTITION BY usage_activation.signup_month ORDER BY month_number ASC), total_accounts), 2) AS usage_activated_rate

FROM usage_activation

INNER JOIN totals ON totals.signup_month = usage_activation.signup_month