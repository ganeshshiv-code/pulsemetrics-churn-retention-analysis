-- Cohort retention: what % of each signup-month cohort is still active at
-- 0, 1, 2, ... months after signup. Uses a recursive CTE to generate month
-- offsets, then a window function to normalize each cohort against its
-- own starting size (since raw counts aren't comparable across cohorts
-- of different sizes).

WITH RECURSIVE month_offsets AS (
  SELECT 0 AS offset_num
  UNION ALL
  SELECT offset_num + 1 FROM month_offsets WHERE offset_num < 30
),
tenure AS (
  SELECT
    subscription_id, customer_id,
    DATE_FORMAT(start_date, '%Y-%m-01') AS cohort_month,
    TIMESTAMPDIFF(MONTH, start_date, COALESCE(end_date, '2025-06-30')) AS tenure_months
  FROM subscriptions
),
retention AS (
  SELECT t.cohort_month, mo.offset_num, COUNT(*) AS retained
  FROM tenure t
  JOIN month_offsets mo ON mo.offset_num <= t.tenure_months
  GROUP BY t.cohort_month, mo.offset_num
)
SELECT
  cohort_month,
  offset_num,
  retained,
  FIRST_VALUE(retained) OVER (PARTITION BY cohort_month ORDER BY offset_num) AS cohort_size,
  ROUND(retained * 100.0 / FIRST_VALUE(retained) OVER (PARTITION BY cohort_month ORDER BY offset_num), 1) AS retention_pct
FROM retention
ORDER BY cohort_month, offset_num;
