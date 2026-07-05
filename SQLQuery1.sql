CREATE TABLE dbo.Almarai_Customers (
    Customer_ID      nvarchar(50)  NULL,
    Customer_Name    nvarchar(50)  NULL,
    Customer_Type    nvarchar(50)  NULL,
    Region           nvarchar(50)  NULL,
    City             nvarchar(50)  NULL,
    Loyalty_Points   smallint      NULL,
    Join_Date        datetime2(7)  NULL,
    Credit_Limit_SAR int           NULL,
    Is_Active        bit           NULL
);



SELECT
    Region,
    AVG(Credit_Limit_SAR) AS AverageCreditLimit_SAR
FROM
    dbo.Almarai_Customers
WHERE
    Is_Active = 1 -- Filter for active customers
GROUP BY
    Region
ORDER BY
    Region;




SELECT
    CASE
        WHEN Loyalty_Points >= 1000 THEN 'High Value Customer'
        WHEN Loyalty_Points >= 500  THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS Customer_Loyalty_Segment,
    COUNT(Customer_ID) AS NumberOfCustomers
FROM
    dbo.Almarai_Customers
WHERE
    Loyalty_Points IS NOT NULL -- Exclude customers with no loyalty points recorded
GROUP BY
    CASE
        WHEN Loyalty_Points >= 1000 THEN 'High Value Customer'
        WHEN Loyalty_Points >= 500  THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END
ORDER BY
    NumberOfCustomers DESC;





SELECT
    Customer_ID,
    Customer_Name,
    Join_Date,
    Credit_Limit_SAR,
    City,
    Region
FROM
    dbo.Almarai_Customers
WHERE
    Is_Active = 1 -- Only active customers
    AND Join_Date >= DATEADD(year, -1, GETDATE()) -- Joined within the last year
    AND Credit_Limit_SAR > 50000 -- Example threshold for a high credit limit
ORDER BY
    Join_Date DESC, Credit_Limit_SAR DESC;

-- DDL for the Almarai_Inventory table, exactly as seen in the image.
-- All columns are nullable as specified in the screenshot.

CREATE TABLE dbo.Almarai_Inventory (
    Inventory_ID NVARCHAR(50) NULL,
    Snapshot_Date DATETIME2(7) NULL,
    Product_ID NVARCHAR(50) NULL,
    Warehouse NVARCHAR(50) NULL,
    Stock_Level SMALLINT NULL,
    Reorder_Level TINYINT NULL,
    Stock_Value_SAR FLOAT NULL,
    Stock_Status NVARCHAR(50) NULL,
    [Year] SMALLINT NULL, -- 'Year' is a reserved keyword, enclosed in brackets.
    Month TINYINT NULL
);


-- Query 1: Inventory Summary by Warehouse and Product
-- This view aggregates key inventory metrics per warehouse and product,
-- useful for high-level stock management and performance tracking.
CREATE VIEW dbo.vw_InventorySummaryByWarehouseProduct AS
SELECT
    Warehouse,
    Product_ID,
    AVG(CAST(Stock_Level AS DECIMAL(10,2))) AS Average_Stock_Level,
    SUM(Stock_Value_SAR) AS Total_Stock_Value_SAR,
    COUNT(DISTINCT Inventory_ID) AS Number_of_Inventory_Items,
    MAX(Snapshot_Date) AS Latest_Snapshot_Date
FROM
    dbo.Almarai_Inventory
GROUP BY
    Warehouse,
    Product_ID;

-- Query 2: Detailed Inventory Status Categorization
-- This view adds a calculated column 'Inventory_Status_Category' using CASE logic
-- to quickly identify items based on their stock level relative to reorder level.
CREATE VIEW dbo.vw_DetailedInventoryStatus AS
SELECT
    Inventory_ID,
    Snapshot_Date,
    Product_ID,
    Warehouse,
    Stock_Level,
    Reorder_Level,
    Stock_Value_SAR,
    Stock_Status,
    [Year],
    Month,
    CASE
        WHEN Stock_Level IS NULL THEN 'Unknown Stock Level'
        WHEN Reorder_Level IS NULL THEN 'Reorder Level Not Defined'
        WHEN Stock_Level <= Reorder_Level THEN 'Below Reorder Level (Critical)'
        WHEN Stock_Level <= Reorder_Level * 1.5 THEN 'Approaching Reorder Level (Warning)'
        ELSE 'Healthy Stock'
    END AS Inventory_Status_Category
FROM
    dbo.Almarai_Inventory;

