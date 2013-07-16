-- Create (and drop) analysis table
DROP TABLE analysis; CREATE TABLE analysis 
SELECT 
  noncritical.`license address`, 
  noncritical.`name of business`, 
  critical.`count` AS critical_count,
  noncritical.`count` AS noncritical_count,
  (critical.`count` + noncritical.`count`) AS total_violations,
  (critical.`count` / (critical.`count` + noncritical.`count`) * 100) AS critical_percentage
FROM 
  (SELECT `license address`, `name of business`, COUNT(`critical`) AS count 
    FROM critical GROUP BY `license address`, `name of business`) AS critical,
  (SELECT `license address`, `name of business`, COUNT(`critical`) AS count 
    FROM noncritical GROUP BY `license address`, `name of business`) AS noncritical
WHERE
  critical.`license address` = noncritical.`license address`
  AND critical.`name of business` = noncritical.`name of business`
ORDER BY
  critical_percentage DESC,
  critical_count DESC
  

-- Averages
-- total: 15.68822023
-- percent: 30.68050602
SELECT
  'Average total violations',
  AVG(total_violations)
FROM
  analysis
UNION
SELECT
  'Average percentage is critical',
  AVG(critical_percentage)
FROM
  analysis