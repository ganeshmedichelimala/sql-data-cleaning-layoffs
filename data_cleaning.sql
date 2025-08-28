-- ===========================================================
-- 📑 DATA CLEANING PIPELINE (Index)
-- ===========================================================
-- STEP 0: View the original data
-- STEP 1: Create a Staging Table (Work on a copy, not raw data)
-- STEP 2: Identify Duplicate Rows
-- STEP 3: Remove Duplicates
-- STEP 4: Standardize Data
--     4.1 Trim extra spaces in company names
--     4.2 Standardize industry values (e.g., Crypto)
--     4.3 Clean up country formatting (remove trailing dots)
--     4.4 Convert date column into proper DATE format
-- STEP 5: Handle NULL or Blank Values
--     5.1 Check for NULL total_laid_off & percentage_laid_off
--     5.2 Fix missing industries using other rows
--     5.3 Delete rows with no useful data
-- STEP 6: Drop unnecessary columns (like row_num)
-- ===========================================================



-- ===========================================================
-- STEP 0: View the original data
-- ===========================================================
select * 
from layoffs;



-- ===========================================================
-- STEP 1: Create a Staging Table
-- ===========================================================
-- Always create a copy of the raw table for cleaning,
-- so that the original remains unchanged.

create table layoffs_staging
like layoffs;

-- Copy all records from layoffs into layoffs_staging
insert into layoffs_staging
select * from layoffs;

-- Verify data copied successfully
select * 
from layoffs_staging;



-- ===========================================================
-- STEP 2: Identify Duplicate Rows
-- ===========================================================
-- Add row numbers within groups of duplicates using ROW_NUMBER().
-- If rows have the same values across all important columns,
-- duplicates will be marked as row_num = 2, 3, etc.

with duplicate_cte as
(
    select *,
    row_number() over (
        partition by company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, 
                     funds_raised_millions
    ) as row_num
    from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;  -- Show only duplicates



-- ===========================================================
-- STEP 3: Remove Duplicates
-- ===========================================================
-- MySQL does not allow DELETE directly from CTE,
-- so we create a second staging table with row_num column.

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  row_num int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Insert data with row numbers into layoffs_staging2
insert into layoffs_staging2
select *,
row_number() over (
    partition by company, location, industry, total_laid_off, 
                 percentage_laid_off, `date`, stage, country, 
                 funds_raised_millions
) as row_num
from layoffs_staging;

-- Remove duplicate rows (row_num > 1)
delete 
from layoffs_staging2
where row_num > 1;

-- Verify duplicates removed
select *
from layoffs_staging2;



-- ===========================================================
-- STEP 4: Standardize Data
-- ===========================================================

-- 4.1 Trim extra spaces from company names
update layoffs_staging2
set company = trim(company);

-- 4.2 Standardize industry values (e.g., Crypto)
update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- 4.3 Clean up country names (remove trailing '.')
UPDATE layoffs_staging2
SET country = trim(trailing '.' from country)
where country like 'United States%';

-- 4.4 Convert date into proper DATE format
-- First check conversion
select `date`, str_to_date(`date`, '%m/%d/%Y') as formatted_date
from layoffs_staging2;

-- Update the column with proper date format
update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

-- Change datatype to DATE
alter table layoffs_staging2
modify column `date` date;



-- ===========================================================
-- STEP 5: Handle NULL or Blank Values
-- ===========================================================

-- 5.1 Check rows with NULL total_laid_off & percentage_laid_off
select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- 5.2 Fix missing industries:
--    → If one row has NULL industry but another row of same company/location has industry,
--      fill it from there.
update layoffs_staging2 t1
join layoffs_staging2 t2 
    on t1.company = t2.company 
   and t1.location = t2.location
set t1.industry = t2.industry
where t1.industry is null and t2.industry is not null;

-- 5.3 Delete useless rows (if both total_laid_off and percentage_laid_off are null)
delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;



-- ===========================================================
-- STEP 6: Drop unnecessary columns
-- ===========================================================
alter table layoffs_staging2
drop column row_num;


-- Final cleaned data
select * 
from layoffs_staging2;
