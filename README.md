# Laptop Data Cleaning Project

This project involves cleaning a dataset of laptops, which includes steps such as backing up the table, removing unnecessary columns, handling missing values, removing duplicates, and transforming columns into more useful formats for analysis.

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
```sql ALTER TABLE laptop DROP COLUMN `Unnamed: 0`;```
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
6. Step 8: GPU Column Modification
     first create 2 columns for storing specific GPU information
     Extract gpu_brand and gpu_name from the Gpu column and drop the old column:
   
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









































