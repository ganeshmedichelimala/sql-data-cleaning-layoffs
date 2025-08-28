# SQL Data Cleaning Project – Layoffs Dataset

## 📌 Project Overview
This project demonstrates how to clean and standardize raw data using SQL.  
The dataset (`layoffs`) contains company layoff records (commonly used for SQL practice).  

I created a **data cleaning pipeline** that:
1. Created staging tables (never cleaned raw data directly)
2. Removed duplicate rows
3. Standardized data (company names, industries, countries, dates)
4. Handled NULL/blank values
5. Dropped unnecessary columns

## 🛠️ Technologies
- MySQL
- SQL Window Functions (`ROW_NUMBER`)
- String Functions (`TRIM`, `LIKE`)
- Date Conversion (`STR_TO_DATE`)

## 📂 Files
- `data_cleaning.sql` → Full cleaning script with comments

## 🚀 Key Learnings
- Using staging tables for safe data cleaning
- Identifying and removing duplicates with `ROW_NUMBER()`
- Standardizing inconsistent text values
- Handling NULL and blank values
- Altering columns to correct data types
