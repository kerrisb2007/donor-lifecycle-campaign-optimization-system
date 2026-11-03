/*
-- Data quality checks (run after loading all 5 tables)
-- Every check should return 0 rows / 0 count unless noted.
-- Run one statement at a time (Run Statement), or the whole file (Run Script).
*/

-- 1. Row counts (expect 8, 36, 8000, 43912, 560)
SELECT 'channels' tbl, COUNT(*) n FROM channels
UNION ALL SELECT 'campaigns',       COUNT(*) FROM campaigns
UNION ALL SELECT 'donors',          COUNT(*) FROM donors
UNION ALL SELECT 'gifts',           COUNT(*) FROM gifts
UNION ALL SELECT 'marketing_spend', COUNT(*) FROM marketing_spend;

-- 2. Orphan keys (expect 0 each)
SELECT 'gifts w/o donor' check_name, COUNT(*) n
  FROM gifts g WHERE NOT EXISTS (SELECT 1 FROM donors d WHERE d.donor_id = g.donor_id)
UNION ALL
SELECT 'gifts w/o channel', COUNT(*)
  FROM gifts g WHERE g.channel_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM channels c WHERE c.channel_id = g.channel_id)
UNION ALL
SELECT 'gifts w/o campaign', COUNT(*)
  FROM gifts g WHERE g.campaign_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM campaigns c WHERE c.campaign_id = g.campaign_id)
UNION ALL
SELECT 'spend w/o channel', COUNT(*)
  FROM marketing_spend s WHERE NOT EXISTS (SELECT 1 FROM channels c WHERE c.channel_id = s.channel_id);

-- 3. Gifts dated before the donor's first_gift_date, or in the future (expect 0)
SELECT 'gift before first_gift_date' check_name, COUNT(*) n
  FROM gifts g JOIN donors d ON d.donor_id = g.donor_id
 WHERE g.gift_date < d.first_gift_date
UNION ALL
SELECT 'gift after as-of date', COUNT(*)
  FROM gifts WHERE gift_date > DATE '2026-10-27';

-- 4. Null, zero or negative amounts, and missing dates (expect 0)
SELECT COUNT(*) AS bad_amount_or_date
  FROM gifts
 WHERE gift_amount IS NULL OR gift_amount <= 0 OR gift_date IS NULL;

-- 5. Possible duplicate gifts: same donor, date and amount (review any rows)
SELECT donor_id, gift_date, gift_amount, COUNT(*) dup_count
  FROM gifts
 GROUP BY donor_id, gift_date, gift_amount
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC, gift_amount DESC;

-- 6. Spend completeness: each channel should have 70 months (Jan 2021 - Oct 2026)
SELECT channel_id, COUNT(*) months_loaded, MIN(spend_month) first_month, MAX(spend_month) last_month
  FROM marketing_spend
 GROUP BY channel_id
HAVING COUNT(*) <> 70;

-- 7. Donors with no gifts (informational; expected 0 in this dataset)
SELECT COUNT(*) donors_without_gifts
  FROM donors d WHERE NOT EXISTS (SELECT 1 FROM gifts g WHERE g.donor_id = d.donor_id);

-- 8. Top 10 largest gifts (outlier review: are they plausible for a major donor?)
SELECT g.gift_id, g.donor_id, g.gift_date, g.gift_amount, c.channel_name
  FROM gifts g LEFT JOIN channels c ON c.channel_id = g.channel_id
 ORDER BY g.gift_amount DESC
 FETCH FIRST 10 ROWS ONLY;

-- 9. Gift amount distribution (sanity check on spread)
SELECT MIN(gift_amount) min_gift,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gift_amount),2) median_gift,
       ROUND(AVG(gift_amount),2) avg_gift,
       MAX(gift_amount) max_gift,
       ROUND(SUM(gift_amount)) total_revenue
  FROM gifts;