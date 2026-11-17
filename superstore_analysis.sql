-- Superstore Sales Analysis (2015-2018)
-- Database: PostgreSQL | Table: superstore (cleaned, dates as DATE)
-- Author: Ayushi Dubey

-- ============================================================
-- Section 2: Overview - how big is the business?
-- ============================================================

-- Q1. What are the total sales?
-- Idea: SUM(sales)
SELECT ROUND(SUM(sales), 2) AS total_sales
FROM superstore;

-- Q2. How many orders were placed?
-- Idea: COUNT(DISTINCT order_id). One order has many rows, so count each order ID once.
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM superstore;

-- Q3. How many unique customers do we have?
-- Idea: COUNT(DISTINCT customer_id). Use the ID, because two customers can share a name.
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM superstore;

-- Q4. What is the average order value?
-- Idea: SUM(sales) / COUNT(DISTINCT order_id). Do not use AVG(sales): that gives the average product line, not the average order.
SELECT ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM superstore;

-- Q5. What period does the data cover?
-- Idea: MIN(order_date) and MAX(order_date)
SELECT MIN(order_date) AS start_date,
       MAX(order_date) AS end_date
FROM superstore;

-- Q6. How many products and cities are there?
-- Idea: COUNT(DISTINCT product_id) and COUNT(DISTINCT city) in one SELECT.
SELECT COUNT(DISTINCT product_id) AS total_products,
       COUNT(DISTINCT city)       AS total_cities
FROM superstore;

-- ============================================================
-- Section 3: Time - which year, which month, when did sales happen?
-- ============================================================

-- Q1. How much did we sell in each year?
-- Idea: EXTRACT(YEAR FROM order_date) and GROUP BY year.
SELECT EXTRACT(YEAR FROM order_date) AS year,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;

-- Q2. What is the year-over-year growth %?
-- Idea: LAG(total_sales) OVER (ORDER BY year) brings the previous year's sales onto the same row.
WITH yearly AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year,
           SUM(sales) AS total_sales
    FROM superstore
    GROUP BY EXTRACT(YEAR FROM order_date)
),
compare AS (
    SELECT year, total_sales,
           LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales
    FROM yearly
)
SELECT year,
       ROUND(total_sales, 2) AS total_sales,
       ROUND(prev_year_sales, 2) AS prev_year_sales,
       ROUND((total_sales - prev_year_sales) * 100.0 / prev_year_sales, 2) AS growth_pct
FROM compare
ORDER BY year;

-- Q3. What are the sales for each month?
-- Idea: DATE_TRUNC('month', order_date) turns every date into the first day of its month.
SELECT DATE_TRUNC('month', order_date)::date AS month,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- Q4. Which month is the best and which is the worst?
-- Idea: GROUP BY month number (1 to 12) across all years, then ORDER BY sales DESC.
SELECT EXTRACT(MONTH FROM order_date) AS month_number,
       TO_CHAR(order_date, 'FMMonth') AS month_name,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'FMMonth')
ORDER BY total_sales DESC;

-- Q5. Is there a seasonal pattern (for example, Q4 peak)?
-- Idea: EXTRACT(QUARTER FROM order_date). Q1 = Jan-Mar, Q2 = Apr-Jun, Q3 = Jul-Sep, Q4 = Oct-Dec.
SELECT EXTRACT(QUARTER FROM order_date) AS quarter,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (), 2) AS pct_of_total
FROM superstore
GROUP BY EXTRACT(QUARTER FROM order_date)
ORDER BY quarter;

-- Q6. Which day of the week has the most orders?
-- Idea: TO_CHAR(order_date, 'FMDay') gives the day name. Count orders with COUNT(DISTINCT order_id).
SELECT TO_CHAR(order_date, 'FMDay') AS day_of_week,
       COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY TO_CHAR(order_date, 'FMDay')
ORDER BY total_orders DESC;

