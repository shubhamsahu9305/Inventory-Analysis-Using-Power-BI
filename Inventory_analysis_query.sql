/************************************* POWER BI KPI QUERY ***************************************/
-- Maximum Payment Days
SELECT max(datediff(PayDate,PODate)) AS Maximum_Payment_Days FROM purchase_invoice;

-- Average Payment Days
SELECT round(avg(datediff(PayDate,PODate)),2) AS Average_Payment_Days FROM purchase_invoice;

-- Maximum Lead Time (in Days)
SELECT max(datediff(ReceivingDate,PODate)) AS Maximum_Lead_Time FROM product_purchases;

-- Average Lead Time (in Days)
SELECT round(avg(datediff(ReceivingDate,PODate)),2) AS Average_Lead_Time FROM product_purchases;

-- Total Purchase Amount (in $)
SELECT round(SUM(Dollars),2) FROM product_purchases 
WHERE YEAR(InvoiceDate)=2016;

-- Total Freight Charges (in $)
SELECT round(SUM(Freight),2) FROM purchase_invoice 
WHERE YEAR(InvoiceDate)=2016;

-- Sales to Purchase Ratio for January and February
WITH CTE_sales AS 
(
SELECT sum(SalesDollars) as total_sales FROM product_sales
WHERE month(SalesDate) IN (1,2) and year(SalesDate)=2016
),
CTE_purchase AS 
(
SELECT sum(Dollars) as total_purchase FROM product_purchases
WHERE month(PODate) IN (1,2) and year(PODate)=2016
)
SELECT round(total_sales/total_purchase,2) AS Sales_to_Purchase_Ratio
 FROM CTE_sales,CTE_purchase;
 

-- Net Profit Before Tax Deduction
WITH CTE AS 
(
SELECT ps.Brand, ps.Description, 
sum(SalesQuantity)*MAX(PurchasePrice) AS Cost_Price,
sum(SalesQuantity)*MAX(SalesPrice) AS Selling_Price
FROM product_sales ps
INNER JOIN purchasepricesdec pp
ON ps.Brand = pp.Brand
GROUP BY ps.Brand, ps.Description
)
SELECT round(SUM(Selling_Price) - SUM(Cost_Price),2) AS Net_profit_before_tax_deduction
FROM CTE;

-- Net Profit After Tax Deduction
WITH CTE_prod AS 
(
SELECT ps.Brand, ps.Description, 
sum(SalesQuantity)*MAX(PurchasePrice) AS Cost_Price,
sum(SalesQuantity)*MAX(SalesPrice) AS Selling_Price,
sum(ExciseTax) AS ExciseTax
FROM product_sales ps
INNER JOIN purchasepricesdec pp
ON ps.Brand = pp.Brand
GROUP BY ps.Brand, ps.Description
),
CTE_profit AS
(
SELECT (SUM(Selling_Price) - SUM(Cost_Price)) AS Net_profit_before_tax_deduction,
sum(ExciseTax) AS ExciseTax_deduction
FROM CTE_prod
)
SELECT round((Net_profit_before_tax_deduction - ExciseTax_deduction),2) AS Net_profit_after_tax_deduction
FROM CTE_profit;

-- Percentage Profit
WITH CTE_prod AS 
(
SELECT ps.Brand, ps.Description, 
sum(SalesQuantity)*MAX(PurchasePrice) AS Cost_Price,
sum(SalesQuantity)*MAX(SalesPrice) AS Selling_Price,
sum(ExciseTax) AS ExciseTax
FROM product_sales ps
INNER JOIN purchasepricesdec pp
ON ps.Brand = pp.Brand
GROUP BY ps.Brand, ps.Description
),
CTE_profit AS
(
SELECT (SUM(Selling_Price) - SUM(Cost_Price)) AS Net_profit_before_tax_deduction,
sum(Selling_Price) AS selling_price,
sum(Cost_Price) AS cost_price,
sum(ExciseTax) AS ExciseTax_deduction
FROM CTE_prod
)
SELECT round(((Net_profit_before_tax_deduction - ExciseTax_deduction)/cost_price)*100,2) AS profit_percentage
FROM CTE_profit;

