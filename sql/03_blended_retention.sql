-- Blended retention curve: a single business-wide retention % at each month
-- offset, weighted by actual cohort size (NOT a simple average of per-cohort
-- percentages, which would incorrectly give a 22-person cohort the same
-- weight as a 72-person cohort).

WITH RECURSIVE month_offsets AS (
  SELECT 0 AS offset_num
  UNION ALL SELECT offset_num + 1 FROM month_offsets WHERE offset_num < 30
),
tenure AS (
  SELECT subscription_id, customer_id,
    DATE_FORMAT(start_date, '%Y-%m-01') AS cohort_month,
    TIMESTAMPDIFF(MONTH, start_date, COALESCE(end_date, '2025-06-30')) AS tenure_months
  FROM subscriptions
),
retention AS (
  SELECT t.cohort_month, mo.offset_num, COUNT(*) AS retained
  FROM tenure t
  JOIN month_offsets mo ON mo.offset_num <= t.tenure_months
  GROUP BY t.cohort_month, mo.offset_num
),
retention_with_size AS (
  SELECT cohort_month, offset_num, retained,
    FIRST_VALUE(retained) OVER (PARTITION BY cohort_month ORDER BY offset_num) AS cohort_size
  FROM retention
)
SELECT
  offset_num,
  SUM(retained) AS total_retained,
  SUM(cohort_size) AS total_starting,
  ROUND(SUM(retained) * 100.0 / SUM(cohort_size), 1) AS blended_retention_pct
FROM retention_with_size
GROUP BY offset_num
ORDER BY offset_num;
