CREATE TABLE reporting_monthly AS

WITH subs AS (

SELECT  d.reporting_month, 
        s.account_id, 
        s.account_status, 
        s.plan_tier, 
        s.mrr_amount

FROM    date_dim d

INNER JOIN  subscription_fact s
ON  d.date_key BETWEEN s.effective_start_date AND s.effective_end_date

QUALIFY ROW_NUMBER() OVER (PARTITION BY account_id, reporting_month ORDER BY effective_start_date DESC) = 1
ORDER BY account_id, reporting_month

)

SELECT  subs.reporting_month, 
        subs.account_id, 
        subs.account_status, 
        subs.plan_tier, 
        subs.mrr_amount,
        MAX(CASE WHEN f.usage_id IS NOT NULL THEN TRUE ELSE FALSE END) AS usage_flag

FROM    subs

LEFT JOIN feature_usage_fact f
ON      f.account_id = subs.account_id
AND     DATE_TRUNC(f.usage_date, MONTH) = subs.reporting_month

GROUP BY ALL
ORDER BY subs.account_id, subs.reporting_month

