CREATE TABLE feature_usage_fact AS

SELECT  u.usage_id,
        s.account_id,
        u.subscription_id AS subscription_key,
        u.usage_date,
        u.feature_name,
        u.usage_count,
        u.usage_duration_secs,
        u.error_count,
        u.is_beta_feature

FROM    feature_usage u

--retrieve account_id
INNER JOIN subscriptions s
ON s.subscription_id = u.subscription_id

--only keep usage records that occur on or after the signup date but on or before the churned date
INNER JOIN account_dim a
ON a.account_id = s.account_id
AND a.signup_date <= u.usage_date
AND IFNULL(a.churned_date, '2999-12-31') >= u.usage_date;