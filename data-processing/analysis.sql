-- Create (and drop) analysis table
DROP TABLE IF EXISTS analysis; 

CREATE TABLE analysis 
SELECT 
  business.id,
  business.`license address` AS address, 
  business.`name of business` AS business,
  business.total_violations AS total_violations,
  inspection_count.count AS inspection_count,
  IF(critical_count.count IS NULL, 0, critical_count.count) AS critical_count,
  IF(noncritical_count.count IS NULL, 0, noncritical_count.count) AS noncritical_count
FROM 
  (SELECT CONCAT(`license address`, `name of business`) AS id,
    `license address`, `name of business`, COUNT(*) AS total_violations
    FROM `InspectionHistory-008`
    GROUP BY `license address`, `name of business`) AS business
  LEFT JOIN
    (SELECT CONCAT(`license address`, `name of business`) AS id,
      COUNT(DISTINCT `InspectionID`) AS count
      FROM `InspectionHistory-008`
      GROUP BY `license address`, `name of business`) AS inspection_count
    ON inspection_count.id = business.id
  LEFT JOIN
    (SELECT CONCAT(`license address`, `name of business`) AS id,
      COUNT(`critical`) AS count
      FROM `InspectionHistory-008`
      WHERE `critical` = 'Yes'
      GROUP BY `license address`, `name of business`) AS critical_count
    ON critical_count.id = business.id
  LEFT JOIN
    (SELECT CONCAT(`license address`, `name of business`) AS id,
      COUNT(`critical`) AS count
      FROM `InspectionHistory-008`
      WHERE `critical` <> 'Yes'
      GROUP BY `license address`, `name of business`) AS noncritical_count
    ON noncritical_count.id = business.id
;
-- Code frequency
ALTER TABLE analysis ADD code_frequency INTEGER;
ALTER TABLE analysis ADD code_frequency_code VARCHAR(256);
UPDATE
  analysis AS a
SET
  a.code_frequency = (SELECT
    COUNT(i.`CodeSection`)
    FROM `InspectionHistory-008` AS i
    WHERE CONCAT(i.`license address`, i.`name of business`) = a.id
    GROUP BY i.`CodeSection`, i.`Critical`
    ORDER BY COUNT(i.`CodeSection`) DESC, i.`Critical` DESC, i.`CodeSection`
    LIMIT 1),
  a.code_frequency_code = (SELECT
    `CodeSection` AS code_frequency_code
    FROM `InspectionHistory-008`
    WHERE CONCAT(`license address`, `name of business`) = a.id
    GROUP BY `CodeSection`, `Critical`
    ORDER BY COUNT(`CodeSection`) DESC, `Critical` DESC, `CodeSection`
    LIMIT 1)
;
-- Ratio columns
ALTER TABLE analysis ADD critical_violation_ratio FLOAT;
UPDATE analysis SET critical_violation_ratio = (critical_count / total_violations);

ALTER TABLE analysis ADD violation_inspection_ratio FLOAT;
UPDATE analysis SET violation_inspection_ratio = (total_violations / inspection_count);

ALTER TABLE analysis ADD critical_inspection_ratio FLOAT;
UPDATE analysis SET critical_inspection_ratio = (critical_count / inspection_count);
  

-- Averages
SELECT
  'Average total violations' AS label,
  AVG(total_violations) AS stat
FROM analysis
UNION
SELECT
  'Average inspections' AS label,
  AVG(inspection_count) AS stat
FROM analysis
UNION
SELECT
  'Average critical violations' AS label,
  AVG(critical_count) AS stat
FROM analysis
UNION
SELECT
  'Average critical to violation ratio' AS label,
  AVG(critical_violation_ratio) AS stat
FROM analysis
UNION
SELECT
  'Average violations to inspections ratio' AS label,
  AVG(violation_inspection_ratio) AS stat
FROM analysis
UNION
SELECT
  'Average critical violations to inspections ratio' AS label,
  AVG(critical_inspection_ratio) AS stat
FROM analysis
;