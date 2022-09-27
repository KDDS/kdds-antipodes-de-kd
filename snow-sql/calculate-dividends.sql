CREATE OR REPLACE DATABASE ANTIPODES;
CREATE or REPLACE WAREHOUSE stocks_dwh WITH WAREHOUSE_SIZE = 'MEDIUM' WAREHOUSE_TYPE = 'STANDARD' AUTO_SUSPEND = 600 AUTO_RESUME = TRUE;

USE DATABASE ANTIPODES;
USE WAREHOUSE STOCKS_DWH;


CREATE OR REPLACE TABLE "ANTIPODES"."PUBLIC"."PRICES"
(
FSYM_ID  VARCHAR2(100) ,
P_DATE   DATE ,
CURRENCY VARCHAR2(5) ,
P_PRICE  NUMERIC(30,3)
);

CREATE OR REPLACE TABLE "ANTIPODES"."PUBLIC"."DIVIDENDS"
(
FSYM_ID  VARCHAR2(100) ,
P_DIVS_EXDATE   DATE ,
P_DIVS_PD  NUMERIC(30)
);

INSERT INTO PRICES VALUES ('LORBHW-R','2022-12-09','INR',598);
INSERT INTO PRICES VALUES ('JBP919-R','2022-12-09','EUR',9.41);
INSERT INTO PRICES VALUES ('CLO6GR-R','2022-12-09','USD',0.0021);
INSERT INTO PRICES VALUES ('CP7Q52-R','2022-12-09','USD',1.7);
INSERT INTO PRICES VALUES ('NOWZ18-R','2022-12-09','AUD',0.04);
INSERT INTO PRICES VALUES ('CLO6GR-R','2022-09-09','USD',0.002);
INSERT INTO PRICES VALUES ('NOWZ18-R','2022-09-09','AUD',0.04);
INSERT INTO PRICES VALUES ('JBP919-R','2022-09-09','EUR',9.612);
INSERT INTO PRICES VALUES ('FOBORW-R','2022-09-09','USD',2.303);
INSERT INTO PRICES VALUES ('CP7Q52-R','2022-09-09','USD',2);
INSERT INTO PRICES VALUES ('LORBHW-R','2022-09-09','INR',601.75);
INSERT INTO PRICES VALUES ('R3T2GH-R','2022-09-09','CNY',95.75);
INSERT INTO PRICES VALUES ('JBP919-R','2022-08-09','EUR',9.776);
INSERT INTO PRICES VALUES ('NOWZ18-R','2022-08-09','AUD',0.047);
INSERT INTO PRICES VALUES ('CLO6GR-R','2022-08-09','USD',0.00225);
INSERT INTO PRICES VALUES ('R3T2GH-R','2022-08-09','CNY',595.64);

INSERT INTO DIVIDENDS VALUES ('LW891F-R','2021-07-15',0.576195002);
INSERT INTO DIVIDENDS VALUES ('TTQSQY-R','2021-09-20',1.5);
INSERT INTO DIVIDENDS VALUES ('WQTO9Y-R','2020-09-24',0.5);
INSERT INTO DIVIDENDS VALUES ('VSN617-R','2022-06-29',0.314931989);
INSERT INTO DIVIDENDS VALUES ('JZYXW4-R','2022-09-22',7);
INSERT INTO DIVIDENDS VALUES ('$251VB-R','2021-12-21',0.349999994);
INSERT INTO DIVIDENDS VALUES ('BJYTXJ-R','2021-10-01',0.00999999978);
INSERT INTO DIVIDENDS VALUES ('WJYDDZ-R','2021-07-16',0.0500000007);
INSERT INTO DIVIDENDS VALUES ('DKPH4W-R','2021-12-13',0.0896959975);
INSERT INTO DIVIDENDS VALUES ('S2VNGO-R','2021-10-20',0.5);
INSERT INTO DIVIDENDS VALUES ('SB6O0JV-R','2022-08-11',20);
INSERT INTO DIVIDENDS VALUES ('S1YXCT-R','2021-07-08',1.60000002);
INSERT INTO DIVIDENDS VALUES ('CLO6GR-R','2022-09-01',10);
INSERT INTO DIVIDENDS VALUES ('CLO6GR-R','2022-09-10',200);
INSERT INTO DIVIDENDS VALUES ('CLO6GR-R','2022-09-14',400);
commit;


-- MOCK DATA FOR 'CLO6GR-R'
-- 8th,  9th, 12th PRICE DATES ON SEPTEMBER                  
-- 1st, 10th, 14th DIVIDEND DATES ON SEPTEMBER
-- $10, $200, $400 DIVIDEND AMOUNT PAID ON ABOVE DATES

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
         --WHERE  fsym_id = 'CLO6GR-R'
         GROUP  BY fsym_id,
                   p_date)
SELECT *
FROM   final
ORDER  BY fsym_id,
          p_date DESC; 