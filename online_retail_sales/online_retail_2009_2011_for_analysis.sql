USE online_retail;

CREATE VIEW cleaned_online_retail2009_2011 AS 
SELECT 
	InvoiceID,
    StockCode,
    Description,
    Quantity,
    Price,
    CustomerID,
    Country,
    InvoiceDate
FROM online_retail2009_2010_staging2

UNION

SELECT 
	InvoiceID,
    StockCode,
    Description,
    Quantity,
    Price,
    CustomerID,
    Country,
    InvoiceDate
FROM online_retail2010_2011_staging2;

SELECT 'InvoiceID', 'StockCode', 'Description', 'Quantity', 'Price', 'CustomerID', 'Country', 'InvoiceDate'
UNION ALL
SELECT * FROM cleaned_online_retail2009_2011
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cleaned_online_retail2009_2011.csv'