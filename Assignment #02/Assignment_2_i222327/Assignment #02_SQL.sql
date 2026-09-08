CREATE DATABASE ECOMMERCE -- Create a new database named ECOMMERCE

--Each set of statements is sent to the server as an individual batch.
--The client tool (like SSMS) sends all the statements before  to the SQL Server as one batch for execution.
GO

USE ECOMMERCE -- Switch to the newly created database

--Each set of statements is sent to the server as an individual batch.
--The client tool (like SSMS) sends all the statements before  to the SQL Server as one batch for execution.
GO

--Each set of statements is sent to the server as an individual batch.
 --The client tool (like SSMS) sends all the statements before  to the SQL Server as one batch for execution.
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


							--Task # 1 Data Uploading and Cleaning 


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
CREATE TABLE Customers 
(
    customer_id VARCHAR(50) CHECK (customer_id <> '') PRIMARY KEY,  -- Define a unique customer ID as the primary key with a constraint to prevent empty values
    customer_unique_id VARCHAR(50) NOT NULL CHECK (customer_unique_id <> ''),  -- Define a unique identifier for customers, ensuring it is not empty
    customer_zip_code_prefix INT NOT NULL CHECK (customer_zip_code_prefix>0),  -- Store the customer's zip code prefix, ensuring it is a positive integer
    customer_city VARCHAR(255) NOT NULL, -- Store the city of the customer, ensuring it is not empty
    customer_state VARCHAR(50) NOT NULL, -- Store the state of the customer, ensuring it is not empty
	FOREIGN KEY (customer_zip_code_prefix, customer_city, customer_state) REFERENCES Geolocation(geolocation_zip_code_prefix, geolocation_city, geolocation_state) ON DELETE CASCADE
    -- Establish a foreign key relationship with the Geolocation table. The foreign key ensures
	-- data consistency by referencing the geolocation table If a referenced geolocation entry
	-- is deleted, all associated customers are also deleted (CASCADE)
);



-- Import data from a CSV file into the Customers table using bulk insert
BULK INSERT Customers
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_customers_dataset.csv'
WITH 
(
    FORMAT = 'CSV',         -- Specify that the file format is CSV
    FIRSTROW = 2,           -- Skip the first row (header row) while importing data  
    FIELDTERMINATOR = ',',  -- Use a comma as the field separator
    ROWTERMINATOR = '\n',   -- Use a newline character as the row terminator
    TABLOCK 				-- Use table-level locking to improve performance during bulk insertion
);



-- Retrieve and display all records from the Customers table
SELECT *
FROM Customers




-- Create a table named Orders to store order-related details
-- Create the Orders table to store order-related details
CREATE TABLE Orders 
(
    -- Order ID: Unique identifier for each order (Primary Key)
    order_id VARCHAR(50) PRIMARY KEY CHECK (order_id <> ''),  
    -- Customer ID: References the Customers table (ensures each order is linked to a customer)
    customer_id VARCHAR(50) NOT NULL,      
    -- Order status: Must be one of the predefined valid statuses
    order_status VARCHAR(50) NOT NULL CHECK (order_status IN ('delivered', 'shipped', 'processing', 'canceled', 'unavailable', 'invoiced', 'created', 'approved')),  
    -- Order timestamps (nullable to handle missing data during insertion)
    order_purchase_timestamp DATETIME NULL,   -- When the order was placed
    order_approved_at DATETIME NULL,          -- When the order was approved
    order_delivered_carrier_date DATETIME NULL, -- When the carrier received the package
    order_delivered_customer_date DATETIME NULL, -- When the customer received the package
    order_estimated_delivery_date DATETIME NULL, -- Estimated delivery date provided to the customer
    -- Foreign Key Constraint: If a customer is deleted, all their orders are also deleted
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE,
    -- Table-Level CHECK Constraints to enforce valid date sequences
    -- Ensure the order approval date is after or equal to the order purchase date
    CONSTRAINT chk_order_approved CHECK (order_approved_at IS NULL OR order_approved_at >= order_purchase_timestamp),
    -- Ensure the carrier received the package after the order was approved
    CONSTRAINT chk_order_carrier_date CHECK (order_delivered_carrier_date IS NULL OR order_delivered_carrier_date >= order_approved_at),
    -- Ensure the customer received the package after the carrier received it and after the purchase date
    CONSTRAINT chk_order_customer_date CHECK (order_delivered_customer_date IS NULL OR (order_delivered_customer_date >= order_delivered_carrier_date AND order_delivered_customer_date >= order_purchase_timestamp)),
    -- Ensure the estimated delivery date is at least on or after the purchase date
    CONSTRAINT chk_order_estimated_date CHECK (order_estimated_delivery_date IS NULL OR order_estimated_delivery_date >= order_purchase_timestamp)
);




