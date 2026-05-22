Use projects;

Set SQL_SAFE_UPDATES  = 0 ;

# Changging table name

ALTER TABLE auto_loan_securitisation_data  
RENAME to dim_loans ;


ALTER TABLE dpd_snapshot_history
RENAME to fact_loan_performance ;


ALTER TABLE dynamic_loss_monthly
RENAME to dynamic_loss ;
 
 
ALTER TABLE static_pool_vintage_data 
RENAME to static_pool ;

SELECT COUNT(*) FROM dim_loans;

SELECT COUNT(*) FROM fact_loan_performance;
SELECT COUNT(*) FROM dynamic_loss;
SELECT COUNT(*) FROM static_pool;

#Table Structure Analyze

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'fact_loan_performance';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'dim_loans';



SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'dynamic_loss';


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'static_pool';

#Data Quality Check

SELECT *
FROM dim_loans
WHERE loanid IS NULL;

SELECT loanid, COUNT(*) as count
FROM dim_loans
GROUP BY loanid
HAVING COUNT(*) > 1;

#Create Date Table

CREATE TABLE dim_date (
    full_date DATE,
    year INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT
);

INSERT INTO dim_date (full_date, year, month, month_name, quarter)
SELECT
    dates.full_date,
    YEAR(dates.full_date),
    MONTH(dates.full_date),
    MONTHNAME(dates.full_date),
    QUARTER(dates.full_date)
FROM (
    SELECT DATE('2020-01-01') + INTERVAL (a.a + (10 * b.a) + (100 * c.a) + (1000 * d.a)) DAY AS full_date
    FROM 
    (SELECT 0 a UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a
    CROSS JOIN
    (SELECT 0 a UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
    CROSS JOIN
    (SELECT 0 a UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
    CROSS JOIN
    (SELECT 0 a UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d
) dates
WHERE dates.full_date BETWEEN '2020-01-01' AND '2030-12-31';


SELECT * FROM dim_date
LIMIT 10;

SELECT
    l.loanid,
    l.currentbalance,
    f.dpd_days,
    f.dpd_bucket
FROM dim_loans l
JOIN fact_loan_performance f
ON l.loanid = f.loanid
LIMIT 10;

#First KPI Validation

SELECT SUM(currentbalance) as Total_sum
FROM dim_loans;


#Total 30+ DPD Loans

SELECT COUNT(*) as Total_DPD_loan
FROM fact_loan_performance
WHERE dpd_days >= 30;

#NPA Loans

SELECT COUNT(*)
FROM fact_loan_performance
WHERE dpd_days >= 90;

#Matching loan id check table

SELECT COUNT(*)
FROM dim_loans l
JOIN fact_loan_performance f
ON l.loanid = f.loanid;

SELECT
    l.loanid,
    l.currentbalance,
    f.dpd_days,
    f.dpd_bucket
FROM dim_loans l
JOIN fact_loan_performance f
ON l.loanid = f.loanid
LIMIT 10;