-- Query 3: Monthly Inventory Value and Level Trends
-- This view provides an aggregated monthly overview of total stock levels and values,
-- useful for historical analysis and forecasting inventory trends over time.
CREATE VIEW dbo.vw_MonthlyInventoryTrends AS
SELECT
    [Year],
    Month,
    SUM(Stock_Level) AS Total_Monthly_Stock_Level,
    SUM(Stock_Value_SAR) AS Total_Monthly_Stock_Value_SAR,
    COUNT(DISTINCT Product_ID) AS Number_of_Unique_Products_Tracked,
    MIN(Snapshot_Date) AS First_Snapshot_in_Month,
    MAX(Snapshot_Date) AS Last_Snapshot_in_Month
FROM
    dbo.Almarai_Inventory
GROUP BY
    [Year],
    Month
ORDER BY
    [Year],
    Month;

    -- DDL for the dbo.Almarai_Products table
-- Note: Product_ID is a strong candidate for a PRIMARY KEY, 
-- but the screenshot shows it as nullable, so no PRIMARY KEY constraint is added here 
-- to exactly match the visible definition.
CREATE TABLE dbo.Almarai_Products (
    Product_ID      nvarchar(50) NULL,
    Product_Name    nvarchar(50) NULL,
    Category        nvarchar(50) NULL,
    Unit_Price_SAR  float        NULL,
    Cost_Price_SAR  float        NULL,
    Supplier_ID     nvarchar(50) NULL,
    Launch_Date     datetime2(7) NULL,
    Is_Active       nvarchar(50) NULL,
    Unit_of_Measure nvarchar(50) NULL
);

-- Optional: Insert sample data for testing the queries
-- This block can be removed if you have actual data.
INSERT INTO dbo.Almarai_Products (Product_ID, Product_Name, Category, Unit_Price_SAR, Cost_Price_SAR, Supplier_ID, Launch_Date, Is_Active, Unit_of_Measure) VALUES
('P001', 'Fresh Milk 1L', 'Dairy', 7.50, 5.00, 'S001', '2022-01-15', 'Yes', 'Liter'),
('P002', 'Yogurt Plain 170g', 'Dairy', 2.80, 1.80, 'S001', '2022-03-10', 'Yes', 'Gram'),
('P003', 'Orange Juice 1.4L', 'Beverages', 12.00, 8.50, 'S002', '2023-05-20', 'Yes', 'Liter'),
('P004', 'Cheese Slices 200g', 'Dairy', 9.00, 6.00, 'S001', '2021-11-01', 'No', 'Gram'),
('P005', 'Bakery Bread', 'Bakery', 4.50, 2.50, 'S003', '2023-01-01', 'Yes', 'Unit'),
('P006', 'Strawberry Yogurt 170g', 'Dairy', 3.00, 2.00, 'S001', '2023-08-01', 'Yes', 'Gram'),
('P007', 'Apple Juice 1L', 'Beverages', 10.00, 7.00, 'S002', '2023-09-15', 'Yes', 'Liter'),
('P008', 'Water Bottle 0.5L', 'Beverages', 1.50, 0.80, 'S004', '2023-10-01', 'Yes', 'Liter'),
('P009', 'Chocolate Milk 1L', 'Dairy', 8.00, 5.50, 'S001', '2022-06-01', 'No', 'Liter'),
('P010', 'Croissant', 'Bakery', 3.00, 1.50, 'S003', '2023-02-10', 'Yes', 'Unit');

SELECT
    Category,
    COUNT(Product_ID) AS NumberOfProducts,
    AVG(Unit_Price_SAR) AS AverageSellingPrice_SAR,
    AVG(Cost_Price_SAR) AS AverageCostPrice_SAR,
    AVG(Unit_Price_SAR - Cost_Price_SAR) AS AverageProfitPerUnit_SAR,
    AVG(
        CASE
            WHEN Unit_Price_SAR > 0 THEN ((Unit_Price_SAR - Cost_Price_SAR) / Unit_Price_SAR) * 100
            ELSE 0 -- Handle cases where Unit_Price_SAR is zero or null to avoid division by zero
        END
    ) AS AverageGrossProfitMarginPercentage
FROM
    dbo.Almarai_Products
WHERE
    Unit_Price_SAR IS NOT NULL AND Cost_Price_SAR IS NOT NULL
GROUP BY
    Category
ORDER BY
    AverageGrossProfitMarginPercentage DESC;

    SELECT
    Product_ID,
    Product_Name,
    Category,
    Unit_Price_SAR,
    Launch_Date,
    Supplier_ID