-- Bulk insert data from a CSV file into the Orders table
BULK INSERT Orders
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_orders_dataset.csv'
WITH 
(
    FORMAT = 'CSV',			-- Specify CSV file format
    FIELDTERMINATOR = ',',	-- Define comma as the column separator
    ROWTERMINATOR = '\n',	-- Define newline as the row separator
    FIRSTROW = 2,			-- Skip the header row
    CODEPAGE = '65001',	    -- Use UTF-8 encoding for character compatibility
	KEEPNULLS,			    -- Preserve NULL values from the source data
	TABLOCK					-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);



-- Retrieve all records from the Orders table
SELECT *
FROM Orders





-- Create a table to store payment details for orders
CREATE TABLE Order_Payments
(
    order_id VARCHAR(50),-- Store the ID of the associated order
    payment_sequential INT CHECK (payment_sequential >= 1) NOT NULL DEFAULT 1,  -- Sequential payment number for an order (ensures multiple payments for one order are tracked)
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card','not_defined')) DEFAULT 'not_defined',     -- Type of payment method used
    payment_installments INT NOT NULL CHECK (payment_installments>0) DEFAULT 1,-- Number of installments chosen for payment
    payment_value FLOAT NOT NULL CHECK (payment_value >= 0) DEFAULT 0,-- Value of the payment transaction
	PRIMARY KEY (order_id, payment_sequential),  -- Define the primary key as a combination of order_id and payment_sequential
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE     -- Establish foreign key relationship with Orders table; if an order is deleted, its payments are also deleted
);



-- Bulk insert data from CSV file into the Order_Payments table
BULK INSERT Order_Payments
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_order_payments_dataset.csv'
WITH 
(
    FORMAT = 'CSV',         -- Specify the format as CSV
    FIELDTERMINATOR = ',',  -- Use comma as the field separator
    ROWTERMINATOR = '\n',   -- Use newline as the row separator
    FIRSTROW = 2,			-- Skip the header row
    CODEPAGE = '65001',     -- Use UTF-8 encoding for character compatibility
	TABLOCK					-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);



-- Retrieve all records from Order_Payments table for verification
SELECT *
FROM Order_Payments






-- Create a table to store product details
CREATE TABLE Products
(
    product_id VARCHAR(50) PRIMARY KEY CHECK (product_id <> ''),-- Unique identifier for each product
    product_catery_name VARCHAR(255) NOT NULL, -- Name of the product catery (linked to another table)
    product_name_length INT CHECK (product_name_length >= 1) DEFAULT 1,-- Length of the product name
    product_description_length INT CHECK (product_description_length >= 0)  DEFAULT 0,-- Length of the product description
    product_photos_qty INT CHECK (product_photos_qty BETWEEN 0 AND 50)  DEFAULT 0, -- Number of photos available for the product
    product_weight_g INT CHECK (product_weight_g > 0) DEFAULT NULL,-- Weight of the product in grams
    product_length_cm INT CHECK (product_length_cm > 0) DEFAULT NULL,-- Length of the product in centimeters
    product_height_cm INT CHECK (product_height_cm > 0) DEFAULT NULL,-- Height of the product in centimeters
    product_width_cm INT CHECK (product_width_cm > 0) DEFAULT NULL,-- Width of the product in centimeters
	FOREIGN KEY (product_catery_name) REFERENCES Product_Catery_Name_Translation(product_catery_name) ON DELETE CASCADE
	-- Establish foreign key relationship with Product_Catery_Name_Translation table
);



-- Bulk insert data from CSV file into the Products table
BULK INSERT Products
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',         -- Specify the format as CSV
    FIELDTERMINATOR = ',',  -- Use comma as the field separator
    ROWTERMINATOR = '\n',   -- Use newline as the row separator
    FIRSTROW = 2,			-- Skip the header row
    CODEPAGE = '65001',     -- Use UTF-8 encoding for character compatibility
    KEEPNULLS,				-- Preserve NULL values in the dataset
	TABLOCK					-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);


-- Retrieve all records from Products table for verification
SELECT *
FROM Products