-- Product Count
SELECT COUNT(Brand) FROM purchasepricesdec;

-- Year Beginning Value in Warehouse
WITH CTE AS
(
SELECT Brand, Description, sum(onHand) AS stock_qty
FROM yearbeg_inventory
GROUP BY Brand, Description
),
CTE1 AS
(
SELECT CTE.Brand, CTE.Description,
CTE.stock_qty*pdesc.PurchasePrice AS value_in_warehouse
FROM CTE INNER JOIN purchasepricesdec AS pdesc
ON CTE.Brand = pdesc.Brand
)
SELECT round(sum(value_in_warehouse),2) AS value_in_warehouse FROM CTE1;

-- Year End Value in Warehouse
WITH CTE AS
(
SELECT Brand, Description, sum(onHand) AS stock_qty
FROM yearend_inventory
GROUP BY Brand, Description
),
CTE1 AS
(
SELECT CTE.Brand, CTE.Description,
CTE.stock_qty*pdesc.PurchasePrice AS value_in_warehouse
FROM CTE INNER JOIN purchasepricesdec AS pdesc
ON CTE.Brand = pdesc.Brand
)
SELECT round(sum(value_in_warehouse),2) AS value_in_warehouse FROM CTE1;

-- Vendor Count
SELECT count(DISTINCT VendorNumber) AS vendor_count FROM purchase_invoice;

-- Store Count
SELECT count(DISTINCT Store) AS store_count FROM yearbeg_inventory;

-- Last Month Purchase
SELECT monthname(PODate) AS purchase_month,
sum(Dollars) AS total_purchase FROM product_purchases
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "December";

-- Month Before Last Month Purchase
SELECT monthname(PODate) AS purchase_month,
sum(Dollars) AS prev_total_purchase FROM product_purchases
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "November";

-- Month on Month Purchase
WITH CTE1 AS
(
SELECT monthname(PODate) AS purchase_month,
sum(Dollars) AS curr_total_purchase FROM product_purchases
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "December"
),
CTE2 AS
(
SELECT monthname(PODate) AS purchase_month,
sum(Dollars) AS prev_total_purchase FROM product_purchases
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "November"
)
SELECT round((curr_total_purchase - prev_total_purchase)/prev_total_purchase*100,2) AS MoM_Change
FROM CTE1 JOIN CTE2;

-- Last Month Freight Charges
SELECT monthname(PODate) AS purchase_month,
sum(Freight) AS total_freight_charges FROM purchase_invoice
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "December";

-- Month Before Last Month Freight Charges
SELECT monthname(PODate) AS purchase_month,
sum(Freight) AS total_freight_charges FROM purchase_invoice
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "November";

-- Month on Month Freight charges
WITH CTE1 AS
(
SELECT monthname(PODate) AS purchase_month,
sum(Freight) AS curr_total_freight_charges FROM purchase_invoice
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "December"
),
CTE2 AS
(
SELECT monthname(PODate) AS purchase_month,
sum(Freight) AS prev_total_freight_charges FROM purchase_invoice
WHERE year(PODate) = 2016
GROUP BY monthname(PODate)
HAVING purchase_month LIKE "November"
)
SELECT round((curr_total_freight_charges - prev_total_freight_charges)/prev_total_freight_charges*100,2) AS MoM_Change
FROM CTE1 JOIN CTE2;

/*************************************** POWER BI GRAPH QUERY **********************************/

## Month Wise Total Purchase Quantity , Purchase Amount and Freight Charges
SELECT monthname(InvoiceDate) AS purchase_month, 
sum(Quantity) AS total_purchase_quantity, 
round(sum(Dollars),2) AS total_purchase_amount, 
round(sum(Freight),2) AS total_freight_charges
FROM purchase_invoice
GROUP BY month(InvoiceDate), monthname(InvoiceDate)
ORDER BY month(InvoiceDate);


## Week Wise Total Sales and Total Excise Tax
SELECT weekofyear(SalesDate) AS sales_week,
round(sum(SalesDollars),2) AS total_sales_amount, 
round(sum(ExciseTax),2) AS total_excise_tax 
FROM product_sales
GROUP BY weekofyear(SalesDate) 
HAVING sales_week<>53
ORDER BY sales_week;