FROM
    dbo.Almarai_Products
WHERE
    Is_Active = 'Yes' -- Filter for active products
    AND Launch_Date >= DATEADD(year, -1, GETDATE()) -- Filter for products launched in the last 12 months
ORDER BY
    Launch_Date DESC, Category, Product_Name;


SELECT
    PriceTier,
    COUNT(Product_ID) AS NumberOfProductsInTier,
    AVG(Unit_Price_SAR) AS AveragePriceInTier_SAR
FROM
    (SELECT
        Product_ID,
        Unit_Price_SAR,
        CASE
            WHEN Unit_Price_SAR <= 5.00 THEN 'Budget'
            WHEN Unit_Price_SAR > 5.00 AND Unit_Price_SAR <= 10.00 THEN 'Standard'
            WHEN Unit_Price_SAR > 10.00 THEN 'Premium'
            ELSE 'Unspecified'
        END AS PriceTier
    FROM
        dbo.Almarai_Products
    WHERE
        Unit_Price_SAR IS NOT NULL
    ) AS TieredProducts
GROUP BY
    PriceTier
ORDER BY
    CASE PriceTier
        WHEN 'Budget' THEN 1
        WHEN 'Standard' THEN 2
        WHEN 'Premium' THEN 3
        ELSE 4
    END;


    -- 1. DDL for the extracted table structure
-- This CREATE TABLE statement documents the original table structure exactly as seen.
-- No new physical tables are created for derived/calculated logic.
CREATE TABLE dbo.Almarai_Sales (
    Sale_ID          nvarchar(50) NULL,
    Date             datetime2(7) NULL,
    Product_ID       nvarchar(50) NULL,
    Customer_ID      nvarchar(50) NULL,
    Quantity         smallint     NULL,
    Unit_Price_SAR   float        NULL,
    Discount_Rate    float        NULL, -- Assumed to be a decimal like 0.1 for 10%
    Total_Amount_SAR float        NULL, -- Assumed to be the final price after discount
    Payment_Method   nvarchar(50) NULL,
    Sales_Channel    nvarchar(50) NULL,
    Year             smallint     NULL,
    Month            tinyint      NULL,
    Quarter          tinyint      NULL
);


-- 2. Business SQL Queries

-- Query 1: Monthly Sales Performance by Product
-- This query aggregates total sales amount and quantity sold for each product
-- on a monthly basis, providing insights into product performance over time.
SELECT
    s.Year,
    s.Month,
    s.Product_ID,
    SUM(s.Total_Amount_SAR) AS Monthly_Total_Sales_SAR,
    SUM(s.Quantity) AS Monthly_Total_Quantity_Sold
FROM
    dbo.Almarai_Sales AS s
GROUP BY
    s.Year,
    s.Month,
    s.Product_ID
ORDER BY
    s.Year,
    s.Month,
    Monthly_Total_Sales_SAR DESC;

-- Query 2: Customer Segmentation by Spending and Average Discount Received
-- This query categorizes customers based on their total spending, calculates
-- their total spending, average discount rate received, and number of purchases.
-- It uses a CTE (Common Table Expression) for derived logic without creating a new table.
WITH CustomerSpendingSummary AS (
    SELECT
        Customer_ID,
        SUM(Total_Amount_SAR) AS Total_Spending_SAR,
        AVG(Discount_Rate) AS Average_Discount_Rate_Received,
        COUNT(DISTINCT Sale_ID) AS Number_of_Purchases
    FROM
        dbo.Almarai_Sales
    GROUP BY
        Customer_ID
)
SELECT
    cs.Customer_ID,
    cs.Total_Spending_SAR,
    cs.Average_Discount_Rate_Received,
    cs.Number_of_Purchases,
    CASE
        WHEN cs.Total_Spending_SAR >= 10000 THEN 'High Value Customer'
        WHEN cs.Total_Spending_SAR >= 2000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS Customer_Segment -- Derived column using CASE logic
FROM
    CustomerSpendingSummary AS cs
ORDER BY
    cs.Total_Spending_SAR DESC;

