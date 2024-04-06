CREATE DATABASE Inventory_Analysis;
USE Inventory_Analysis;

/****************************** RENAME TABLE ********************************/

RENAME TABLE 2017purchasepricesdec TO purchasepricesdec;
RENAME TABLE beginvfinal12312016 TO yearbeg_inventory;
RENAME TABLE endinvfinal12312016 TO yearend_inventory;
RENAME TABLE invoicepurchases12312016 TO purchase_invoice;
RENAME TABLE purchasesfinal12312016 TO product_purchases;
RENAME TABLE salesfinal12312016 TO product_sales;

/*************************** DATA CLEANING ******************************/

-- FOR purchasepricesdec Table

SELECT COUNT(*), COUNT(DISTINCT Brand) FROM purchasepricesdec;

SELECT * FROM purchasepricesdec;

ALTER TABLE purchasepricesdec
DROP  COLUMN `index`,
DROP  COLUMN `Classification`,
DROP  COLUMN `Size`;

SELECT * FROM purchasepricesdec WHERE `Description` IS NULL;
DELETE FROM purchasepricesdec WHERE `Description` IS NULL;

ALTER TABLE purchasepricesdec
MODIFY COLUMN Brand BIGINT NOT NULL PRIMARY KEY;

WITH cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY Brand,
								`Description`,
                                Price,
                                Volume,
                                PurchasePrice,
                                VendorNumber,
                                VendorName ORDER BY Brand) AS row_num
FROM purchasepricesdec)
SELECT * FROM cte WHERE row_num>1;

-- For yearbeg_inventory Table

SELECT COUNT(*), COUNT(DISTINCT InventoryId) FROM yearbeg_inventory;

SELECT * FROM yearbeg_inventory;

ALTER TABLE yearbeg_inventory
DROP  COLUMN `index`,
DROP  COLUMN `Size`;

SELECT * FROM yearbeg_inventory WHERE `Price` = 0;
SELECT avg(Price) FROM yearbeg_inventory;

SET @mean := (SELECT avg(Price) FROM yearbeg_inventory);
UPDATE yearbeg_inventory
SET Price=@mean
WHERE Price=0;

SELECT * FROM yearbeg_inventory WHERE `City` = "";

ALTER TABLE yearbeg_inventory 
MODIFY COLUMN startDate DATETIME;

ALTER TABLE yearbeg_inventory
MODIFY COLUMN InventoryId VARCHAR(50) NOT NULL PRIMARY KEY;

WITH cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY InventoryId,
								Store,
                                City,
                                Brand,
                                `Description`,
                                onHand,
                                Price,
                                startDate ORDER BY InventoryId) AS row_num
FROM yearbeg_inventory)
SELECT * FROM cte WHERE row_num>1;

-- For yearend_inventory Table

SELECT COUNT(*), COUNT(DISTINCT InventoryId) FROM yearend_inventory;

SELECT * FROM yearend_inventory;

ALTER TABLE yearend_inventory
DROP  COLUMN `index`,
DROP  COLUMN `Size`;

SELECT * FROM yearend_inventory WHERE `Price` = 0;

ALTER TABLE yearend_inventory 
MODIFY COLUMN endDate DATETIME;

ALTER TABLE yearend_inventory
MODIFY COLUMN InventoryId VARCHAR(50) NOT NULL PRIMARY KEY;

WITH cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY InventoryId,
								Store,
                                City,
                                Brand,
                                `Description`,
                                onHand,
                                Price,
                                startDate ORDER BY InventoryId) AS row_num
FROM yearbeg_inventory)
SELECT * FROM cte WHERE row_num>1;

SELECT * FROM yearend_inventory WHERE City IS NULL;

UPDATE yearend_inventory
SET City = "Not Known"
WHERE City IS NULL;

-- For purchase_invoice Table

SELECT COUNT(*),COUNT(DISTINCT VendorNumber), COUNT(DISTINCT PONumber) FROM purchase_invoice;

ALTER TABLE purchase_invoice
DROP  COLUMN `index`;

ALTER TABLE purchase_invoice 
MODIFY COLUMN InvoiceDate DATETIME,
MODIFY COLUMN PODate DATETIME,
MODIFY COLUMN PayDate DATETIME;

ALTER TABLE purchase_invoice
MODIFY COLUMN PONumber BIGINT NOT NULL PRIMARY KEY;