-- ============================================================
-- Section 4: Geography - where do we sell?
-- ============================================================

-- Q1. Which region sells the most and which the least?
-- Idea: GROUP BY region ORDER BY SUM(sales) DESC
SELECT region,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;

-- Q2. What are the top 10 states by sales?
-- Idea: GROUP BY state, ORDER BY sales DESC, then LIMIT 10.
SELECT state,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY state
ORDER BY total_sales DESC
LIMIT 10;

-- Q3. What are the top 10 cities?
-- Idea: Same as the states question, with city.
SELECT city, state,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY city, state
ORDER BY total_sales DESC
LIMIT 10;

-- Q4. How has each region grown over the years?
-- Idea: GROUP BY region and year. LAG with PARTITION BY region gives each region's previous year.
WITH region_year AS (
    SELECT region,
           EXTRACT(YEAR FROM order_date) AS year,
           SUM(sales) AS total_sales
    FROM superstore
    GROUP BY region, EXTRACT(YEAR FROM order_date)
),
compare AS (
    SELECT region, year, total_sales,
           LAG(total_sales) OVER (PARTITION BY region ORDER BY year) AS prev_sales
    FROM region_year
)
SELECT region, year,
       ROUND(total_sales, 2) AS total_sales,
       ROUND((total_sales - prev_sales) * 100.0 / prev_sales, 2) AS growth_pct
FROM compare
ORDER BY region, year;

-- Q5. What % of total sales does each region contribute?
-- Idea: SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (). The empty OVER () gives the grand total on every row.
SELECT region,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (), 2) AS pct_of_total
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;

-- ============================================================
-- Section 5: Products - what do we sell?
-- ============================================================

-- Q1. Which category sells the most?
-- Idea: GROUP BY category
SELECT category,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (), 2) AS pct_of_total
FROM superstore
GROUP BY category
ORDER BY total_sales DESC;

-- Q2. Which sub-categories are the top and bottom?
-- Idea: GROUP BY category and sub_category. The first rows are the top, the last rows are the bottom.
SELECT category, sub_category,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY category, sub_category
ORDER BY total_sales DESC;

-- Q3. What are the top 10 products by sales?
-- Idea: GROUP BY product_name, ORDER BY sales DESC, LIMIT 10.
SELECT product_name,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

-- Q4. What are the bottom 10 products?
-- Idea: ORDER BY SUM(sales) ASC LIMIT 10 (lowest first).
SELECT product_name,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY product_name
ORDER BY total_sales ASC, product_name
LIMIT 10;

-- Q5. How does each category perform year by year?
-- Idea: GROUP BY category and year.
SELECT category,
       EXTRACT(YEAR FROM order_date) AS year,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY category, EXTRACT(YEAR FROM order_date)
ORDER BY category, year;

-- ============================================================
-- Section 6: Customers - who buys from us?
-- ============================================================

-- Q1. Who are the top 10 customers?
-- Idea: GROUP BY customer_name, ORDER BY sales DESC, LIMIT 10.
SELECT customer_name,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY total_sales DESC
LIMIT 10;

-- Q2. Which segment (Consumer, Corporate, Home Office) sells the most?
-- Idea: GROUP BY segment
SELECT segment,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (), 2) AS pct_of_total
FROM superstore
GROUP BY segment
ORDER BY total_sales DESC;

-- Q3. How many customers ordered more than once (repeat customers)?
-- Idea: HAVING COUNT(DISTINCT order_id) > 1, inside a subquery, then count the customers.
SELECT COUNT(*) AS repeat_customers,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM superstore), 2) AS pct_of_all_customers
FROM (
    SELECT customer_id
    FROM superstore
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
) t;

-- Q4. How many new customers did we get each year?
-- Idea: MIN(order_date) per customer gives the first order. Then count customers by the year of that first order.
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM superstore
    GROUP BY customer_id
)
SELECT EXTRACT(YEAR FROM first_date) AS year,
       COUNT(*) AS new_customers
