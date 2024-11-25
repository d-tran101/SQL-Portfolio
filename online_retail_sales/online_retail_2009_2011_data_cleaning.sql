CREATE DATABASE IF NOT EXISTS online_retail;

USE online_retail;

-- creating table online_retail2009_2010 to import data

CREATE TABLE IF NOT EXISTS online_retail2009_2010 (
    InvoiceID VARCHAR(255),
    StockCode VARCHAR(255),
    Description VARCHAR(255),
    Quantity VARCHAR(255),
    InvoiceDate VARCHAR(255),
    Price VARCHAR(255),
    CustomerID VARCHAR(255),
    Country VARCHAR(255)
);

SET GLOBAL LOCAL_INFILE= ON;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/online_retail_II2009_2010.csv' INTO TABLE online_retail2009_2010
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- creating staging table for online_retail2009_2010 

CREATE TABLE online_retail2009_2010_staging
LIKE online_retail2009_2010;

INSERT online_retail2009_2010_staging
SELECT *
FROM online_retail2009_2010;

-- data cleaning 2009_2010 table; assuming that the transaction was recorded more than once due to an error

WITH duplicate_cte as (
SELECT InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country, 
	ROW_NUMBER() OVER(PARTITION BY InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country) as duplicate_check
FROM online_retail2009_2010_staging
)
SELECT *
FROM duplicate_cte
WHERE duplicate_check > 1;

-- create another staging table to remove duplicates

