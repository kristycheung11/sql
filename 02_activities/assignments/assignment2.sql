/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || coalesce(product_size,"")|| ' (' || coalesce(product_qty_type, 'unit') || ')' AS new_product_list
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT DISTINCT 
market_date,
customer_id,
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY market_date) as customer_visits
FROM customer_purchases;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT *

FROM(
SELECT DISTINCT 
market_date,
customer_id,
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY market_date DESC ) as customer_visits
FROM customer_purchases) x

WHERE x.customer_visits = 1;


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT 
customer_id,
product_id,
COUNT(product_id) as number_of_purchases
FROM customer_purchases
GROUP BY customer_id, product_id;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT p.product_name,

TRIM(SUBSTR(p.product_name,p.hypen_position+1,8)) AS description

FROM (

SELECT product_name,
NULLIF(INSTR (product_name, '-'), 0) AS hypen_position
FROM product) p;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

-- Create temp table

DROP TABLE IF EXISTS market_sales;

CREATE TEMP TABLE market_sales AS

SELECT market_date,
SUM (quantity*cost_to_customer_per_qty) as total_sales_values
FROM customer_purchases
GROUP BY market_date;


--UNION

SELECT market_date,
MAX(total_sales_values) AS highest_and_lowest_sales_values
FROM temp.market_sales

UNION

SELECT market_date,
MIN (total_sales_values)
FROM temp.market_sales



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--  TEMP TABLE to get product name and vendor name from separate tables

DROP TABLE IF EXISTS temp.vendor_product_inventory;

CREATE TEMP TABLE IF NOT EXISTS temp.vendor_product_inventory AS

SELECT 
vn.vendor_name,
p.product_name,
vn.original_price,
vn.original_price*5 AS cost_per_five_products

FROM (
SELECT DISTINCT
vi.vendor_id,
v.vendor_name,
vi.product_id,
vi.original_price

FROM vendor_inventory vi
INNER JOIN vendor v
    ON vi.vendor_id =v.vendor_id) vn

INNER JOIN product p
	ON vn.product_id = p.product_id

-- CROSS JOIN
	
SELECT 
vendor_name, 
product_name,
SUM(cost_per_five_products) AS total_sales

FROM (

SELECT  vp.*, c.customer_id
FROM  vendor_product_inventory vp
CROSS JOIN customer c)

GROUP BY vendor_name, product_name



-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;

CREATE TABLE IF NOT EXISTS product_units AS

SELECT*,
CURRENT_TIMESTAMP as snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES(8, 'Apple Pie', '10"', 3, 'unit',CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units 
WHERE product_id= 8 AND product_name='Apple Pie';


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


-- Add new column
ALTER TABLE product_units
ADD current_quantity INT;


-- Create temp table to find lastest quantity per product 

DROP TABLE IF EXISTS temp.new_vendor_inventory;

CREATE TEMP TABLE IF NOT EXISTS temp. new_vendor_inventory AS

SELECT 
market_date,
quantity as latest_quantity,
vendor_id,
product_id

FROM
(SELECT *,
 ROW_NUMBER() OVER (PARTITION BY vendor_id, product_id ORDER BY market_date DESC) AS inventory_count_order
FROM vendor_inventory)

WHERE inventory_count_order = 1;

--Another temp table with JOIN

DROP TABLE IF EXISTS temp.vendor_inventory_product_table;

CREATE TEMP TABLE IF NOT EXISTS temp.vendor_inventory_product_table AS

SELECT p.*,
nv.latest_quantity
FROM product_units p
LEFT JOIN new_vendor_inventory nv
    ON p.product_id =nv.product_id;

--New product_unit table with LEFT JOIN

DROP TABLE IF EXISTS new_product_unit_table;

CREATE TABLE IF NOT EXISTS new_product_unit_table AS

SELECT 
p.product_id,
p.product_name,
p.product_size,
p.product_category_id,
p.product_qty_type,
p.snapshot_timestamp,
nv.latest_quantity as current_quantity
FROM product_units p
LEFT JOIN new_vendor_inventory nv
    ON p.product_id =nv.product_id;
	
	
-- UPDATE

UPDATE new_product_unit_table
SET current_quantity = COALESCE (current_quantity,'0')