-- Creating the Sellers table to store seller details
CREATE TABLE Sellers 
(
    seller_id VARCHAR(50) PRIMARY KEY CHECK (seller_id <> ''),-- Unique identifier for each seller, cannot be empty
    seller_zip_code_prefix INT CHECK (seller_zip_code_prefix > 0) NOT NULL,-- Numeric zip code prefix, must be greater than 0
    seller_city VARCHAR(255) NOT NULL,-- Name of the city where the seller is located
    seller_state VARCHAR(50) NOT NULL,-- State of the seller's location
	FOREIGN KEY (seller_zip_code_prefix, seller_city, seller_state) REFERENCES Geolocation(geolocation_zip_code_prefix, geolocation_city, geolocation_state)
    -- Establishing a foreign key relationship with the Geolocation table
);




-- Bulk insert data from CSV file into the Sellers table
BULK INSERT Sellers
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_sellers_dataset.csv'
WITH
(
    FORMAT = 'CSV',         -- Specify the format as CSV
    FIELDTERMINATOR = ',',  -- Use comma as the field separator
    ROWTERMINATOR = '\n',   -- Use newline as the row separator
    FIRSTROW = 2,			-- Skip the header row
    CODEPAGE = '65001',     -- Use UTF-8 encoding for character compatibility
	TABLOCK					-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);




-- Retrieve and display all records from the Sellers table
SELECT *
FROM Sellers





-- Creating the Order_Items table to store individual items in each order
CREATE TABLE Order_Items 
(
    order_id VARCHAR(50),  -- Unique identifier for the order
    order_item_id INT CHECK (order_item_id > 0) ,  -- Order item number (must be greater than 0)
    product_id VARCHAR(50),  -- ID of the product being ordered
    seller_id VARCHAR(50),  -- ID of the seller who sells the product
    shipping_limit_date DATETIME NOT NULL,  -- Deadline for shipping the item
    price DECIMAL(10,2) CHECK (price >= 0) DEFAULT 0 NOT NULL,  -- Price of the product (non-negative)
    freight_value DECIMAL(10,2) CHECK (freight_value >= 0) DEFAULT 0 NOT NULL,  -- Shipping cost (non-negative)
    PRIMARY KEY (order_id, order_item_id),  -- Composite primary key (ensures uniqueness per order)
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,  -- Links to Orders table, deletes associated items if an order is deleted
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE,  -- Links to Products table, deletes items if product is deleted
    FOREIGN KEY (seller_id) REFERENCES Sellers(seller_id) ON DELETE CASCADE  -- Links to Sellers table, deletes items if seller is deleted
);





-- Bulk inserting data into the Order_Items table from a CSV file
BULK INSERT Order_Items
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_order_items_dataset.csv'
WITH (
    DATAFILETYPE = 'char',  -- Specifies that data is stored as characters
    FORMAT = 'CSV',			-- File format is CSV
    FIELDTERMINATOR = ',',  -- Comma is used as a field separator
    ROWTERMINATOR = '0x0A', -- Specifies newline character as row terminator (use '0x0D0A' for Windows if needed)
    FIRSTROW = 2,			-- Skips the first row (header)
    CODEPAGE = '65001',		-- Ensures UTF-8 encoding to handle special characters properly
	TABLOCK					-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);





-- Fetching all data from the Order_Items table for verification
SELECT *
FROM Order_Items;




-- Create the Order_Reviews table to store customer reviews for orders
CREATE TABLE Order_Reviews
(
    review_id VARCHAR(50) CHECK (review_id <> ''), -- Unique identifier for each review, cannot be empty
    order_id VARCHAR(50) NOT NULL, -- Foreign key referencing Orders table, required field
    review_score INT CHECK (review_score BETWEEN 1 AND 5) NOT NULL, -- Review score must be between 1 and 5
    review_comment_title VARCHAR(255) DEFAULT NULL, -- Optional title for the review
    review_comment_message VARCHAR(MAX) DEFAULT NULL, -- Optional detailed review message
    review_creation_date DATETIME NULL, -- Date when the review was created (to be converted later)
    review_answer_timestamp DATETIME NULL, -- Timestamp when the review was answered (to be converted later)
	PRIMARY KEY (review_id, order_id), -- Composite primary key using review_id and order_id
	FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE ,-- Ensures deletion consistency with Orders
	CHECK (review_answer_timestamp IS NULL OR review_creation_date IS NOT NULL), -- Ensure creation date exists if answer exists
    CHECK (review_answer_timestamp IS NULL OR review_answer_timestamp >= review_creation_date) -- Ensure the answer timestamp is after the review creation date
);





