CREATE TABLE account_dim AS

SELECT  a.account_id,
        a.account_name,
        a.industry,
        a.country,
        a.referral_source,
        MAX(CASE WHEN account_status = 'trial' THEN TRUE ELSE FALSE END) AS trialled,
        MIN(s.effective_start_date) AS signup_date,
        MIN(CASE WHEN account_status = 'active' THEN s.effective_start_date END) AS activated_date,
        MIN(usage_date) AS first_usage_date,
        MAX(usage_date) AS last_usage_date,
        MIN(CASE WHEN account_status = 'churned' THEN s.effective_start_date END) AS churned_date

FROM    accounts a

LEFT JOIN subscription_fact s
ON s.account_id = a.account_id

LEFT JOIN feature_usage_fact u
ON u.account_id = a.account_id

GROUP BY ALL;