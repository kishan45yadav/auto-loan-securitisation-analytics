# auto-loan-securitisation-analytics
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=flat&logo=powerbi&logoColor=black)
![MySQL](https://img.shields.io/badge/MySQL-Workbench-4479A1?style=flat&logo=mysql&logoColor=white)
# 🏦 Auto Loan Securitisation — Data Analytics Project

> **End-to-end data engineering and analytics pipeline for an Auto Loan Asset-Backed Securities (ABS) portfolio — covering schema design, ETL, data quality, KPI validation, and Power BI reporting.**
![image alt](https://github.com/kishan45yadav/auto-loan-securitisation-analytics/blob/main/Screenshot%20(374).png?raw=true)
![image alt](https://github.com/kishan45yadav/auto-loan-securitisation-analytics/blob/main/Screenshot%20(375).png?raw=true)
![image alt](https://github.com/kishan45yadav/auto-loan-securitisation-analytics/blob/main/Screenshot%20(376).png?raw=true)
![image alt](https://github.com/kishan45yadav/auto-loan-securitisation-analytics/blob/main/Screenshot%20(377).png?raw=true)

## 📁 Project Structure

```
auto-loan-securitisation/
│
├── Data_Analyst_Securitisation.sql       # Full SQL pipeline (ETL, schema, KPIs)
├── Auto_loan_Securitisation.pbix         # Power BI dashboard file
├── Auto_Loan_Securitisation_Analytics_Report.docx  # Full project report
└── README.md                             # This file
```

---

## 🗂️ Database Schema (Star Schema)

| Original Table Name               | Renamed To              | Type       | Primary Key              |
|-----------------------------------|-------------------------|------------|--------------------------|
| `auto_loan_securitisation_data`   | `dim_loans`             | Dimension  | `loanid`                 |
| `dpd_snapshot_history`            | `fact_loan_performance` | Fact       | `loanid` + `snapshot_date` |
| `dynamic_loss_monthly`            | `dynamic_loss`          | Analytical | `period`                 |
| `static_pool_vintage_data`        | `static_pool`           | Analytical | `vintage_month`          |
| *(created)*                       | `dim_date`              | Date Dim   | `full_date`              |

---

## ⚙️ ETL Pipeline

### Step 1 — Database Setup
```sql
USE projects;
SET SQL_SAFE_UPDATES = 0;
```

### Step 2 — Table Renaming (Semantic Naming Convention)
```sql
ALTER TABLE auto_loan_securitisation_data  RENAME TO dim_loans;
ALTER TABLE dpd_snapshot_history           RENAME TO fact_loan_performance;
ALTER TABLE dynamic_loss_monthly           RENAME TO dynamic_loss;
ALTER TABLE static_pool_vintage_data       RENAME TO static_pool;
```

### Step 3 — Date Dimension Population (2020–2030)
```sql
CREATE TABLE dim_date (
    full_date   DATE,
    year        INT,
    month       INT,
    month_name  VARCHAR(20),
    quarter     INT
);

INSERT INTO dim_date (full_date, year, month, month_name, quarter)
SELECT
    dates.full_date,
    YEAR(dates.full_date),
    MONTH(dates.full_date),
    MONTHNAME(dates.full_date),
    QUARTER(dates.full_date)
FROM (
    SELECT DATE('2020-01-01') + INTERVAL (a.a + (10*b.a) + (100*c.a) + (1000*d.a)) DAY AS full_date
    FROM /* cross join digit tables a, b, c, d */
) dates
WHERE dates.full_date BETWEEN '2020-01-01' AND '2030-12-31';
```

---

## ✅ Data Quality Checks

| Check                  | Query Logic                                     | Expected Result |
|------------------------|-------------------------------------------------|-----------------|
| Null Primary Key       | `WHERE loanid IS NULL`                          | 0 rows          |
| Duplicate Key          | `GROUP BY loanid HAVING COUNT(*) > 1`           | 0 groups        |
| Referential Integrity  | `JOIN dim_loans ON loanid` → `COUNT(*)`         | All matched     |

> **All checks passed** — no nulls, no duplicates, full referential integrity confirmed.

---

## 📊 Key Performance Indicators (KPIs)

### 1. Total Portfolio Balance
```sql
SELECT SUM(currentbalance) AS Total_sum
FROM dim_loans;
```

### 2. 30+ DPD Delinquent Loans
```sql
SELECT COUNT(*) AS Total_DPD_loan
FROM fact_loan_performance
WHERE dpd_days >= 30;
```

### 3. NPA Loans (90+ DPD — RBI Standard)
```sql
SELECT COUNT(*) AS NPA_Count
FROM fact_loan_performance
WHERE dpd_days >= 90;
```

### 4. Referential Integrity Count
```sql
SELECT COUNT(*)
FROM dim_loans l
JOIN fact_loan_performance f ON l.loanid = f.loanid;
```

---

## 📉 DPD Risk Tier Classification

| DPD Bucket | Risk Category      | Regulatory Status | Action                   |
|------------|--------------------|-------------------|--------------------------|
| 0 DPD      | Performing         | Standard Asset    | No action                |
| 1–29 DPD   | Watch              | SMA-0             | Enhanced monitoring      |
| 30–59 DPD  | Sub-Standard Early | SMA-1             | Collection escalation    |
| 60–89 DPD  | Sub-Standard Late  | SMA-2             | Legal notice / restructure |
| 90+ DPD    | Non-Performing     | **NPA**           | Provisioning & recovery  |

---

## 📈 Power BI Dashboard — Report Pages

| Page                   | Key Visuals                                         |
|------------------------|-----------------------------------------------------|
| Portfolio Overview     | Total balance, loan count, DPD donut chart          |
| Delinquency Tracker    | DPD bucket bar chart, trend line, vintage heat map  |
| NPA Monitor            | 90+ DPD KPI card, NPA %, MoM trend                 |
| Loss Curves            | Dynamic loss curve by cohort                        |
| Static Pool Analysis   | Vintage cohort waterfall / table                    |
| Data Quality           | Null check summary, duplicate flags, integrity ✓    |

### Recommended Power BI Relationships
```
dim_loans[loanid]         →  fact_loan_performance[loanid]      (1:Many)
dim_date[full_date]       →  fact_loan_performance[snapshot_date] (1:Many)
dim_date[full_date]       →  dynamic_loss[period_date]           (1:Many)
dim_date[full_date]       →  static_pool[vintage_date]           (1:Many)
```

### Core DAX Measures
```dax
Total Portfolio Balance = SUM(dim_loans[currentbalance])

30+ DPD Count = 
    CALCULATE(
        COUNTROWS(fact_loan_performance),
        fact_loan_performance[dpd_days] >= 30
    )

NPA Count = 
    CALCULATE(
        COUNTROWS(fact_loan_performance),
        fact_loan_performance[dpd_days] >= 90
    )

NPA Rate % = DIVIDE([NPA Count], COUNTROWS(fact_loan_performance), 0)

Avg DPD = AVERAGE(fact_loan_performance[dpd_days])
```

---

## 🔧 Setup & Prerequisites

### Database
- **RDBMS:** MySQL 8.0+ (or compatible)
- **Database Name:** `projects`
- **Permissions Required:** `ALTER`, `INSERT`, `SELECT`, `CREATE TABLE`

### Power BI
- **Power BI Desktop:** April 2024 release or later
- **Data source:** Direct MySQL connection or exported CSV
- **File:** `Auto_loan_Securitisation.pbix`

### To Run the SQL Pipeline
```bash
# Connect to your MySQL instance and run:
mysql -u <username> -p projects < Data_Analyst_Securitisation.sql
```

---

## 🚀 Recommendations

### Immediate
- [ ] Add indexes on `loanid` in both `dim_loans` and `fact_loan_performance`
- [ ] Partition `fact_loan_performance` by `snapshot_date` for performance
- [ ] Schedule monthly automated refresh via SQL Agent or dbt
- [ ] Add `data_load_audit` table to log ETL timestamps and row counts

### Analytical Enhancements
- [ ] Build vintage analysis view joining `static_pool` with `dim_date`
- [ ] Implement roll-rate matrix (DPD bucket migration tracking)
- [ ] Add LGD and PD columns to `dim_loans` for credit scoring
- [ ] Flag loans jumping from 0 DPD to 30+ DPD in a single cycle

### Governance
- [ ] Restrict `SQL_SAFE_UPDATES = 0` to ETL service accounts only
- [ ] Implement Row-Level Security (RLS) in Power BI by tranche/investor
- [ ] Publish a data dictionary with all column definitions
- [ ] Set Power BI refresh alerts on row count anomalies

---

## 👤 Author & Classification

| Field          | Details                          |
|----------------|----------------------------------|
| Prepared By    | Securitisation Analytics Team    |
| Report Date    | May 2026                         |
| Classification | Confidential                     |
| Version        | 1.0 — Final                      |

---

*For the full narrative report with schema diagrams, KPI breakdowns, and dashboard architecture, refer to `Auto_Loan_Securitisation_Analytics_Report.docx`.*