-- Bulk insert data from a CSV file into Order_Reviews table
BULK INSERT Order_Reviews
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_order_reviews_dataset.csv'
WITH (
    DATAFILETYPE = 'char',		-- Specifies character-based data file
    FORMAT = 'CSV',				-- Input file is in CSV format
    FIELDTERMINATOR = ',',		-- Fields are separated by commas
    ROWTERMINATOR = '0x0A',		-- Line break for Unix-based systems ('0x0D0A' for Windows)
    FIRSTROW = 2,				-- Skip the header row
    CODEPAGE = '65001',			-- Use UTF-8 encoding to support special characters
	KEEPNULLS,					-- Prevents SQL Server from replacing NULL values with default column values
	TABLOCK						-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);




-- Select all records from Order_Reviews for verification
SELECT *
FROM Order_Reviews;



-- Creating a table to store product catery translations
CREATE TABLE Product_Catery_Name_Translation
(
    product_catery_name VARCHAR(255) PRIMARY KEY,  -- Original catery name (in Portuguese)
    product_catery_name_english VARCHAR(255) NOT NULL  -- English translation of the catery name
);



-- Bulk inserting data into Product_Catery_Name_Translation table from a CSV file
BULK INSERT Product_Catery_Name_Translation
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\product_category_name_translation.csv'
WITH (
    DATAFILETYPE = 'char',		-- Specifies character-based data storage
    FORMAT = 'CSV',				-- File format is CSV
    FIELDTERMINATOR = ',',		-- Comma is used as a field separator
    ROWTERMINATOR = '0x0A',		-- Specifies newline character as row terminator
    FIRSTROW = 2,				-- Skips the first row (header)
    CODEPAGE = '65001',			-- Ensures UTF-8 encoding
	TABLOCK						-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);




-- Fetching all data from the Product_Catery_Name_Translation table for verification
SELECT *
FROM Product_Catery_Name_Translation;



-- Creating the Geolocation table to store validated location data
CREATE TABLE Geolocation
(
    geolocation_zip_code_prefix INT CHECK (geolocation_zip_code_prefix > 0) NOT NULL,  -- ZIP code prefix (must be a positive integer)
    geolocation_lat FLOAT CHECK (geolocation_lat BETWEEN -90 AND 90) NOT NULL,  -- Latitude (must be between -90 and 90)
    geolocation_lng FLOAT CHECK (geolocation_lng BETWEEN -180 AND 180) NOT NULL,  -- Longitude (must be between -180 and 180)
    geolocation_city VARCHAR(255) NOT NULL,  -- City name
    geolocation_state VARCHAR(50) NOT NULL CHECK(LEN(geolocation_state) = 2),  -- State name
    PRIMARY KEY (geolocation_zip_code_prefix, geolocation_city, geolocation_state)  -- Composite primary key (ensures uniqueness per location)
);




-- Creating a staging table to temporarily store raw geolocation data before validation
CREATE TABLE Geolocation_Staging
(
    geolocation_zip_code_prefix INT CHECK (geolocation_zip_code_prefix > 0) NOT NULL,  -- ZIP code prefix (must be a positive integer)
    geolocation_lat FLOAT CHECK (geolocation_lat BETWEEN -90 AND 90) NOT NULL,  -- Latitude (must be between -90 and 90)
    geolocation_lng FLOAT CHECK (geolocation_lng BETWEEN -180 AND 180) NOT NULL,  -- Longitude (must be between -180 and 180)
    geolocation_city VARCHAR(255) NOT NULL,  -- City name
    geolocation_state VARCHAR(50) NOT NULL,  -- State name
);



-- Bulk inserting raw data into the staging table from a CSV file
BULK INSERT Geolocation_Staging
FROM 'C:\Users\ALLEN PROGRAMMER\Downloads\olist_geolocation_dataset.csv'
WITH 
(
    DATAFILETYPE = 'char',  -- Specifies character-based data storage
    FORMAT = 'CSV',			-- File format is CSV
    FIELDTERMINATOR = ',',  -- Comma is used as a field separator
    ROWTERMINATOR = '0x0A', -- Specifies newline character as row terminator (use '0x0D0A' for Windows if needed)
    FIRSTROW = 2,			-- Skips the first row (header)
    CODEPAGE = '65001',		-- Ensures UTF-8 encoding
	TABLOCK					-- Applies a table-level lock during the bulk insert operation to improve performance by reducing logging and concurrency issues
);



--INSERT INTO Geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
--SELECT geolocation_zip_code_prefix, 
--       MIN(geolocation_lat) AS geolocation_lat, 
--       MIN(geolocation_lng) AS geolocation_lng, 
--       geolocation_city, 
--       geolocation_state
--FROM Geolocation_Staging
--GROUP BY geolocation_zip_code_prefix, geolocation_city, geolocation_state;