## Top 5 Products Having Highest Stock at the Year Beginning
WITH CTE AS (
SELECT Brand, Description, sum(onHand) as stock_qty,
DENSE_RANK() OVER (ORDER BY sum(onHand) DESC) AS prod_rank
FROM yearbeg_inventory
GROUP BY Brand,Description)
SELECT Brand, Description, stock_qty 
FROM CTE
WHERE prod_rank<=5;


## Top 5 Products Having Highest Stock at the Year End
WITH CTE AS (
SELECT Brand, Description, sum(onHand) as stock_qty,
DENSE_RANK() OVER (ORDER BY sum(onHand) DESC) AS prod_rank
FROM yearend_inventory
GROUP BY Brand,Description)
SELECT Brand, Description, stock_qty 
FROM CTE
WHERE prod_rank<=5;


## Products with No Stock at the Year Beginning
SELECT Brand, Description, sum(onHand) as stock_qty
FROM yearbeg_inventory
GROUP BY Brand,Description
HAVING stock_qty=0;


## Products with No Stock at the Year End
SELECT Brand, Description, sum(onHand) as stock_qty
FROM yearend_inventory
GROUP BY Brand,Description
HAVING stock_qty=0;


## Percentage of Approved Invoices
SELECT count(PONumber)/(SELECT COUNT(*) FROM purchase_invoice)*100 AS Approved_invoice_percentage
FROM purchase_invoice WHERE Approval NOT LIKE "Not Approved";

## Slow Moving Products
WITH CTE AS
(
SELECT Brand, 
Description,
sum(SalesQuantity) AS SalesQty,
DENSE_RANK() OVER (ORDER BY sum(SalesQuantity) ASC) AS qty_rank
FROM product_sales
GROUP BY Brand, Description
)
SELECT Brand, Description, SalesQty
FROM CTE WHERE qty_rank<=5;


## Best Selling Products
WITH CTE AS
(
SELECT Brand, 
Description,
sum(SalesQuantity) AS SalesQty,
DENSE_RANK() OVER (ORDER BY sum(SalesQuantity) DESC) AS qty_rank
FROM product_sales
GROUP BY Brand, Description
)
SELECT Brand, Description, SalesQty
FROM CTE WHERE qty_rank<=5;

## Problematic Products
WITH CTE AS
(
SELECT Brand, Description,
datediff(max(SalesDate),min(SalesDate)) AS total_sales_days,
sum(SalesQuantity) AS total_sales,
sum(SalesQuantity)/ datediff(max(SalesDate),min(SalesDate)) AS sales_per_day,
max(SalesQuantity) AS max_sales
FROM product_sales
GROUP BY Brand, Description
HAVING sales_per_day>max_sales
)
SELECT Brand, Description FROM CTE;

## TOP 5 Stores Having High Average Weekly Demand
WITH CTE1 AS
(
SELECT floor(datediff(max(SalesDate),min(SalesDate))/7) AS weeknum
FROM product_sales
),
CTE2 AS
(
SELECT Store, 
sum(SalesQuantity) AS total_qty_sold,
floor(sum(SalesQuantity)/(SELECT weeknum FROM CTE1)) AS avg_weekly_demand
FROM product_sales
GROUP BY Store
)
SELECT Store, avg_weekly_demand FROM CTE2
ORDER BY avg_weekly_demand DESC
LIMIT 5;

## Store WEEK on WEEK Sales
WITH CTE1 AS
(
SELECT Store, week(SalesDate) as weekday, 
round(sum(SalesPrice),2) AS total_sales
FROM product_sales
GROUP BY Store, week(SalesDate)
ORDER BY Store ASC
),
CTE2 AS
(
SELECT Store, weekday, total_sales,
LAG(total_sales,1) OVER (PARTITION BY Store ORDER BY weekday) AS prev_sales
FROM CTE1
)
SELECT Store, weekday,
round(ifnull(((total_sales - prev_sales)/prev_sales)*100,0),2) AS WOW_sales_growth_percent
FROM CTE2;


