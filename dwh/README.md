SUBSCRIPTIONS

** Account Subscription relationship **

Although the relationship is theoretically 1 Account to 1 or more Subscriptions, there shouldn't be a new subscription_id every time there are updates to the subscription plan. There also shouldn't be multiple concurrent subscriptions per account (most subscription_ids don't have an end_date).

I have assumed each account only has one subscription and the subscription_id as a primary key to turn this into a fact table.

** End dates **

The end date is supposed to be the churn date, however many of these end dates overlap with one or many successive subscription records for the relevant accounts.

I have assumed each account can only churn once and not reactivate to right-size this task.

The end date is updated to an existing row, so in order to transform this into a fact table, I have normalised the churn records: one row to show the date range of that subscription update and another for the churn date.

** Dimension flags **

is_trial: some accounts seem to go on trial after activating a subscription, have restricted this flag to records where there was no history of mrr_amount above 0. We could assume that post activation trials are part of product led growth where they can try a different plan without changing cost. I have overwritten the $0 MRR with the previous row's.

upgrade/downgrade flags: these did not seem to align with plan tier changes, so they needed to be corrected

** Derived account status column **
trial, active, churned

ACCOUNTS

The signup date didn't seem to match any dates in subscriptions. Trials are recorded in subscriptions so signup date should be sourced from this table too.

Adjusting signup date and bringing in activated and churn dates.

Updated trial flag to align with subscription data.

FEATURE USAGE

Added account_id to make this table easier to query; keep subscription_id for querying slow changing dimensions.

Only kept rows where the usage occurred on or after the signup date and on or before the churned date.

OUT OF SCOPE

I have not modelled churn_events.csv as the churn dates don't align with most of the end dates in subscriptions.csv.

I have also not modelled support_tickets.csv as there was minimal value in terms of churn/retention analysis.