WITH cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY VendorNumber,
								VendorName,
                                InvoiceDate,
                                PONumber,
                                PODate,
                                PayDate,
                                Quantity,
                                Dollars,
                                Freight,
                                Approval ORDER BY PONumber) AS row_num
FROM purchase_invoice)
SELECT * FROM cte WHERE row_num>1;

SELECT * FROM purchase_invoice WHERE Approval LIKE "None";

UPDATE purchase_invoice
SET Approval = "Not Approved"
WHERE Approval LIKE "None";

-- FOR product_purchases Table

SELECT COUNT(*), COUNT(DISTINCT InventoryId),
COUNT(DISTINCT Store), COUNT(DISTINCT Brand) FROM product_purchases;

ALTER TABLE product_purchases
RENAME COLUMN `index` TO unique_id;

ALTER TABLE product_purchases
MODIFY COLUMN unique_id BIGINT NOT NULL PRIMARY KEY;

ALTER TABLE product_purchases
DROP  COLUMN Size,
DROP COLUMN Classification;

ALTER TABLE product_purchases 
MODIFY COLUMN PODate DATETIME,
MODIFY COLUMN ReceivingDate DATETIME,
MODIFY COLUMN InvoiceDate DATETIME,
MODIFY COLUMN PayDate DATETIME;

SELECT * FROM product_purchases WHERE `Dollars`= 0;
DELETE FROM product_purchases WHERE `Dollars`= 0;


WITH cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY InventoryId,
								Store,
                                Brand,
                                `Description`,
                                VendorNumber,
                                VendorName,
                                PONumber,
                                PODate,
                                ReceivingDate,
                                InvoiceDate,
                                PayDate,
                                PurchasePrice,
                                Quantity,
                                Dollars ORDER BY unique_id) AS row_num
FROM product_purchases)
SELECT * FROM cte WHERE row_num>1;


-- FOR product_sales Table

SELECT COUNT(*), COUNT(DISTINCT InventoryId),
COUNT(DISTINCT Store), COUNT(DISTINCT Brand) FROM product_sales;

ALTER TABLE product_sales
RENAME COLUMN `index` TO unique_id;

ALTER TABLE product_sales
MODIFY COLUMN unique_id BIGINT NOT NULL PRIMARY KEY;

ALTER TABLE product_sales
DROP  COLUMN Size,
DROP COLUMN Classification;


SELECT *, str_to_date(SalesDate,"%m/%d/%Y") FROM product_sales;
UPDATE product_sales SET SalesDate = str_to_date(SalesDate,"%m/%d/%Y");
ALTER TABLE product_sales 
MODIFY COLUMN SalesDate DATETIME;

WITH cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY InventoryId,
								Store,
                                Brand,
                                `Description`,
                                SalesQuantity,
                                SalesDollars,
                                SalesPrice,
                                SalesDate,
                                Volume,
                                ExciseTax,
                                VendorNo,
                                VendorName ORDER BY unique_id) AS row_num
FROM product_sales)
SELECT * FROM cte WHERE row_num>1;


/************************ ESTABLISH RELATIONSHIP **********************/
-- ONE TO MANY RELATIONSHIP BETWEEN purchasepricesdec and yearbeg_inventory
ALTER TABLE yearbeg_inventory
ADD CONSTRAINT FK_purchasedec_beg
FOREIGN KEY (Brand) REFERENCES purchasepricesdec(Brand);


-- ONE TO MANY RELATIONSHIP BETWEEN purchasepricesdec and yearend_inventory
ALTER TABLE yearend_inventory
ADD CONSTRAINT FK_purchasedec
FOREIGN KEY (Brand) REFERENCES purchasepricesdec(Brand);


-- ONE TO MANY RELATIONSHIP BETWEEN purchasepricesdec and product_sales
ALTER TABLE product_sales
ADD CONSTRAINT FK_purchasedec_sales
FOREIGN KEY (Brand) REFERENCES purchasepricesdec(Brand);


-- ONE TO MANY RELATIONSHIP BETWEEN purchasepricesdec and product_purchases
ALTER TABLE product_purchases
ADD CONSTRAINT FK_purchasedec_purchase
FOREIGN KEY (Brand) REFERENCES purchasepricesdec(Brand);

-- ONE TO MANY RELATIONSHIP BETWEEN purchase_invoice and product_purchases
ALTER TABLE product_purchases
ADD CONSTRAINT FK_purchaseinvoice
FOREIGN KEY (PONumber) REFERENCES purchase_invoice(PONumber);