## Top 10 Products Havings High Average Weekly sales
WITH CTE1 AS
(
SELECT floor(datediff(max(SalesDate),min(SalesDate))/7) AS weeknum
FROM product_sales
),
CTE2 AS
(
SELECT Brand, Description, 
sum(SalesQuantity) AS total_qty_sold,
floor(sum(SalesQuantity)/(SELECT weeknum FROM CTE1)) AS avg_weekly_demand
FROM product_sales
GROUP BY Brand, Description
),
CTE3 AS
(
SELECT CTE2.Brand, CTE2.Description, 
round(CTE2.avg_weekly_demand*price_desc.Price,2) AS avg_weekly_sales,
RANK() OVER (ORDER BY round(CTE2.avg_weekly_demand*price_desc.Price,2) DESC) as sales_rank
FROM CTE2  INNER JOIN purchasepricesdec AS price_desc
ON price_desc.Brand = CTE2.Brand
)
SELECT Brand, Description, avg_weekly_sales FROM CTE3
WHERE sales_rank<=10;


## Top 5 Vendors Based On Purchase Amount
WITH CTE AS
(
SELECT VendorNumber, VendorName, sum(Dollars) AS total_purchase_amount,
RANK() over (ORDER BY sum(Dollars) DESC) as purchase_rank
FROM purchase_invoice
GROUP BY VendorNumber, VendorName
)
SELECT VendorNumber, VendorName, total_purchase_amount
FROM CTE WHERE purchase_rank<=5;


## Bottom 5 Vendors Based On Purchase Amount
WITH CTE AS
(
SELECT VendorNumber, VendorName, sum(Dollars) AS total_purchase_amount,
RANK() over (ORDER BY sum(Dollars) ASC) as purchase_rank
FROM purchase_invoice
GROUP BY VendorNumber, VendorName
)
SELECT VendorNumber, VendorName, total_purchase_amount
FROM CTE WHERE purchase_rank<=5;


## Top 5 Vendors at Each Store Based on Purchase Quantity
WITH CTE AS
(
SELECT Store, VendorNumber, VendorName, sum(Quantity) AS purchase_qty,
RANK() OVER (PARTITION BY Store ORDER BY sum(Quantity) DESC) as purchase_qty_rank
FROM product_purchases
GROUP BY Store, VendorNumber, VendorName
)
SELECT Store, VendorNumber, VendorName, purchase_qty
FROM CTE WHERE purchase_qty_rank<=5;


## ABC Analysis
CREATE VIEW abc_analysis AS
WITH CTE1 AS 
(
SELECT yb.Brand, yb.Description, floor((sum(yb.onHand)+sum(ye.onHand))/2) AS annual_units_sold
FROM yearbeg_inventory AS yb
INNER JOIN yearend_inventory AS ye ON yb.Brand = ye.Brand
GROUP BY yb.Brand, yb.Description
),
CTE2 AS
(
SELECT p.Brand, p.Description, p.PurchasePrice, CTE1.annual_units_sold,
p.PurchasePrice * CTE1.annual_units_sold AS annual_consumption
FROM purchasepricesdec AS p
LEFT JOIN CTE1 ON p.Brand = CTE1.Brand
),
CTE3 AS
(
SELECT Brand, Description, annual_consumption,
annual_consumption/(SELECT sum(annual_consumption) FROM CTE2)*100 AS percentage_annual_consumption
FROM CTE2
ORDER BY annual_consumption DESC
),
CTE4 AS
(
SELECT Brand, Description, annual_consumption, percentage_annual_consumption,
sum(percentage_annual_consumption) over (ORDER BY annual_consumption DESC) as annual_consuption_cumulative_sum
FROM CTE3
)
SELECT Brand, Description, annual_consuption_cumulative_sum,
CASE WHEN annual_consuption_cumulative_sum <=70 THEN "A [HIGH VALUE]"
WHEN annual_consuption_cumulative_sum <=90 THEN "B [MEDIUM VALUE]"
ELSE "C [LESS VALUE]"
END AS ABC_category
FROM CTE4;

-- ABC Analysis View Output
SELECT * FROM abc_analysis;


