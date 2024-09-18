# Laptop Data Cleaning Project

This project involves cleaning a dataset of laptops, which includes steps such as backing up the table, removing unnecessary columns, handling missing values, removing duplicates, and transforming columns into more useful formats for analysis.

## Before cleaning data 
![Before Cleaning Data](./before_cleaning_data.png)

## Table of Contents

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










