-- Using a Common Table Expression (CTE) to clean and filter the data before inserting into the main Geolocation table
-- Creating a Common Table Expression (CTE) named UniqueGeo
WITH UniqueGeo AS (
    SELECT *,
           -- Assigning a row number to each row within the same (zip_code, city, state) combination
           -- The ORDER BY clause determines which row is ranked first
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix, geolocation_city, geolocation_state  -- Groups by composite primary key
               ORDER BY geolocation_lat, geolocation_lng  -- Orders within each group, keeping the smallest lat/lng
           ) AS rn
    FROM Geolocation_Staging  -- Selecting data from the staging table
)

-- Inserting unique records into the final Geolocation table
INSERT INTO Geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
SELECT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
FROM UniqueGeo 
WHERE rn = 1;  -- Keeping only the first (ranked) row from each duplicate group




-- Fetching all data from the Geolocation table to verify inserted records
SELECT *
FROM Geolocation;



-- Dropping the temporary staging table as it's no longer needed
DROP TABLE Geolocation_Staging;



-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


								--Task # 2 Data Retrieval 


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


									-- RUN QUERIES 


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

				
									-- ORDER ANALYSIS

					
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

--a.	Percentage of orders that t delayed beyond the estimated date

SELECT 
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Orders)), 2) AS delayed_order_percentage
FROM Orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;


--b.	What are the peak months of order delays?(RETURN MORE THAN 10)

SELECT 
    MONTH(order_delivered_customer_date) AS MonthNo, 
    COUNT(*) AS NoOfDelays
FROM Orders
WHERE order_delivered_customer_date > order_estimated_delivery_date
GROUP BY MONTH(order_delivered_customer_date)
ORDER BY NoOfDelays DESC;


--c.	Which state experiences the highest order delays?(RETURN MORE THAN 10)
SELECT c.customer_state AS State, COUNT(*) AS TotalDelays
FROM Orders o
JOIN Customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY c.customer_state
ORDER BY TotalDelays DESC


--d.	See how many orders are still in “pending” status for each year
SELECT YEAR(order_purchase_timestamp) AS order_year, COUNT(*) AS pending_orders
FROM Orders
WHERE order_status = 'processing'
AND order_purchase_timestamp IS NOT NULL  
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;


--e.	What is the average delay duration per seller?(RETURN MORE THAN 10)