## XYZ Analysis
CREATE VIEW XYZ_analysis AS
WITH CTE1 AS
(
SELECT Brand, Description, 
weekofyear(SalesDate) AS sales_week, 
sum(SalesQuantity) AS sales_qty FROM product_sales
GROUP BY Brand, Description, weekofyear(SalesDate)
),
CTE2 AS
(
SELECT Brand, Description, 
stddev_pop(sales_qty) AS std_weekly_demand,
avg(sales_qty) AS avg_weekly_demand FROM CTE1
GROUP BY Brand, Description
),
CTE3 AS
(
SELECT Brand, Description, 
std_weekly_demand/avg_weekly_demand AS CV_weekly_demand,
DENSE_RANK() OVER (ORDER BY std_weekly_demand/avg_weekly_demand ASC) AS CV_weekly_demand_rank
FROM CTE2
)
SELECT Brand, Description, 
CASE WHEN CV_weekly_demand_rank <= 0.2*(SELECT max(CV_weekly_demand_rank) FROM CTE3) THEN "X [UNIFORM DEMAND]"
WHEN CV_weekly_demand_rank <= 0.5*(SELECT max(CV_weekly_demand_rank) FROM CTE3) THEN "Y [VARIABLE DEMAND]"
ELSE "Z [UNCERTAIN DEMAND]" END AS XYZ_Category
FROM CTE3;

-- XYZ Analysis View Output
SELECT * FROM xyz_analysis;


## Stock Analysis
CREATE VIEW product_stock_status AS
WITH CTE1 AS
(
SELECT Brand, Description, 
weekofyear(SalesDate) AS sales_week, 
sum(SalesQuantity) AS sales_qty FROM product_sales
GROUP BY Brand, Description, weekofyear(SalesDate)
),
CTE2 AS
(
SELECT Brand, Description, 
max(sales_qty) AS peak_weekly_demand,
avg(sales_qty) AS avg_weekly_demand FROM CTE1
GROUP BY Brand, Description
),
CTE3 AS
(
SELECT Brand, Description,
max(datediff(ReceivingDate,PODate)) AS max_lead_time,
avg(datediff(ReceivingDate,PODate)) AS avg_lead_time
FROM product_purchases
GROUP BY Brand, Description
),
CTE4 AS
(
SELECT p.Brand, p.Description,
peak_weekly_demand,avg_weekly_demand,max_lead_time,avg_lead_time
FROM purchasepricesdec AS p 
LEFT JOIN CTE2 ON p.Brand = CTE2.Brand
LEFT JOIN CTE3 ON p.Brand = CTE3.Brand
),
CTE5 AS
(
SELECT Brand, Description,peak_weekly_demand,avg_weekly_demand,
max_lead_time,avg_lead_time,
ceil(ifnull(((peak_weekly_demand*(max_lead_time/7)) - (avg_weekly_demand*(avg_lead_time/7))),0)) AS safety_stock
FROM CTE4
),
CTE6 AS
(
SELECT Brand, Description, safety_stock, 
ceil(ifnull((safety_stock+(avg_weekly_demand*(avg_lead_time/7))),0)) AS reorder_point
FROM CTE5
),
CTE7 AS
(
SELECT Brand, Description, sum(onHand) AS yearend_stock
FROM yearend_inventory
GROUP BY Brand, Description
),
CTE8 AS
(
SELECT CTE6.Brand, CTE6.Description, safety_stock, reorder_point, 
ifnull(yearend_stock,0) As yearend_stock
FROM CTE6 LEFT JOIN CTE7 ON CTE6.Brand = CTE7.Brand
),
CTE9 AS
(
SELECT Brand, Description,yearend_stock,
CASE WHEN reorder_point > yearend_stock THEN "YES"
ELSE "NO" END AS Do_we_need_to_order
FROM CTE8
)
SELECT Brand, Description,
CASE WHEN yearend_stock = 0 THEN "OUT OF STOCK"
WHEN Do_we_need_to_order LIKE "YES" THEN "BELOW REORDER POINT"
ELSE "IN STOCK" END AS stock_status
FROM CTE9;

-- Stock Analysis View Output
SELECT * FROM product_stock_status;

## Products that are Out of Stock and Stock Below Reorder Point
SELECT * FROM product_stock_status
WHERE stock_status LIKE "OUT OF STOCK" OR stock_status LIKE "BELOW REORDER POINT"

