-- Overall churn rate, and broken down by plan and acquisition channel
-- Technique: conditional aggregation (CASE inside SUM)

-- Overall
SELECT
  SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS churned,
  COUNT(*) AS total,
  ROUND(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions;

-- By plan
SELECT
  p.plan_name,
  ROUND(SUM(CASE WHEN s.status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY churn_rate_pct DESC;

-- By acquisition channel
SELECT
  c.acquisition_channel,
  ROUND(SUM(CASE WHEN s.status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions s
JOIN customers c ON s.customer_id = c.customer_id
GROUP BY c.acquisition_channel
ORDER BY churn_rate_pct DESC;
