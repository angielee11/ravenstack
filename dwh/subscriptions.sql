/* PREP DATA TO TRANSFORM INTO FACT TABLE */

DROP TABLE stg_sub IF EXISTS;

CREATE TABLE stg_sub AS

SELECT  subscription_id AS pk,
        account_id,
        start_date AS subscription_start_date,
        end_date AS subscription_end_date,
        plan_tier,
        LAG(plan_tier) OVER (PARTITION BY account_id ORDER BY start_date ASC) AS previous_plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        billing_frequency,
        auto_renew_flag,
        --date periods for when the record is relevant
        start_date AS effective_start_date,
        COALESCE(LEAD(start_date) OVER (PARTITION BY account_id ORDER BY start_date ASC), '2999-12-31') AS effective_end_date

FROM    subscriptions;

/* CREATE COLUMN SHOWING ACCOUNT STATUS */

DROP TABLE IF EXISTS stg_sub_status;

CREATE TABLE stg_sub_status AS
-- normalise churned rows, refer to readme for modelling decision made
WITH churned AS (

SELECT  pk,
        account_id,
        'active' AS account_status,
        plan_tier,
        previous_plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        billing_frequency,
        auto_renew_flag,
        subscription_start_date AS effective_start_date

FROM    stg_sub

WHERE   effective_end_date = '2999-12-31'
AND     subscription_end_date IS NOT NULL

UNION ALL 

SELECT  CONCAT(pk,2) AS pk,
        account_id,
        'churned' AS account_status,
        plan_tier,
        previous_plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        billing_frequency,
        auto_renew_flag,
        subscription_end_date AS effective_start_date

FROM    stg_sub

WHERE   effective_end_date = '2999-12-31'
AND     subscription_end_date IS NOT NULL

),

churned_fct AS (

SELECT  pk,
        account_id,
        account_status,
        plan_tier,
        previous_plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        billing_frequency,
        auto_renew_flag,
        effective_start_date,
        COALESCE(LEAD(effective_start_date) OVER (PARTITION BY account_id ORDER BY effective_start_date ASC), '2999-12-31') AS effective_end_date

FROM    churned
)
--rest of the data
SELECT  pk,
        account_id,
        --if no previous paying record then trial else active
        CASE WHEN IFNULL(LAG(mrr_amount) OVER (PARTITION BY account_id ORDER BY effective_start_date ASC),0) = 0 AND mrr_amount = 0 THEN  'trial' ELSE 'active' END AS account_status,
        plan_tier
        plan_tier,
        previous_plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        billing_frequency,
        auto_renew_flag,
        effective_start_date,
        effective_end_date

FROM    stg_sub

WHERE   NOT (effective_end_date = '2999-12-31' AND subscription_end_date IS NOT NULL)

UNION ALL
--churned accounts CTE
SELECT  pk,
        account_id,
        account_status,
        plan_tier,
        previous_plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        billing_frequency,
        auto_renew_flag,
        effective_start_date,
        effective_end_date

FROM    churned_fct;

/* ADJUST DIM FLAGS AND CORRECT REVENUE AMOUNT FOR POST ACTIVATION TRIALS */

DROP TABLE IF EXISTS subscription_fact;

CREATE TABLE subscription_fact AS

SELECT  pk,
        account_id,
        account_status,
        plan_tier,
        previous_plan_tier,
        seats,
        -- if recurring revenue = 0 and active account then take previous record's revenue amt
        CASE WHEN account_status = 'active' AND mrr_amount = 0 THEN LAG(mrr_amount) OVER (PARTITION BY account_id ORDER BY effective_start_date)
             ELSE mrr_amount END AS mrr_amount,
        CASE WHEN account_status = 'active' AND arr_amount = 0 THEN LAG(arr_amount) OVER (PARTITION BY account_id ORDER BY effective_start_date)
             ELSE arr_amount END AS arr_amount,
        -- upgrade/downgrade flags assuming tier order is Basic, Pro, Enterprise
        CASE WHEN previous_plan_tier IN ('Enterprise','Pro') AND plan_tier = 'Basic' THEN TRUE
              WHEN previous_plan_tier = 'Enterprise' AND plan_tier = 'Pro' THEN TRUE ELSE FALSE
        END AS downgrade_flag,
        CASE WHEN previous_plan_tier IN ('Basic','Pro') AND plan_tier = 'Enterprise' THEN TRUE
              WHEN previous_plan_tier = 'Basic' AND plan_tier = 'Pro' THEN TRUE ELSE FALSE
        END AS upgrade_flag,
        billing_frequency,
        auto_renew_flag,
        effective_start_date,
        effective_end_date,
        --helper column for getting current state
        CASE WHEN effective_end_date = '2999-12-31' THEN TRUE ELSE FALSE END AS current_record_flag
FROM stg_sub_status;