CREATE TABLE `online_retail2009_2010_staging2` (
  `InvoiceID` varchar(255) DEFAULT NULL,
  `StockCode` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Quantity` varchar(255) DEFAULT NULL,
  `InvoiceDate` varchar(255) DEFAULT NULL,
  `Price` varchar(255) DEFAULT NULL,
  `CustomerID` varchar(255) DEFAULT NULL,
  `Country` varchar(255) DEFAULT NULL,
  `duplicate_check` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO online_retail2009_2010_staging2
SELECT InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country, 
	ROW_NUMBER() OVER(PARTITION BY InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country) as duplicate_check
FROM online_retail2009_2010_staging;

DELETE FROM online_retail2009_2010_staging2
WHERE duplicate_check > 1;

-- standardizing data

SELECT InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country
FROM online_retail2009_2010_staging2;

-- standardizing invoiceID column

UPDATE online_retail2009_2010_staging2
SET InvoiceID = TRIM(InvoiceID);

-- standardizng StockCode column

UPDATE online_retail2009_2010_staging2
SET StockCode = TRIM(StockCode);

-- standardizing Description column

UPDATE online_retail2009_2010_staging2
SET Description = TRIM(Description);

UPDATE online_retail2009_2010_staging2
SET Description = UPPER(Description);

UPDATE online_retail2009_2010_staging2 -- adding a space before and after the '+' sign for every description entry that has a '+' symbol
SET description = REPLACE(description, '+', ' + ')
WHERE description LIKE '%+%' AND description NOT LIKE '% + %';

UPDATE online_retail2009_2010_staging2
SET description = REPLACE(description, ' , ', ',')
WHERE description LIKE '% , %';

UPDATE online_retail2009_2010_staging2 -- removing extra spaces between comma
SET description = REPLACE(description, ',', ', ')
WHERE description LIKE '%,%';

UPDATE online_retail2009_2010_staging2 -- adding only one space behind the comma
SET description = TRIM(TRAILING '.' FROM description);

UPDATE online_retail2009_2010_staging2 -- removing double spaces
SET description = REPLACE(description, '  ', ' ');

UPDATE online_retail2009_2010_staging2
SET description = REPLACE(description, 'RETRO SPOT', 'RETROSPOT')
WHERE description like '%retro spot%';


CREATE VIEW replace_missing_values as -- filling blank description entries with description entries from other rows with the same stock code
SELECT DISTINCT stockcode, description
FROM online_retail2009_2010_staging2
where description <> '';

UPDATE online_retail2009_2010_staging2 p1
JOIN replace_missing_values p2 ON p1.stockcode = p2.stockcode
SET p1.description = p2.description
WHERE p1.description = '';


UPDATE online_retail2009_2010_staging2 -- removing *
SET description = REPLACE(description, '*', '');


CREATE VIEW replace_values_special_characters as -- filling '?' description entries with description entries from other rows with the same stock code
SELECT DISTINCT stockcode, description
FROM online_retail2009_2010_staging2
where description <> '?';

UPDATE online_retail2009_2010_staging2 p1 
JOIN replace_values_special_characters p2 ON p1.stockcode = p2.stockcode
SET p1.description = p2.description
WHERE p1.Description LIKE '%?%';

UPDATE online_retail2009_2010_staging2 -- replacing other unmatched blank description entries with 'unknown'
SET Description = 'Unknown'
WHERE Description = ''

UPDATE online_retail2009_2010_staging2 -- replacing other '?' description entries with 'unknown'
SET description = REPLACE(Description, '?', 'Unknown')

-- standardizing Quantity column

UPDATE online_retail2009_2010_staging2
SET Quantity = TRIM(Quantity);

-- standardizing InvoiceDate column

UPDATE online_retail2009_2010_staging2
SET InvoiceDate = TRIM(InvoiceDate);

UPDATE online_retail2009_2010_staging2 -- changing to valid datetime data type
SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i');

-- standardizing CustomerId column

UPDATE online_retail2009_2010_staging2
SET CustomerId = TRIM(CustomerId);

UPDATE online_retail2009_2010_staging2 -- missing CustomerID entries are replaced with 0 
SET CustomerId = CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 0 ELSE CustomerID END;

-- standardizing Country column

UPDATE online_retail2009_2010_staging2
SET Country = TRIM(Country);

UPDATE online_retail2009_2010_staging2 -- replacing abbrevation with full name of country
SET Country = REPLACE(country, 'RSA', 'Republic of South Africa');

UPDATE online_retail2009_2010_staging2 -- replacing abbrevation with full name of country
SET Country = REPLACE(country, 'EIRE', 'Republic of Ireland');

UPDATE online_retail2009_2010_staging2 -- replacing abbrevation with full name of country
SET Country = REPLACE(country, 'USA', 'United States of America');

-- modifying column types after cleaning

ALTER TABLE online_retail2009_2010_staging2
DROP COLUMN duplicate_check;

ALTER TABLE online_retail2009_2010_staging2
MODIFY COLUMN InvoiceID VARCHAR(25),
MODIFY COLUMN StockCode VARCHAR(25),
MODIFY COLUMN Description VARCHAR(100),
MODIFY COLUMN Quantity INT,
MODIFY COLUMN InvoiceDate DATETIME,
MODIFY COLUMN Price DECIMAL(10,2),
MODIFY COLUMN CustomerID VARCHAR(25),
MODIFY COLUMN Country VARCHAR(50);

-- adding new column Revenue; Quantity * Price

ALTER TABLE online_retail2009_2010_staging2
ADD COLUMN Revenue DECIMAL(10,2);

UPDATE online_retail2009_2010_staging2
SET Revenue = Quantity * Price;

-- reordering columns for readability and organization

ALTER TABLE online_retail2009_2010_staging2
MODIFY COLUMN Price DECIMAL(10,2) AFTER Quantity;

ALTER TABLE online_retail2009_2010_staging2
MODIFY COLUMN Revenue DECIMAL(10,2) AFTER Price;

ALTER TABLE online_retail2009_2010_staging2
MODIFY COLUMN CustomerID VARCHAR(25) AFTER Revenue;

ALTER TABLE online_retail2009_2010_staging2
MODIFY COLUMN Country VARCHAR(50) AFTER CustomerID;

-- creating table online_retail2009_2010 to import data

CREATE TABLE IF NOT EXISTS online_retail2010_2011 (
    InvoiceID VARCHAR(255),
    StockCode VARCHAR(255),
    Description VARCHAR(255),
    Quantity VARCHAR(255),
    InvoiceDate VARCHAR(255),
    Price VARCHAR(255),
    CustomerID VARCHAR(255),
    Country VARCHAR(255)
);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/online_retail_II2010_2011.csv' INTO TABLE online_retail2010_2011
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- creating staging table for online_retail2010-2011

CREATE TABLE online_retail2010_2011_staging
LIKE online_retail2010_2011;

INSERT online_retail2010_2011_staging
SELECT *
FROM online_retail2010_2011;

-- creating another staging table to remove duplicates

CREATE TABLE `online_retail2010_2011_staging2` (
  `InvoiceID` varchar(255) DEFAULT NULL,
  `StockCode` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Quantity` varchar(255) DEFAULT NULL,
  `InvoiceDate` varchar(255) DEFAULT NULL,
  `Price` varchar(255) DEFAULT NULL,
  `CustomerID` varchar(255) DEFAULT NULL,
  `Country` varchar(255) DEFAULT NULL,
  `duplicate_check` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO online_retail2010_2011_staging2
SELECT InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country, 
	ROW_NUMBER() OVER(PARTITION BY InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country) as duplicate_check
FROM online_retail2010_2011_staging;

DELETE FROM online_retail2010_2011_staging2
WHERE duplicate_check > 1;

-- standardizing data

SELECT InvoiceID, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country
FROM online_retail2010_2011_staging2;

-- standardizing invoiceID column

UPDATE online_retail2010_2011_staging2
SET InvoiceID = TRIM(InvoiceID);

-- standardizng StockCode column

UPDATE online_retail2010_2011_staging2
SET StockCode = TRIM(StockCode);

-- standardizing Description column

UPDATE online_retail2010_2011_staging2
SET Description = TRIM(Description);

UPDATE online_retail2010_2011_staging2
SET Description = UPPER(Description);

UPDATE online_retail2010_2011_staging2 -- adding a space before and after the '+' sign for every description entry that has a '+' symbol
SET description = REPLACE(description, '+', ' + ')
WHERE description LIKE '%+%' AND description NOT LIKE '% + %';

UPDATE online_retail2010_2011_staging2 
SET description = REPLACE(description, ' , ', ',')
WHERE description LIKE '% , %';

UPDATE online_retail2010_2011_staging2 -- removing extra spaces between comma
SET description = REPLACE(description, ',', ', ')
WHERE description LIKE '%,%';

UPDATE online_retail2010_2011_staging2 -- adding only one space behind the comma
SET description = TRIM(TRAILING '.' FROM description);

UPDATE online_retail2010_2011_staging2 -- removing double spaces
SET description = REPLACE(description, '  ', ' ');

UPDATE online_retail2010_2011_staging2
SET description = REPLACE(description, 'RETRO SPOT', 'RETROSPOT')
WHERE description like '%retro spot%';


CREATE VIEW replace_missing_values2 as -- filling blank description entries with description entries from other rows with the same stock code
SELECT DISTINCT stockcode, description
FROM online_retail2010_2011_staging2
where description <> '';

UPDATE online_retail2010_2011_staging2 p1
JOIN replace_missing_values2 p2 ON p1.stockcode = p2.stockcode
SET p1.description = p2.description
WHERE p1.description = '';


UPDATE online_retail2010_2011_staging2 -- removing *
SET description = REPLACE(description, '*', '');


CREATE VIEW replace_values_special_characters2 as -- filling '?' description entries with description entries from other rows with the same stock code
SELECT DISTINCT stockcode, description
FROM online_retail2010_2011_staging2
where description <> '?';

UPDATE online_retail2010_2011_staging2 p1
JOIN replace_values_special_characters2 p2 ON p1.stockcode = p2.stockcode
SET p1.description = p2.description
WHERE p1.Description LIKE '%?%';

UPDATE online_retail2010_2011_staging2 -- replacing other unmatched blank description entries with 'unknown'
SET Description = 'Unknown'
WHERE Description = ''

UPDATE online_retail2010_2011_staging2 -- replacing other unmatched blank description entries with '?'
SET description = REPLACE(description, '?', 'Unknown')

-- standardizing Quantity column

UPDATE online_retail2010_2011_staging2
SET Quantity = TRIM(Quantity);

-- standardizing InvoiceDate column

UPDATE online_retail2010_2011_staging2
SET InvoiceDate = TRIM(InvoiceDate);

UPDATE online_retail2010_2011_staging2 -- changing to valid datetime data type
SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i');

-- standardizing CustomerId column

UPDATE online_retail2010_2011_staging2
SET CustomerId = TRIM(CustomerId);

UPDATE online_retail2010_2011_staging2 -- missing CustomerID entries are replaced with 0 
SET CustomerId = CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 0 ELSE CustomerID END;

-- standardizing Country column

UPDATE online_retail2010_2011_staging2
SET Country = TRIM(Country);

UPDATE online_retail2010_2011_staging2 -- replacing abbrevation with full name of country
SET Country = REPLACE(country, 'RSA', 'Republic of South Africa');

UPDATE online_retail2010_2011_staging2 -- replacing abbrevation with full name of country
SET Country = REPLACE(country, 'EIRE', 'Republic of Ireland');

UPDATE online_retail2010_2011_staging2 -- replacing abbrevation with full name of country
SET Country = REPLACE(country, 'USA', 'United States of America');

-- modifying column types after cleaning

ALTER TABLE online_retail2010_2011_staging2
DROP COLUMN duplicate_check;

ALTER TABLE online_retail2010_2011_staging2
MODIFY COLUMN InvoiceID VARCHAR(25),
MODIFY COLUMN StockCode VARCHAR(25),
MODIFY COLUMN Description VARCHAR(100),
MODIFY COLUMN Quantity INT,
MODIFY COLUMN InvoiceDate DATETIME,
MODIFY COLUMN Price DECIMAL(10,2),
MODIFY COLUMN CustomerID VARCHAR(25),
MODIFY COLUMN Country VARCHAR(50);

-- adding new column Revenue; Quantity * Price

ALTER TABLE online_retail2010_2011_staging2
ADD COLUMN Revenue DECIMAL(10,2);

UPDATE online_retail2010_2011_staging2
SET Revenue = Quantity * Price;

-- reordering columns for readability and organization

ALTER TABLE online_retail2010_2011_staging2
MODIFY COLUMN Price DECIMAL(10,2) AFTER Quantity;

ALTER TABLE online_retail2010_2011_staging2
MODIFY COLUMN Revenue DECIMAL(10,2) AFTER Price;

ALTER TABLE online_retail2010_2011_staging2
MODIFY COLUMN CustomerID VARCHAR(25) AFTER Revenue;

ALTER TABLE online_retail2010_2011_staging2
MODIFY COLUMN Country VARCHAR(50) AFTER CustomerID;
