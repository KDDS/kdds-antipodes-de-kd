WITH stage_price
     AS (SELECT fsym_id,
                p_date :: DATE AS p_date,
                p_price
         FROM   "ANTIPODES"."PUBLIC"."PRICES"),
     stage_dividends
     AS (SELECT fsym_id,
                p_divs_exdate :: DATE AS p_divs_exdate,
                p_divs_pd
         FROM   "ANTIPODES"."PUBLIC"."DIVIDENDS"),
     all_information
     AS (SELECT a.fsym_id,
                a.p_date,
                a.p_price,
                Coalesce(b.p_divs_exdate, '9999-12-31') AS p_divs_exdate,
                Coalesce(b.p_divs_pd, 0)                AS p_divs_pd
         FROM   stage_price a
                left join stage_dividends b
                       ON a.fsym_id = b.fsym_id
                          AND a.p_date < b.p_divs_exdate),
     final
     AS (SELECT fsym_id,
                p_date,
                SUM(p_divs_pd) AS total
         FROM   all_information
         GROUP  BY fsym_id,
                   p_date)
SELECT *
FROM   final
ORDER  BY fsym_id,
          p_date DESC; 