SELECT OT.seller_id AS SellerID,
    AVG(DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS AVG_DELAY_IN_DAYS
FROM Orders o
JOIN Order_Items OT ON o.order_id = OT.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY OT.seller_id
ORDER BY AVG_DELAY_IN_DAYS DESC;


--f.	How do shipping costs impact order delays? Find the average shipping cost for delayed and on-time orders. 

SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 'Delayed'
        ELSE 'On-Time'
    END AS Delivery_status,
    ROUND(AVG(oi.freight_value), 2) AS AVG_SHIPPING_COST
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 'Delayed'
        ELSE 'On-Time'
    END;


--g.	Which product catery experience the most order delays. (RETURN MORE THAN 10)


SELECT p.product_catery_name AS CateryName, COUNT(o.order_id) AS Delayed_Orders
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY p.product_catery_name
ORDER BY Delayed_Orders DESC;


--h.	How do number of items per order affect the delays? Find the average number of items for delayed and on time orders.

SELECT delivery_status, ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM (
    SELECT
        o.order_id,
        SUM(oi.order_item_id) AS item_count,  
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Delayed'
            ELSE 'On-Time'
        END AS delivery_status
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY o.order_id, o.order_delivered_customer_date, o.order_estimated_delivery_date
) item_counts
GROUP BY delivery_status;


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

				
									-- CUSTOMER ANALYSIS

					
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

--a.	 What percentage of customers have made only one order?


SELECT ROUND((SELECT COUNT(*)
             FROM (
             SELECT c.customer_unique_id            --numerator has customers that have placed one order
             FROM Customers c
             INNER JOIN Orders o ON c.customer_id = o.customer_id
             GROUP BY c.customer_unique_id
             HAVING COUNT(o.order_id) = 1
         ) AS single_order_customers) * 100.0 /
          (SELECT COUNT(DISTINCT customer_unique_id) --denominator has the total number of customers
           FROM Customers), 2) AS PercentageOfCustomersWithSingleorder;


--b.	Find the top five cities with the most repeat customers (customers who have placed orders more than once)


SELECT TOP 5 customer_city, COUNT(customer_unique_id) AS RepeatedCustomers
FROM (
    SELECT c.customer_city, c.customer_unique_id, COUNT(o.order_id) AS order_count
    FROM Customers c
    INNER JOIN Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_city, c.customer_unique_id
    HAVING COUNT(o.order_id) > 1 --fidning unique customers that have placed more than 1 order
) AS repeat_customers
GROUP BY
    customer_city
ORDER BY
    RepeatedCustomers DESC;


--c.	Calculate the average order price of customers for each state (RETURN MORE THAN 10)


SELECT 
    c.customer_state, 
    ROUND(AVG(op.payment_value), 2) AS Avg_OrderPrice
FROM Customers AS c
INNER JOIN Orders o ON c.customer_id = o.customer_id
INNER JOIN Order_Payments op ON o.order_id = op.order_id
GROUP BY c.customer_state
ORDER BY Avg_OrderPrice DESC;



--d.	Find the top ten customers with the highest number of orders placed.


SELECT TOP 10 c.customer_unique_id AS CustomerID, COUNT(o.order_id) AS TotalOrders
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY TotalOrders DESC;



--e.	Which customers have the longest average delivery time (RETURN MORE THAN 10)


SELECT c.customer_unique_id AS CustomerID,
    AVG(DATEDIFF(DAY, o.order_approved_at, o.order_delivered_customer_date)) AS Avg_DeliveryDays
FROM Customers AS c
INNER JOIN Orders o ON c.customer_id = o.customer_id
WHERE
    o.order_status = 'delivered'
    AND o.order_approved_at IS NOT NULL
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_unique_id
ORDER BY Avg_DeliveryDays DESC;


--f.	How does customer order frequency change over time? Find the average number of orders placed per customer per year.


SELECT YEAR(o.order_purchase_timestamp) AS OrderYear,
    COUNT(o.order_id) * 1.0 / COUNT(DISTINCT c.customer_unique_id) AS Avrders_PerCustomer
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY YEAR(o.order_purchase_timestamp)
ORDER BY OrderYear;


--g.	Which top 5 customers have spent the most money in year 2017


SELECT TOP 5
    c.customer_unique_id AS Customer,
    ROUND(SUM(op.payment_value), 2) AS TotalSpent_In_2017
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id
INNER JOIN Order_Payments op ON o.order_id = op.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY c.customer_unique_id
ORDER BY TotalSpent_In_2017 DESC;



--h.	Which customers have the highest order cancellations (RETURN MORE THAN 10)


SELECT c.customer_unique_id AS Customers, COUNT(o.order_id) AS Cancelled_orders_count
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'canceled'
GROUP BY c.customer_unique_id
ORDER BY cancelled_orders_count DESC


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

				
									-- PRODUCT ANALYSIS

					
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


--a.	What is the most profitable product catery per state? Find the most profitable product catery in each state based on total sales. (RETURN MORE THAN 10)


SELECT s.customer_state AS State, s.product_catery_name AS Top_catery, s.total_sales AS TotalSales
FROM (
    SELECT c.customer_state, p.product_catery_name, SUM(oi.price) AS total_sales
    FROM Orders o
    INNER JOIN Customers c ON o.customer_id = c.customer_id
    INNER JOIN Order_Items oi ON o.order_id = oi.order_id
    INNER JOIN Products p ON oi.product_id = p.product_id
    GROUP BY
        c.customer_state, p.product_catery_name
) s
JOIN (
    SELECT customer_state, MAX(total_sales) AS max_sales
    FROM (
        SELECT
            c.customer_state,
            p.product_catery_name,
            SUM(oi.price) AS total_sales
        FROM
            Orders o
        JOIN Customers c ON o.customer_id = c.customer_id
        JOIN Order_Items oi ON o.order_id = oi.order_id
        JOIN Products p ON oi.product_id = p.product_id
        GROUP BY
            c.customer_state, p.product_catery_name
    ) t
    GROUP BY
        customer_state
) m ON s.customer_state = m.customer_state AND s.total_sales = m.max_sales
ORDER BY
    s.total_sales DESC;


--b.	What are the peak hours for order placements per product catery? Find which hours of the day have the highest number of order placements for each product catery. (RETURN MORE THAN 10)

SELECT p.product_catery_name AS ProductCatery,
    DATEPART(HOUR, o.order_purchase_timestamp) AS OrderHour,
    COUNT(*) AS OrderCount
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.product_catery_name,   -- Groups by catery and hour of day when order was placed
    DATEPART(HOUR, o.order_purchase_timestamp)
HAVING COUNT(*) = (
    SELECT MAX(cnt)
    FROM (
        SELECT COUNT(*) AS cnt
        FROM Orders o2                      
        JOIN Order_Items oi2 ON o2.order_id = oi2.order_id
        JOIN Products p2 ON oi2.product_id = p2.product_id
        WHERE p2.product_catery_name = p.product_catery_name   -- Finding max orders per hour from all orders in that hour
        AND o2.order_purchase_timestamp IS NOT NULL
        GROUP BY DATEPART(HOUR, o2.order_purchase_timestamp)
    ) max_counts
)
ORDER BY OrderCount DESC;


--c.	Which product cateries experience the most delays? Find the top 5 product cateries with the highest number of delayed orders. 


SELECT TOP 5 
    t.product_catery_name_english AS ProductCatery,
    COUNT(*) AS NoOfDelayedOrders
FROM Orders o
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
INNER JOIN Products p ON oi.product_id = p.product_id
INNER JOIN Product_Catery_Name_Translation t ON p.product_catery_name = t.product_catery_name
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY t.product_catery_name_english
ORDER BY NoOfDelayedOrders DESC;


--d.	What is the impact of product price on sales volume? Find whether higher-priced products sell less by comparing average price vs. total sales. (RETURN MORE THAN 10)


SELECT  p.product_id AS ProductID,
    ROUND(AVG(oi.price), 2) AS AveragePrice,
    COUNT(o.order_id) AS TotalSales
FROM Products p
INNER JOIN Order_Items oi ON p.product_id = oi.product_id
INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id
ORDER BY AveragePrice ASC, TotalSales --organising data from min avg price to max price


--e.	Which products are most frequently bought together? Find the most frequently purchased product pairs. (RETURN MORE THAN 10)


SELECT
    o1.product_id AS Product1,
    o2.product_id AS Product2,
    COUNT(DISTINCT o1.order_id) AS purchase_count
FROM Order_Items o1
INNER JOIN Order_Items o2
ON o1.order_id = o2.order_id
AND o1.product_id < o2.product_id  -- Ensure unique pairs
INNER JOIN
    Products p1 ON o1.product_id = p1.product_id
INNER JOIN
    Products p2 ON o2.product_id = p2.product_id
GROUP BY o1.product_id, o2.product_id
ORDER BY COUNT(DISTINCT o1.order_id) DESC;


--f.	Calculate the total revenue per product catery by summing order item prices. (RETURN MORE THAN 10)


SELECT t.product_catery_name_english AS Catery,
    ROUND(SUM(oi.price), 2) AS TotalRevenue
FROM Order_Items oi
INNER JOIN Products p ON oi.product_id = p.product_id
INNER JOIN Product_Catery_Name_Translation t ON p.product_catery_name = t.product_catery_name
INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY t.product_catery_name_english
ORDER BY TotalRevenue DESC;


--g.	Compute the average review score for each product catery. (RETURN MORE THAN 10)


SELECT t.product_catery_name_english AS Catery,
    ROUND(AVG(r.review_score), 2) AS Avg_Review_Score,
    COUNT(r.review_id) AS review_count
FROM Order_Reviews r
INNER JOIN Orders o ON r.order_id = o.order_id
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
INNER JOIN Products p ON oi.product_id = p.product_id
INNER JOIN Product_Catery_Name_Translation t ON p.product_catery_name = t.product_catery_name
WHERE o.order_status = 'delivered'
GROUP BY t.product_catery_name_english
ORDER BY Avg_Review_Score DESC;


--h.	Retrieve the top 5 products based on total sales revenue.


SELECT TOP 5
    p.product_id AS ProductID, t.product_catery_name_english AS Catery,
    ROUND(SUM(oi.price), 2) AS TotalRevenue
FROM Order_Items oi
INNER JOIN Products p ON oi.product_id = p.product_id
INNER JOIN Product_Catery_Name_Translation t ON p.product_catery_name = t.product_catery_name
INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, t.product_catery_name_english
ORDER BY TotalRevenue DESC;




-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

				
						     -- SELLER AND SHIPMENT ANALYSIS

					
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


--a.	What is the return rate per seller? (RETURN MORE THAN 10)


SELECT 
    s.seller_id, 
    _total.total_count AS TotalOrders, 
    _canceled.canceled_count AS CanceledOrders,
    ROUND(
        (_canceled.canceled_count * 100.0) / 
        NULLIF(_total.total_count, 0),
        2
    ) AS ReturnRate_Percentage
FROM Sellers s
LEFT JOIN (
    SELECT
        oi.seller_id,
        COUNT(*) AS canceled_count
    FROM Orders o
    INNER JOIN Order_Items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'canceled'
    GROUP BY oi.seller_id
) _canceled ON s.seller_id = _canceled.seller_id
LEFT JOIN (
    SELECT
        oi.seller_id,
        COUNT(*) AS total_count
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY oi.seller_id
) _total ON s.seller_id = _total.seller_id
WHERE _total.total_count > 0  
ORDER BY ReturnRate_Percentage DESC;


--b.	Which sellers sell the most expensive products on average? Find sellers whose products have the highest average price. (RETURN MORE THAN 10)


SELECT s.seller_id,
    ROUND(AVG(oi.price), 2) AS AverageProductPrice
FROM Sellers s
INNER JOIN Order_Items oi ON s.seller_id = oi.seller_id
INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
ORDER BY AverageProductPrice DESC;


--c.	What is the profit margin per seller? Find the profit margin per seller, assuming: (RETURN MORE THAN 10)


SELECT
    s.seller_id,
    ROUND(SUM(oi.price - oi.freight_value), 2) AS Profit_Margin,
    ROUND(SUM(oi.price), 2) AS SellingPrice,
    ROUND(SUM(oi.freight_value), 2) AS FreightValue,
COUNT(DISTINCT oi.order_id) AS order_count,
    ROUND((SUM(oi.price - oi.freight_value) * 100.0 / SUM(oi.price)), 2) AS Profit_Margin_Percentage
   
FROM Order_Items oi
INNER JOIN Sellers s ON oi.seller_id = s.seller_id
INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
ORDER BY Profit_Margin_Percentage DESC;


--d.	How do shipping costs impact order delays? Find the average shipping cost (freight_value) for delayed vs. non-delayed orders.


SELECT   --For Delayed Order
    'Delayed' AS Delivery_status,
    ROUND(AVG(oi.freight_value), 2) AS AVG_ShippingCost
FROM Orders o
INNER JOIN
    Order_Items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL

UNION ALL
SELECT   --On time Orders
    'On-Time' AS delivery_status,
    ROUND(AVG(oi.freight_value), 2) AS avg_shipping_cost
FROM Orders o
INNER JOIN
    Order_Items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
ORDER BY AVG_ShippingCost DESC;


--e.	What is the number of delayed shipments in 2017


	SELECT COUNT(*) AS DelayedShipmentsIN_2017
FROM Orders o
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
    AND YEAR(o.order_purchase_timestamp) = 2017
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL;


--f.	What is the correlation between shipping cost and delivery speed? Find the average shipping cost (freight_value) for delayed vs. on-time shipments.


SELECT   -- DELAYED SHIPMENT
    'Delayed' AS shipment_status,
    ROUND(AVG(oi.freight_value), 2) AS avg_shipping_cost
FROM Orders o
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
UNION ALL
SELECT  -- ON-TIME SHIPMENT
    'On-Time' AS shipment_status,
    ROUND(AVG(oi.freight_value), 2) AS avg_shipping_cost
FROM Orders o
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date <= o.order_estimated_delivery_date;


--g.	Sum the total freight cost for each seller. (RETURN MORE THAN 10)


SELECT s.seller_id,
    ROUND(SUM(oi.freight_value), 2) AS TotalFreightCost,
    COUNT(oi.order_id) AS TotalShipments
FROM Sellers s
INNER JOIN Order_Items oi ON s.seller_id = oi.seller_id
INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    s.seller_id
ORDER BY
     TotalFreightCost DESC;

					
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


--	 Purpose of TABLOCK in BULK INSERT
--When you use the TABLOCK option in a BULK INSERT statement, you’re applying a table-level lock on the target table for the duration of the insert operation.

--🔒 What does this mean?
--Instead of acquiring row-level or page-level locks (which is the default behavior), SQL Server locks the entire table. This can significantly improve performance when inserting large volumes of data.

--✅ Benefits of Using TABLOCK:
--Performance Boost:

--Bulk inserts are much faster because SQL Server doesn’t have to manage thousands or millions of tiny locks.

--Reduces locking overhead and logging during the operation.

--Minimizes Lock Escalation:

--SQL Server doesn't need to escalate from row-level locks to table-level locks (which can be costly).

--TABLOCK does it upfront, saving the system extra work.

--Enables Minimal Logging (in Simple/Bulk-Logged Recovery Mode):

--If your database is in Simple or Bulk-Logged recovery mode, using TABLOCK with BULK INSERT allows minimal logging, which further boosts performance.

--⚠️ When not to use TABLOCK:
--If other transactions are actively reading from or writing to the table, a table-level lock can block them.

--In high-concurrency environments, this may lead to deadlocks or wait times.
