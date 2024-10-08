# Laptop Data Cleaning and Exploratory Data Analysis Project useing SQL

This project involves cleaning a dataset of laptops, which includes steps such as backing up the table, removing unnecessary columns, handling missing values, removing duplicates, and transforming columns into more useful formats for analysis.

## Before Cleaning data 
![Before Cleaning Data](https://github.com/shanto173/SQL-2024/blob/main/image/before_cleanign_data.png)

## After Cleaning data

![Before Cleaning Data](https://github.com/shanto173/SQL-2024/blob/main/image/after_cleaned_dataset.png)

## Table of Contents for Data Cleaning 

1. [Step 1: Creating Backup](#step-1-creating-backup)
2. [Step 2: Checking the Number of Rows and Columns](#step-2-checking-the-number-of-rows-and-columns)
3. [Step 3: Checking Memory Usage](#step-3-checking-memory-usage)
4. [Step 4: Dropping Non-important Columns](#step-4-dropping-non-important-columns)
5. [Step 5: Dropping Rows with Null Values](#step-5-dropping-rows-with-null-values)
6. [Step 6: Dropping Duplicates](#step-6-dropping-duplicates)
7. [Step 7: Cleaning Columns](#step-7-cleaning-columns)
8. [Step 8: Handling Screen Resolution Information](#step-8-handling-screen-resolution-information)
9. [Step 9: Cleaning and Organizing Memory Information](#step-9-cleaning-and-organizing-memory-information)
10. [Step 10: Final Step: View the Cleaned Laptop Table](#step-10-final-step-view-the-cleaned-laptop-table)

## Table of Contents for exploratory data analysis. 

1. [Exploratory-Data-Analysis](#Exploratory-Data-Analysis)<br>
2. [Introduction](#Introduction)
3. [Data-Preview](#1-Data-Preview)
4. [Univariate-Analysis-of-Numerical-Columns](#2-univariate-analysis-of-numerical-column)
5. [Bivariate-Data-Analysis(Numerical Vs Numerical)](#3-bivariate-data-analysisnumerical-column)
6. [Bivariate-Data-Analysis(Categorical Vs Numerical)](#33-bivariate-analysis-company-vs-average-pricecategory-vs-numerical)
7. [Missing Value Treatment (Imputing Missing Price)](#3-missing-value-treatment)
8. [Feature_Engineering](#4-feature-enginerring)
9. [Encoding(One Hot Encoding)](#5-encoding-one-hot-encoding)



---

## SQL Code and Explanation



### Step 1: Creating Backup
The first step is to create a backup of the `laptop` table.

1. Create the table structure for backup:
```SQL
CREATE TABLE laptop_backup LIKE laptop;
```
2. Insert all the values into the backup table:
```SQL
INSERT INTO laptop_backup 
SELECT * FROM laptop; 
```
### Step 2: Checking the Number of Rows and Columns.
To verify the number of rows in the laptop table:
```SQL
SELECT COUNT(*) FROM laptop;
```
### Step 3: Checking Memory Usage
Check how much memory the data occupies:
```SQL
SELECT * FROM information_schema.tables 
WHERE TABLE_SCHEMA = 'data_cleaning_project' AND table_name = 'laptop';
```
Convert the memory from bytes to kilobytes:
```SQL
SELECT data_length / 1024 FROM information_schema.tables 
WHERE TABLE_SCHEMA = 'data_cleaning_project' AND table_name = 'laptop'; 
```
### Step 4: Dropping Non-important Columns
The column Unnamed: 0 is irrelevant, so I dropped it:
```sql
ALTER TABLE laptop DROP COLUMN `Unnamed: 0`;

```
### Step 5: Dropping Rows with Null Values
Identify and delete rows where all relevant columns are null:

```sql
WITH ind AS (SELECT * FROM laptop 
WHERE company IS NULL AND TypeName IS NULL AND Inches IS NULL
AND ScreenResolution IS NULL AND Cpu IS NULL AND Ram IS NULL
AND Memory IS NULL AND Gpu IS NULL AND OpSys IS NULL
AND Weight IS NULL AND Price IS NULL)
DELETE FROM laptop WHERE `index` IN (SELECT `index` FROM ind);
```

### Step 6: Dropping Duplicates
Remove duplicate rows based on the main features:
```SQL
WITH duplicates AS (
    SELECT Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price, MIN(`index`) AS duplicate_index
    FROM laptop 
    GROUP BY Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price)
DELETE FROM laptop WHERE `index` NOT IN (SELECT duplicate_index FROM duplicates);
```
### Step 7: Cleaning Columns
1. Convert the Inches column from text to decimal format in order to reduce file size:
   ```SQL
    ALTER TABLE laptop MODIFY COLUMN Inches DECIMAL(10,1);
   ```
2. Remove the "GB" from the RAM column with an empty string and convert the RAM column to integer:
   ```sql
    UPDATE laptop t1
    SET Ram = (
    SELECT REPLACE(t2.Ram, 'GB', '')
    FROM (SELECT * FROM laptop) t2
    WHERE t2.`index` = t1.`index`
    );
    ALTER TABLE laptop MODIFY COLUMN Ram INTEGER;
   ```
3. Fix the Weight column by replacing "kg" and converting it:
  ```sql
    UPDATE laptop t1
    SET Weight = REPLACE(Weight, 'kg', '') 
    WHERE `index` = t1.`index`;
  ```
4. Round the Price column to the nearest integer and update the value and convert the double column to an integer:
   
    ```SQL 
      UPDATE laptop t1
      SET Price = (
      SELECT ROUND(Price) 
      FROM (SELECT * FROM laptop) t2 
      WHERE t1.`index` = t2.`index`
    );
    ALTER TABLE laptop MODIFY COLUMN Price INTEGER;
    ```
5. Clean the OpSys column by categorizing the operating systems:
   ```SQL
        UPDATE laptop 
        SET OpSys = CASE
            WHEN OpSys LIKE '%mac%' THEN 'macOS'
            WHEN OpSys LIKE '%windows%' THEN 'windows'
            WHEN OpSys LIKE '%linux%' THEN 'Linux'
            WHEN OpSys LIKE '%No OS%' THEN 'NA'
            ELSE 'others'
        END;
   ```
6. Step 8: GPU Column Modification First, create 2 columns for storing specific GPU information Extract gpu_brand and gpu_name from the Gpu column and drop the old column:
   
   ```sql
            ALTER TABLE laptop
            ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu,
            ADD COLUMN gpu_name VARCHAR(255) AFTER OpSys;
            
            UPDATE laptop t1
            SET gpu_brand = (
                SELECT SUBSTRING_INDEX(Gpu, ' ', 1) 
                FROM (SELECT * FROM laptop) t2 
                WHERE t1.`index` = t2.`index`
            );
            
            UPDATE laptop t1
            SET gpu_name = (
                SELECT REPLACE(Gpu, gpu_brand, '') 
                FROM (SELECT * FROM laptop) t2 
                WHERE t1.`index` = t2.`index`
            );
            
            ALTER TABLE laptop DROP COLUMN Gpu;
     
   ```

7. Create three new columns to store the CPU brand, name, and speed.

    ```sql
    ALTER TABLE laptop
    ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
    ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
    ADD COLUMN cpu_speed DECIMAL(10,1) AFTER Cpu_name;
    ```
7.1  Extracting the CPU Brand
```sql
SELECT Cpu, SUBSTRING_INDEX(Cpu, ' ', 1) FROM laptop;
```
        
7.2 Updating the cpu_brand Column The extracted CPU brand values are inserted into the cpu_brand column.
```sql
 UPDATE laptop t1
    SET cpu_brand = (
    SELECT SUBSTRING_INDEX(Cpu, ' ', 1)
    FROM (SELECT * FROM laptop) t2
    WHERE t1.index = t2.index
    );
```
7.3 Extracting CPU Name The CPU name is extracted by removing the brand from the original Cpu column and stored in the cpu_name column.

```sql
        UPDATE laptop t1
        SET cpu_name = (
        SELECT REPLACE(Cpu, cpu_brand, '')
        FROM (SELECT * FROM laptop) t2
        WHERE t1.index = t2.index
        );
```

7.4  Extracting CPU Speed This step extracts the CPU speed from the cpu_name and stores it in the cpu_speed column.
```sql
            UPDATE laptop t1
            SET cpu_speed = (
                SELECT REPLACE(t3.speed, 'GHz', '')
                FROM (
                SELECT cpu_name, SUBSTRING_INDEX(cpu_name, ' ', -1) AS 'speed'
                FROM (SELECT * FROM laptop) t2
                WHERE t1.index = t2.index
            ) t3
        );
```
7.5 Cleaning Up the cpu_name Column The CPU speed is removed from the cpu_name column.
```sql
            UPDATE laptop t1
            SET cpu_name = (
                SELECT SUBSTRING_INDEX(cpu_name, cpu_speed, 1)
                FROM (SELECT * FROM laptop) t2
                WHERE t1.index = t2.index
            );
```
7.6 Dropping the Original Cpu Column Finally, the original Cpu column is dropped from the table.
```sql
            ALTER TABLE laptop DROP COLUMN Cpu;
            SELECT * FROM laptop;
```
### step-8-handling-screen-resolution-information
Step 1: Creating Columns for Screen Resolution Data
Three new columns are added to store height, width, and whether the laptop has a touchscreen.
```SQL
ALTER TABLE laptop
ADD COLUMN height INTEGER AFTER ScreenResolution,
ADD COLUMN width INTEGER AFTER height,
ADD COLUMN touchscreen INTEGER AFTER width;
```
Step 2: Extracting Height and Width
The height and width are extracted from the ScreenResolution column.
```SQL
    UPDATE laptop t1
SET height = (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution, ' ', -1), 'x', 1)
    FROM (SELECT * FROM laptop) t2
    WHERE t1.index = t2.index
);

UPDATE laptop t1
SET width = (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution, ' ', -1), 'x', -1)
    FROM (SELECT * FROM laptop) t2
    WHERE t1.index = t2.index
);

```

Step 3: Identifying Touchscreen Laptops
A new touchscreen column is updated based on whether the laptop has a touchscreen feature.
```SQL
UPDATE laptop t1
SET touchscreen = (
    SELECT CASE
        WHEN ScreenResolution LIKE '%Touchscreen%' THEN 1
        ELSE 0
    END AS touch
    FROM (SELECT * FROM laptop) t2
    WHERE t1.index = t2.index
);
```
Step 4: Dropping the ScreenResolution Column
The original ScreenResolution column is dropped after the data has been extracted.
```SQL
ALTER TABLE laptop DROP COLUMN `ScreenResolution`;
SELECT * FROM laptop;
```
3. Renaming CPU Names for Easier Understanding
This section standardizes the CPU names in the cpu_name column for easier understanding and analysis.

```SQL
UPDATE laptop t1
SET cpu_name = (
    CASE
        WHEN cpu_name LIKE '%Core i5%' THEN 'Core i5'
        WHEN cpu_name LIKE '%Core i7%' THEN 'Core i7'
        WHEN cpu_name LIKE '%A9%' THEN 'A9'
        -- Add other conditions as needed
        ELSE 'others'
    END
);
SELECT * FROM laptop;

```

### step-9-cleaning-and-organizing-memory-information
Step 1: Creating New Columns for Memory Information
Three new columns are created to store different types of memory information.

```SQL
ALTER TABLE laptop
ADD COLUMN secondary_storages VARCHAR(255) AFTER primary_storage;

```
Step 2: Identifying Memory Types
A temporary column is used to identify the type of memory.

```SQL
    SELECT Memory,
CASE
    WHEN Memory LIKE '%SSD%HDD%' THEN 'hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash%' THEN 'Flash drive'
END AS new
FROM laptop;

```
Step 3: Updating the Primary and Secondary Storage
The primary and secondary storage values are extracted and updated accordingly.

```SQL
UPDATE laptop t1
SET primary_storage = (SUBSTRING_INDEX(Memory, ' ', 1));

UPDATE laptop t1
SET secondary_storages = (
    SELECT CASE
        WHEN t1.Memory = sec THEN NULL
        ELSE sec
    END AS new_sec
    FROM (
        SELECT Memory, SUBSTRING_INDEX(Memory, ' +', -1) sec
        FROM (SELECT * FROM laptop) t2
        WHERE t1.index = t2.index
    ) t3
);

```
Step 4: Further Cleaning of Storage Data
The storage data is cleaned and standardized.

```SQL
UPDATE laptop
SET secondary_storages = REPLACE(REPLACE(TRIM(REPLACE(secondary_storage, 'HDD', '')), 'SSD', ''), '1.0TB', '1TB');

UPDATE laptop t1
SET primary_storage = (
    CASE
        WHEN primary_storage = '1TB' THEN '1024GB'
        WHEN primary_storage = '2TB' THEN '2048GB'
        ELSE primary_storage
    END
);

```
Step 5: Converting Storage Columns to Integer
The primary_storage and secondary_storages columns are converted to integer types for efficient data handling.

```SQL
    ALTER TABLE laptop 
    MODIFY COLUMN primary_storage INTEGER;
    
    ALTER TABLE laptop
    MODIFY COLUMN secondary_storages INTEGER;

```
### step-10-final-step-view-the-cleaned-laptop-table

```SQL
SELECT * FROM laptop;

```


# Exploratory Data Analysis

## Introduction

In this analysis, I perform Exploratory Data Analysis (EDA) to gain insights into the dataset and prepare it for further modeling. The EDA process is divided into several key steps:

1. **Univariate Data Analysis**:
   - I start by analyzing individual variables to understand their distributions and characteristics. This includes examining numerical columns and identifying basic statistical measures.

2. **Bivariate Data Analysis**:
   -  Then explore the relationships between pairs of variables. This involves:
     - **Numerical-Numerical Analysis**: Investigating the correlation and patterns between numerical variables.
     - **Categorical-Categorical Analysis**: Analyzing the interactions between categorical variables.
     - **Categorical to Numerical Analysis**: Examining how categorical variables impact numerical variables.

3. **Data Cleaning and Preparation**:
   - Based on insights gained from the univariate and bivariate analyses, I address missing values by imputing them appropriately.
   - Outliers are identified and handled to ensure they do not skew the analysis.

4. **Feature Engineering**:
   - New features are created to enhance the dataset. For example, I may calculate metrics like Pixel Per Inch (PPI) using existing columns such as height and width, which can serve as valuable indicators of laptop price.

5. **Categorical Data Encoding**:
   - Finally, categorical data is transformed into a numerical format using one-hot encoding to prepare it for machine learning models.

This structured approach ensures a thorough understanding of the dataset and prepares it for accurate and effective analysis.

### 1-Data-Preview

This section provides an overview of the data in the `laptop` table, including a preview of the top and bottom rows, as well as a random sample.

#### Head
```SQL
SELECT * FROM laptop ORDER BY `index` LIMIT 5;
```
![Top 5 Rows](https://github.com/shanto173/SQL-2024/blob/main/image/head_5.png)

Retrieves the first 5 rows from the laptop table, ordered by the index column. Useful for quickly viewing the initial entries in the dataset.

#### Tail
```SQL
SELECT * FROM laptop ORDER BY `index` DESC LIMIT 5;
```
![Top 5 Rows](https://github.com/shanto173/SQL-2024/blob/main/image/tail.png)

Retrieves the last 5 rows from the laptop table, ordered by the index column in descending order. for understanding the data, and quickly viewing the final entries in the dataset.

#### Sample

```SQL
SELECT * FROM laptop ORDER BY RAND() LIMIT 5;
```
Results:
![Top 5 Rows](https://github.com/shanto173/SQL-2024/blob/main/image/random_5.png)

Retrieves 5 random rows from the laptop table for getting a random sample of data to examine various parts of the dataset.

### 2-Univariate-Analysis-of-Numerical-Columns
Numerical-Columns(Price)
This section focuses on the price column, which is a numerical column of interest. It includes steps for calculating key statistical measures and identifying outliers.

#### Creating a New Index for Percentile Calculation
```SQL
WITH temp AS (
  SELECT `index`, price, ROW_NUMBER() OVER(ORDER BY price) AS new_row
  FROM laptop
)
UPDATE laptop t1
JOIN temp t2 ON t1.index = t2.index
SET t1.new_index = t2.new_row;
```
Adds a new column new_index to the laptop table, which contains the row number ordered by price. This is used to facilitate percentile calculations because there are no 
the function that I can use for percentile.

#### Statistical Summary and Quantiles
```SQL
    SELECT 
  COUNT(price) AS count,
  MIN(price) AS min_price,
  MAX(price) AS max_price,
  AVG(price) AS average_price,
  STD(price) AS std_dev_price,
  (SELECT price FROM laptop WHERE new_index IN (FLOOR((25*(SELECT COUNT(*) FROM laptop)+1)/100))) AS Q1,
  (SELECT price FROM laptop WHERE new_index IN (FLOOR((50*(SELECT COUNT(*) FROM laptop)+1)/100))) AS Median,
  (SELECT price FROM laptop WHERE new_index IN (FLOOR((75*(SELECT COUNT(*) FROM laptop)+1)/100))) AS Q3
FROM laptop;

```
Results:
![8 number Summary](https://github.com/shanto173/SQL-2024/blob/main/image/8_number_summary.png)

Provides a statistical summary of the price column, including count, minimum, maximum, average, and standard deviation. Additionally, calculates the 1st quartile (Q1), median, and 3rd quartile (Q3) using the new_index column to determine the appropriate percentile values.
            
    observation: -- **Here count value is the same as the total number of rows so there are no null values are present**
                 -- **The minimum laptop price is 9271. which may be an outlier because a laptop can't be that cheap**
                 -- **The maximum laptop price is over 3 lakh which is quite expensive for a laptop**
                 -- **avg price is 60k and the median is 52k which indicates that there are some outliers because of this the data is skewed**
                 -- **standard deviation is 37k which is a lot, which means data is not that centered, data is quite scattered**
                 -- **25 percentile value is 32k which indicates that 25 percent of laptop price price is less than 32k**
                 -- **50 percentile value is 52.5k which indicates that 50 percent of the laptop price is less than 52.5k**
                 -- **75 percentile value is 79.5k which indicates that 75 percent of the laptop price is less than 79.5k**

#### 3. Missing Value Detection

This section identifies rows where the `price` column has missing values (i.e., null entries).

#### Finding Missing Price Values
```SQL
SELECT * FROM laptop WHERE price IS NULL;
```
Results:
![Null values](https://github.com/shanto173/SQL-2024/blob/main/image/Price_null.png)

Retrieves all rows from the laptop table where the price column is null. This helps in identifying any missing values that need to be imputed or handled before further analysis.

#### 4. Outlier Detection
Outliers can significantly affect the results of the analysis, so this section focuses on identifying them based on the interquartile range (IQR) method.

```SQL
SELECT * FROM laptop;

SELECT * 
FROM (
  SELECT *,
    (SELECT price FROM laptop WHERE new_index IN (FLOOR((25*(SELECT COUNT(*) FROM laptop)+1)/100))) AS Q1,
    (SELECT price FROM laptop WHERE new_index IN (FLOOR((75*(SELECT COUNT(*) FROM laptop)+1)/100))) AS Q3
  FROM laptop
) t
WHERE t.price < (Q1 - (1.5 * (t.Q3 - t.Q1))) OR 
      t.price > (Q1 + (1.5 * (t.Q3 - t.Q1)));

```
Results:
![Outliers Detection](https://github.com/shanto173/SQL-2024/blob/main/image/finding_outliers.png)

**Description:**
The first query retrieves all rows from the laptop table for a general overview.
The second query calculates the 1st quartile (Q1) and 3rd quartile (Q3) and identifies any rows where the price is an outlier. Outliers are defined as values below Q1 - 1.5*(Q3 - Q1) or above Q1 + 1.5*(Q3 - Q1). 

Results:
![Justifying outliers](https://github.com/shanto173/SQL-2024/blob/main/image/justifying_outliers.png)
                   
    --Out of 1244 rows there are 151 outliers according to IQR but they are not outliers, if we consider the specification.

#### 5. Horizontal Histogram of Laptop Prices
Overview
This SQL query generates a horizontal histogram of laptop prices by categorizing the prices into predefined ranges (or "buckets") and displaying the frequency of laptops in each range using asterisks (*). This visual representation helps to quickly understand the distribution of laptop prices.

```SQL
SELECT t.bucket, 
       COUNT(price), 
       REPEAT('*', COUNT(price)/5) AS histogram
FROM (
  SELECT price,
    CASE 
      WHEN price BETWEEN 0 AND 25000 THEN '0-25k'
      WHEN price BETWEEN 25001 AND 50000 THEN '25k-50k'
      WHEN price BETWEEN 50001 AND 75000 THEN '50k-75k'
      WHEN price BETWEEN 75001 AND 100000 THEN '75k-100k'
      ELSE '>100k'
    END AS bucket
  FROM laptop
) t
GROUP BY t.bucket;

```
Results:
![Laptop Histograme](https://github.com/shanto173/SQL-2024/blob/main/image/histograme.png)
Bucket Creation:
The CASE statement groups the laptop prices into five predefined ranges
**Count of Laptops:
The COUNT(price) function counts how many laptops fall into each price range (bucket).
Horizontal Histogram.**

**The REPEAT('*', COUNT(price)/5) function generates a string of asterisks (*) representing the count of laptops in each bucket. The division by 5 reduces the number of asterisks to make the output more concise and readable.
Each asterisk represents approximately five laptops, but this can be adjusted by modifying the divisor in COUNT(price)/X.**
            
    Observation: - most of the laptop price range between 25k to 50k and 50k to 75k 
                 - only 300 laptops price range between 75k to over 100k because of their brand name and specs their prices are quite high.


#### 6.Data Analysis on weight column
The following SQL query provides a basic statistical summary of the Weight column, including the count, minimum, maximum, average, and standard deviation.
```SQL
SELECT COUNT(Weight), 
       MIN(Weight), 
       MAX(Weight), 
       AVG(Weight), 
       STD(Weight)
FROM laptop;
```
Results:
![weight 5 Number Summary](https://github.com/shanto173/SQL-2024/blob/main/image/weight_5_number_summary.png)

    observation:- By seeing the count value I can say there are no null values present 
                - By seeing the price and max price there are some outliers present in the data
                - By seeing Std, the std less I can say the weight data is mostly centered

#### 6.1 Outlier Detection of weight

Weight of 0.0002 kg:
This weight is considered an outlier since it is far below a reasonable laptop weight.
The following query is used to identify such records
```SQL
SELECT * FROM laptop 
WHERE Weight = 0.0002;
```
#### 6.2 Weights Above 5 kg:
Laptops weighing more than 5 kg are likely outliers since most laptops are designed to be portable, with weights generally between 0.5 and 3 kg. This query finds such outliers:
```SQL
SELECT * FROM laptop 
WHERE Weight > 5;
```
#### 6.3 Outliers removal
Once outliers are detected, they can be removed from the dataset using the following DELETE queries.
```sql
DELETE FROM laptop WHERE `index` = 349;  -- Remove row with weight 0.0002 kg
DELETE FROM laptop WHERE `index` IN (326, 587);  -- Remove rows with weight > 5 kg
```
#### 6.4Visualizing the Weight Distribution
After removing the outliers, I visualize the distribution of laptop weights by plotting a horizontal histogram using SQL. The histogram groups laptops into buckets based on their weight, with each asterisk (*) representing a certain number of laptops in each bucket.

```sql
SELECT bucket, 
       COUNT(bucket), 
       REPEAT('*', COUNT(bucket)/6) AS histogram
FROM (
  SELECT Weight,
    CASE
      WHEN Weight BETWEEN 0.5 AND 3 THEN '0.5kg-3kg'
      WHEN Weight BETWEEN 3.1 AND 5 THEN '3kg-5kg'
      ELSE '>5kg'
    END AS bucket
  FROM laptop
) t 
GROUP BY bucket;
```
Bucket Creation: The CASE statement groups the laptop weights into the following categories:
0.5kg-3kg: Lightweight laptops.
3kg-5kg: Heavier laptops.
>5kg: Unusually heavy Laptops (if any remain after outlier removal).

Results:
![Weight_histograme](https://github.com/shanto173/SQL-2024/blob/main/image/weight_histograme.png)

#### 7.CPU Speed Analysis in SQL
The following SQL query provides a statistical overview of the CPU speeds in the dataset, including the total number of records, the slowest and fastest CPU speeds, and the average and standard deviation of the values.

```sql
SELECT COUNT(cpu_speed), 
       MIN(cpu_speed), 
       MAX(cpu_speed), 
       AVG(cpu_speed), 
       STD(cpu_speed)
FROM laptop;
```
Results:
![Cpu_5_Number_summary](https://github.com/shanto173/SQL-2024/blob/main/image/cpu_5_number_summary.png)

    observation: - AVG(cpu_speed): The average CPU speed of laptops is approximately 2.30 GHz, reflecting a typical mid-range performance level for laptops.
                 - STD(cpu_speed): The standard deviation is 0.5049 GHz, indicating that most CPU speeds fall within half a GHz from the average.
                 - Modern laptops typically have CPU speeds ranging from 1.5 GHz to 3.5 GHz or higher. A speed of 0.9 GHz seems unusually low, which might indicate an                      - outlier. It could represent very old or specialized low-power processors (like those in ultra-portable devices) 

### 1.Categorical Data Analysis (Company)
The SQL query below retrieves the number of laptops for each company in the dataset.<br>It helps identify which brands have the most and least representation in the dataset.

SQL Code:
```SQL
SELECT company, COUNT(company) 
FROM laptop 
GROUP BY company;
```
Result:

![Company_pie_chart](https://github.com/shanto173/SQL-2024/blob/main/image/company_pie.png)

    Insights: Top 3 Brands is 
                - Lenovo: 281 laptops
                - Dell: 280 laptops
                - HP: 260 laptops
                These brands dominate the dataset, indicating their strong presence in the laptop market.
              
              Smaller Representation:
                Asus, Acer, Apple, and Fujitsu have very limited representation.

### 2.Analyzing Touchscreen Feature
The SQL query below retrieves the count and percentage of laptops that are equipped with a touchscreen versus those that are not.<be> The percentage of each category is calculated based on the total number of laptops in the dataset.

```SQL
    SELECT 
  touchscreen,
  COUNT(touchscreen) AS touchscreen_count,
  COUNT(touchscreen) / (SELECT COUNT(*) FROM laptop) AS touchscreen_percentage
FROM laptop
GROUP BY touchscreen;
```
Result:

![Touchscreen percentage](https://github.com/shanto173/SQL-2024/blob/main/image/touchscreen_percentage.png)

    Insights: - Non-TouchScreen Laptops:
                 - The majority of laptops in the dataset, approximately 85.41%, do not have a touchscreen.
              - TouchScreen Laptops:
                 - About 14.59% of the laptops are equipped with a touchscreen, indicating that touchscreens are less common.


### 3. Analyzing CPU Brand
The SQL query below retrieves the count and percentage of laptops by CPU brand. It shows how common each CPU brand is within the dataset by calculating the percentage share of each.

```SQL
SELECT 
  cpu_brand,
  COUNT(cpu_brand) AS cpu_brand_count,
  COUNT(cpu_brand) / (SELECT COUNT(*) FROM laptop) AS cpu_brand_percentage
FROM laptop
GROUP BY cpu_brand;
```
Result:

![Cpu_brand_pie_char](https://github.com/shanto173/SQL-2024/blob/main/image/cpu_brand.png)

    Insights:
    Intel dominates the dataset with 95.08% of laptops using Intel CPUs, making it by far the most common CPU brand.
    AMD accounts for 4.83% of the laptops, making it the second most common but significantly less popular than Intel.
    Samsung represents just 0.08% of the dataset, with only one laptop in the dataset using a Samsung CPU.



### 4. Analyzing CPU Brand
The SQL query below retrieves the count and percentage of laptops by CPU brand. It shows how common each CPU brand is within the dataset by calculating the percentage share of each.

```SQL
SELECT 
  cpu_brand,
  COUNT(cpu_brand) AS cpu_brand_count,
  COUNT(cpu_brand) / (SELECT COUNT(*) FROM laptop) AS cpu_brand_percentage
FROM laptop
GROUP BY cpu_brand;

```
Result:

![Cpu_brand_pie_char](https://github.com/shanto173/SQL-2024/blob/main/image/opsys_pie.png)

    Insights:
    Intel dominates the dataset with 95.08% of laptops using Intel CPUs, making it by far the most common CPU brand.
    AMD accounts for 4.83% of the laptops, making it the second most common but significantly less popular than Intel.
    Samsung represents just 0.08% of the dataset, with only one laptop in the dataset using a Samsung CPU.

### 3-Bivariate-Data-Analysis(Numerical-Column)

#### 3.1 Bivariate Analysis (Company vs. Touchscreen)

The SQL query below performs a bivariate analysis by grouping the laptops based on Company and Touchscreen status. It calculates the number of TouchScreen and Non-TouchScreen laptops for each company.

```sql
SELECT 
  Company,
  SUM(CASE WHEN touchscreen = 1 THEN 1 ELSE 0 END) AS 'TouchScreen_Yes',
  SUM(CASE WHEN touchscreen = 0 THEN 1 ELSE 0 END) AS 'TouchScreen_No'
FROM laptop
GROUP BY Company, touchscreen;

```
Result:

![Touchscreen_yes_Vs_no](https://github.com/shanto173/SQL-2024/blob/main/image/Touchscreen_yes_no.png)

    Dell has the highest number of TouchScreen laptops (61) compared to other brands, showing a strong presence of touchscreen technology in its models.
    HP, Acer, Asus, and Lenovo also offer touchscreen models, but they predominantly manufacture Non-TouchScreen laptops.
    Some companies like Apple, Chuwi, MSI, Huawei, and Vero don’t have any TouchScreen models in the dataset.

#### 3.2 Bivariate Analysis (Company vs. CPU Brand)
The SQL query below calculates the number of laptops from each company that use Intel, AMD, and Samsung CPUs.

```sql
SELECT 
  company,
  SUM(CASE WHEN cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS 'Intel',
  SUM(CASE WHEN cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS 'AMD',
  SUM(CASE WHEN cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS 'Samsung'
FROM laptop
GROUP BY company;
```

Result:

![Company_brand_useage](https://github.com/shanto173/SQL-2024/blob/main/image/company_cpu_brand.png)
    
    Insights:
    Dell, HP, Lenovo, and Asus primarily use Intel CPUs in their laptops, with very few models using AMD.
    HP has the highest number of AMD laptops (23), followed by Lenovo (16).
    Only Samsung uses its own CPU in one of its laptops, while other companies exclusively use Intel or AMD.
    Brands like Apple, MSI, and Chuwi solely use Intel CPUs.


#### 3.3 Bivariate Analysis (Company vs. Average Price)(Category Vs numerical)
The SQL query below calculates the average laptop price for each Company.

```sql
SELECT 
  Company, 
  ROUND(AVG(Price)) AS Avg_Price
FROM laptop
GROUP BY Company;
```

Result:

![Company_Avg_Price](https://github.com/shanto173/SQL-2024/blob/main/image/Company%20Vs%20Average_price.png)
    
    Insights:
    Razer has the highest average laptop price (178,283), followed by LG (111,835), indicating these brands focus on premium, high-end laptops.
    Apple, Microsoft, and MSI also have high average prices, suggesting they cater to a higher-tier market.
    Chuwi, Vero, and Mediacom have the lowest average prices, indicating these brands offer budget laptops.
    HP, Acer, and Lenovo are positioned as mid-range brands, with average prices ranging between 33,796 and 58,377.


#### 3.3 Bivariate Analysis (Company vs. Price Range)(Category Vs numerical)
The SQL query calculates the minimum and maximum laptop prices for each company.

```sql
SELECT 
  Company, 
  MIN(Price) AS Min_Price, 
  MAX(Price) AS Max_Price
FROM laptop
GROUP BY Company;

```

Result:

![Company_Price_Range](https://github.com/shanto173/SQL-2024/blob/main/image/min_max_price.png)
    
       Insights:
    1. Razer has the widest price range, with laptops ranging from 54,825 to 324,955, indicating a broad product line that includes both premium and ultra-premium models.
    2. HP and Lenovo also show a wide price range, with HP ranging from 11,136 to 233,846 and Lenovo from 12,201 to 261,019.This suggests they offer both budget and high-end laptops.
    3. Vero and Chuwi are focused on budget-friendly laptops, with their maximum prices not exceeding 23,923.
    4. Apple and MSI tend to focus on mid-to-premium laptops, with Apple's prices ranging from 47,896 to 152,274, while MSI’s range is from 44,702 to 149,131.
    5. Google and Huawei offer products in a narrower range, primarily targeting the higher end of the market.



### 3. Missing Value Treatment 

#### 3.1 Missing Value Treatment (delet all those missing rows)
```sql
DELETE FROM laptop
WHERE price IS NULL;
```

#### 3.2 Missing Value Treatment(Imputing Missing Price by avg price)
The SQL query below updates the price column, filling any null values with the average price from the dataset.

```sql
UPDATE laptop
SET price = (SELECT AVG(price) FROM laptop)
WHERE price IS NULL;
```
    Reasoning:
    Imputation using mean is a common and simple technique to handle missing numerical data.
    In this case, I chose to use the average price because it provides a reasonable estimate that minimizes the impact of missing values on        further analysis.


#### 3.3 Missing Value Treatment (Imputing Missing Price by Company)
The SQL query below updates the price column by setting null values to the average price for each company, ensuring that the imputed values are more specific and relevant to the brand.
```sql
UPDATE laptop t1
SET price = (
    SELECT AVG(price) 
    FROM laptop t2 
    WHERE t1.company = t2.company
)
WHERE t1.price IS NULL;
```
    Explanation:
    The query calculates the average price for each company by grouping laptops by the company column.
    If a laptop's price is missing, the query updates that row with the average price of the laptops from the same company.


#### 3.4 Missing Value Treatment Based on Company and CPU Name
The fourth approach for treating missing values involves filling the price where it is NULL by calculating the average price for laptops that belong to the same Company and have the same cpu_name. This method ensures that we provide a meaningful and relevant estimate for missing prices based on similarities in brand and processor.

```sql
UPDATE laptop t1
SET price = (
    SELECT AVG(t2.price)
    FROM (SELECT * FROM laptop) t2
    WHERE t2.Company = t1.Company
    AND t2.cpu_name = t1.cpu_name
)
WHERE price IS NULL;

```
    Explanation:
    This method ensures that missing prices are filled with relevant averages based on both the laptop’s brand (Company) and its processor             (cpu_name). This provides more precision compared to using a simple overall average.


### 4 Feature Enginerring 

 After performing EDA now i have better knowledge about the data set but there are some column that are not usefull for analysis such as Height and width and inches, so with this three i can now create new column PPI which is much more helpfull for analysis.

 PPI formula is :
 
 ![PPI_formula](https://github.com/shanto173/SQL-2024/blob/main/image/ppi_formula.png)


#### 4.1 Adding a New Column for PPI Calculation

The first operation is to add a new column named `ppi` to the `laptop` table. This column will store the calculated PPI for each laptop.

```sql
ALTER TABLE laptop
ADD COLUMN ppi INTEGER;
```
#### 4.1.2 Updating the PPI Column with Calculated Values

```sql
UPDATE laptop t1
SET ppi = (
  SELECT ROUND(SQRT((width * width) + (height * height)) / Inches)
  FROM (SELECT * FROM laptop) t2
  WHERE t1.index = t2.index
);

```

#### 4.2 Updating the Screen Size Column with Categorized Values

There is another column name inches, because of there are so many value we can create a categories from that 
        when inches <= 14 then 'Small_size'
        when inches >14.1 and Inches < 16 then 'medium'
        when inches >= 16 then 'large'

#### 4.2.1 Adding a New Column for Screen Size Classification

We first create a new column, `screen_size`, in the `laptop` table. This column will hold the categorized values corresponding to the size of the screen.

```sql
ALTER TABLE laptop
ADD COLUMN screen_size VARCHAR(255) AFTER inches;
```
#### 4.2.2 Updating the Screen Size Column with Categorized Values

```sql
WITH temp AS (
  SELECT inches,
    CASE 
      WHEN inches <= 14 THEN 'Small_size'
      WHEN inches > 14.1 AND inches < 16 THEN 'medium'
      WHEN inches >= 16 THEN 'large'
    END AS 'screen_size'
  FROM laptop
)
UPDATE laptop t1
JOIN temp t2 ON t1.inches = t2.inches
SET t1.screen_size = t2.screen_size;
```

This query classifies the inches values into categories and updates the screen_size column for each laptop in the dataset accordingly.


### 5 Encoding (One-Hot Encoding)

One-hot encoding is used to convert the gpu_brand categorical column into binary features.

```sql
-- One-Hot Encoding for GPU brand
SELECT gpu_brand,
    CASE WHEN gpu_brand = 'Inter' THEN 1 ELSE 0 END AS 'inter',
    CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS 'amd', 
    CASE WHEN gpu_brand = 'nvidia' THEN 1 ELSE 0 END AS 'nvidia',
    CASE WHEN gpu_brand = 'arm' THEN 1 ELSE 0 END AS 'arm'
FROM laptop;
```

![One_hot_encoding](https://github.com/shanto173/SQL-2024/blob/main/image/one_hot_encode.png)
































































































