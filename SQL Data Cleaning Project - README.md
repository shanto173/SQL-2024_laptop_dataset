# SQL Data Cleaning Project

## Overview

This project involves cleaning a laptop dataset using various SQL techniques. The process includes creating backups, removing irrelevant columns, handling missing and duplicate data, and transforming several columns for better usability and consistency. The objective is to prepare the dataset for analysis by ensuring its accuracy, completeness, and structure.

## Steps for Data Cleaning

### 1. **Creating a Backup**
   - **Purpose**: Ensures the original dataset remains untouched for recovery purposes.
   - **SQL Queries**:
     ```sql
     CREATE TABLE laptop_backup LIKE laptop;
     INSERT INTO laptop_backup SELECT * FROM laptop;
     ```

### 2. **Checking Data Size**
   - **Action**: Verifying the number of rows and the memory the data occupies.
   - **SQL Queries**:
     ```sql
     SELECT COUNT(*) FROM laptop;
     SELECT data_length / 1024 FROM information_schema.tables 
     WHERE TABLE_SCHEMA = 'data_cleaning_project' AND table_name = 'laptop';
     ```

### 3. **Dropping Irrelevant Columns**
   - **Action**: The `Unnamed: 0` column was irrelevant and dropped.
   - **SQL Query**:
     ```sql
     ALTER TABLE laptop DROP COLUMN `Unnamed: 0`;
     ```

### 4. **Removing Null Values**
   - **Action**: Removed rows where all critical fields were `NULL`.
   - **SQL Query**:
     ```sql
     DELETE FROM laptop 
     WHERE `index` IN (SELECT `index` FROM laptop WHERE company IS NULL AND TypeName IS NULL);
     ```

### 5. **Handling Duplicates**
   - **Action**: Removed duplicate rows while retaining the first instance.
   - **SQL Query**:
     ```sql
     DELETE FROM laptop 
     WHERE `index` NOT IN (SELECT MIN(`index`) FROM laptop GROUP BY company, TypeName, Inches, ScreenResolution, Cpu);
     ```

### 6. **Column Data Transformation**
   - **Company and TypeName**: These columns were checked for consistency.
     ```sql
     SELECT DISTINCT Company FROM laptop;
     SELECT DISTINCT TypeName FROM laptop;
     ```

   - **Inches**: Converted `Inches` column to a decimal for better precision.
     ```sql
     ALTER TABLE laptop MODIFY COLUMN Inches DECIMAL(10,1);
     ```

### 7. **RAM Column Cleaning**
   - **Action**: Removed the 'GB' suffix and converted the column to an integer.
   - **SQL Query**:
     ```sql
     UPDATE laptop SET Ram = REPLACE(Ram, 'GB', '');
     ALTER TABLE laptop MODIFY COLUMN Ram INTEGER;
     ```

### 8. **Weight Column Cleaning**
   - **Action**: Removed 'kg' suffix and normalized data.
   - **SQL Query**:
     ```sql
     UPDATE laptop SET Weight = REPLACE(Weight, 'kg', '');
     ```

### 9. **Price Normalization**
   - **Action**: Rounded the prices to integers for memory efficiency.
   - **SQL Query**:
     ```sql
     UPDATE laptop SET Price = ROUND(Price);
     ALTER TABLE laptop MODIFY COLUMN Price INTEGER;
     ```

### 10. **Operating System Cleanup**
   - **Action**: Standardized OS names (e.g., `macos`, `windows`, `linux`).
   - **SQL Query**:
     ```sql
     UPDATE laptop SET opsys = CASE
         WHEN opsys LIKE '%mac%' THEN 'macos'
         WHEN opsys LIKE '%windows%' THEN 'windows'
         ELSE 'others'
     END;
     ```

### 11. **GPU Column Transformation**
   - **Action**: Split the `GPU` column into `gpu_brand` and `gpu_name`.
   - **SQL Query**:
     ```sql
     ALTER TABLE laptop ADD COLUMN gpu_brand VARCHAR(255), ADD COLUMN gpu_name VARCHAR(255);
     ```

### 12. **Memory Column Cleanup**
   - **Action**: Split the `Memory` column into `memory_space` and `memory_type` and processed any extendable memory.
   - **SQL Query**:
     ```sql
     ALTER TABLE laptop ADD COLUMN memory_space VARCHAR(255), ADD COLUMN memory_type VARCHAR(255);
     UPDATE laptop SET memory_space = SUBSTRING_INDEX(memory, ' ', 1);
     ```

### 13. **CPU Column Cleanup**
   - **Action**: Extracted CPU brand, name, and speed into separate columns.
   - **SQL Queries**:
     ```sql
     ALTER TABLE laptop ADD COLUMN cpu_brand VARCHAR(255), ADD COLUMN cpu_name VARCHAR(255), ADD COLUMN cpu_speed DECIMAL(10,1);
     ```

### 14. **Screen Resolution Column Cleanup**
   - **Action**: Split `ScreenResolution` into `height`, `width`, and `touchscreen`.
   - **SQL Query**:
     ```sql
     ALTER TABLE laptop ADD COLUMN height INTEGER, ADD COLUMN width INTEGER, ADD COLUMN touchscreen INTEGER;
     ```


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
## Final Dataset
The cleaned dataset contains the following columns:
- Company, TypeName, Inches, Ram, Weight, Price
- gpu_brand, gpu_name, memory_space, memory_type
- cpu_brand, cpu_name, cpu_speed
- height, width, touchscreen

## Conclusion
This process cleaned the dataset by removing irrelevant data, filling or dropping null values, normalizing columns, and enhancing data consistency. The final dataset is structured and ready for analysis.