FROM first_order
GROUP BY EXTRACT(YEAR FROM first_date)
ORDER BY year;

-- Q5. What is the average sales per customer?
-- Idea: SUM(sales) / COUNT(DISTINCT customer_id)
SELECT ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS avg_sales_per_customer
FROM superstore;

-- ============================================================
-- Section 7: Shipping
-- ============================================================

-- Q1. Which ship mode is used the most?
-- Idea: GROUP BY ship_mode. Count orders, not rows.
SELECT ship_mode,
       COUNT(DISTINCT order_id) AS total_orders,
       ROUND(COUNT(DISTINCT order_id) * 100.0 / SUM(COUNT(DISTINCT order_id)) OVER (), 2) AS pct_of_orders
FROM superstore
GROUP BY ship_mode
ORDER BY total_orders DESC;

-- Q2. What is the average delivery time in days?
-- Idea: AVG(ship_date - order_date). Subtracting two dates gives the number of days.
SELECT ROUND(AVG(ship_date - order_date), 2) AS avg_delivery_days
FROM superstore;

-- Q3. Does delivery time differ by region or ship mode?
-- Idea: AVG(ship_date - order_date) with GROUP BY region, ship_mode.
SELECT ship_mode, region,
       ROUND(AVG(ship_date - order_date), 2) AS avg_delivery_days
FROM superstore
GROUP BY ship_mode, region
ORDER BY ship_mode, region;

-- ============================================================
-- Section 8: Advanced questions (these impress in interviews)
-- ============================================================

-- Q1. Rank products inside each category.
-- Idea: RANK() OVER (PARTITION BY category ORDER BY sales DESC). Here only the top 3 of each category are shown.
WITH product_sales AS (
    SELECT category, product_name,
           SUM(sales) AS total_sales
    FROM superstore
    GROUP BY category, product_name
),
ranked AS (
    SELECT category, product_name,
           ROUND(total_sales, 2) AS total_sales,
           RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS rnk
    FROM product_sales
)
SELECT category, rnk, product_name, total_sales
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q2. Show cumulative (running) sales by month.
-- Idea: SUM(sales) OVER (ORDER BY month) adds each month to the total so far.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(sales) AS total_sales
    FROM superstore
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month,
       ROUND(total_sales, 2) AS total_sales,
       ROUND(SUM(total_sales) OVER (ORDER BY month), 2) AS running_total
FROM monthly
ORDER BY month;

-- Q3. Which customers give 80% of our sales?
-- Idea: Cumulative % of sales with window functions. Sort customers by sales, add them up, and stop when the running share reaches 80%.
WITH cust AS (
    SELECT customer_id, customer_name, SUM(sales) AS total_sales
    FROM superstore
    GROUP BY customer_id, customer_name
),
cum AS (
    SELECT customer_name, total_sales,
           SUM(total_sales) OVER (ORDER BY total_sales DESC, customer_id) AS running_sales,
           SUM(total_sales) OVER () AS grand_total
    FROM cust
)
SELECT COUNT(*) AS customers_for_80_pct,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cust), 2) AS pct_of_all_customers
FROM cum
WHERE running_sales - total_sales < 0.8 * grand_total;

-- Q4. What is the month-over-month change?
-- Idea: LAG() with month totals. Percentage change = (this month - last month) * 100 / last month.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(sales) AS total_sales
    FROM superstore
    GROUP BY DATE_TRUNC('month', order_date)
),
compare AS (
    SELECT month, total_sales,
           LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales
    FROM monthly
)
SELECT month,
       ROUND(total_sales, 2) AS total_sales,
       ROUND(prev_month_sales, 2) AS prev_month_sales,
       ROUND((total_sales - prev_month_sales) * 100.0 / prev_month_sales, 2) AS mom_change_pct
FROM compare
ORDER BY month;