-- Query 3: Daily Sales Analysis with Gross Revenue and Discount Amount
-- This query calculates daily total sales, and derives two new metrics:
-- 'Daily_Gross_Sales_SAR' (revenue before discount) and 'Daily_Discount_Amount_SAR'.
-- This demonstrates creating calculated values directly in the SELECT statement.
SELECT
    CAST(s.Date AS date) AS Sale_Date, -- Truncates datetime to date for daily aggregation
    SUM(s.Quantity) AS Total_Quantity_Sold_Daily,
    SUM(s.Total_Amount_SAR) AS Daily_Net_Sales_SAR,
    SUM(s.Quantity * s.Unit_Price_SAR) AS Daily_Gross_Sales_SAR, -- Derived: Original Revenue before discount
    SUM(s.Quantity * s.Unit_Price_SAR * s.Discount_Rate) AS Daily_Discount_Amount_SAR -- Derived: Total discount given daily
FROM
    dbo.Almarai_Sales AS s
GROUP BY
    CAST(s.Date AS date)
ORDER BY
    Sale_Date;



-- DDL for the Almarai_Suppliers table exactly as seen in the image,
-- with Supplier_ID inferred as the primary key.
CREATE TABLE dbo.Almarai_Suppliers (
    Supplier_ID nvarchar(50) NOT NULL PRIMARY KEY, -- Inferred Primary Key
    Supplier_Name nvarchar(50) NULL,
    Supplier_Type nvarchar(50) NULL,
    Country nvarchar(50) NULL,
    City nvarchar(50) NULL,
    Contract_Start_Date datetime2(7) NULL,
    Rating float NULL,
    Payment_Terms_Days tinyint NULL,
    Is_Active bit NULL
);
GO

-- BUSINESS SQL QUERIES (using VIEWS for derived logic, as requested)

-- Query 1: Summary of Supplier Performance and Payment Terms by Country and Supplier Type
-- This view aggregates key metrics like count, average rating, and average payment terms
-- for each combination of country and supplier type.
CREATE VIEW dbo.vw_SupplierPerformanceSummary AS
SELECT
    Country,
    Supplier_Type,
    COUNT(Supplier_ID) AS NumberOfSuppliers,
    AVG(Rating) AS AverageRating,
    AVG(CAST(Payment_Terms_Days AS decimal(5,2))) AS AveragePaymentTermsDays
FROM
    dbo.Almarai_Suppliers
WHERE
    Is_Active = 1 -- Focus on active suppliers
GROUP BY
    Country,
    Supplier_Type;
GO

-- Query 2: Active Suppliers with Categorized Contract Length
-- This view categorizes active suppliers based on how long their contract has been active
-- since the Contract_Start_Date, using current date for comparison.
CREATE VIEW dbo.vw_ActiveSupplierContractStatus AS
SELECT
    Supplier_ID,
    Supplier_Name,
    Supplier_Type,
    Country,
    Contract_Start_Date,
    DATEDIFF(year, Contract_Start_Date, GETDATE()) AS Contract_Years_Active,
    CASE
        WHEN DATEDIFF(year, Contract_Start_Date, GETDATE()) < 1 THEN 'New (Less than 1 Year)'
        WHEN DATEDIFF(year, Contract_Start_Date, GETDATE()) BETWEEN 1 AND 3 THEN 'Mid-Term (1-3 Years)'
        WHEN DATEDIFF(year, Contract_Start_Date, GETDATE()) BETWEEN 4 AND 7 THEN 'Established (4-7 Years)'
        WHEN DATEDIFF(year, Contract_Start_Date, GETDATE()) > 7 THEN 'Long-Term (Over 7 Years)'
        ELSE 'Unknown'
    END AS Contract_Duration_Category
FROM
    dbo.Almarai_Suppliers
WHERE
    Is_Active = 1 AND Contract_Start_Date IS NOT NULL;
GO

-- Query 3: Suppliers with Higher Than Average Rating within Their Country
-- This view identifies suppliers whose individual rating is above the average rating
-- for all suppliers in their respective country.
CREATE VIEW dbo.vw_HighPerformingSuppliersByCountry AS
WITH CountryAverageRatings AS (
    SELECT
        Country,
        AVG(Rating) AS AvgRatingPerCountry
    FROM
        dbo.Almarai_Suppliers
    WHERE
        Rating IS NOT NULL AND Is_Active = 1
    GROUP BY
        Country
)
SELECT
    s.Supplier_ID,
    s.Supplier_Name,
    s.Country,
    s.Rating,
    car.AvgRatingPerCountry
FROM
    dbo.Almarai_Suppliers AS s
JOIN
    CountryAverageRatings AS car
ON
    s.Country = car.Country
WHERE
    s.Rating > car.AvgRatingPerCountry
    AND s.Is_Active = 1;
GO



