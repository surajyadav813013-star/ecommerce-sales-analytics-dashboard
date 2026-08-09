/* ============================================================
   File: 03_customer_analysis.sql
   Purpose: Customer-side metrics for the dashboard — repeat
   rate, top customers, new-vs-returning trend. (Kept this
   lighter than my other SQL project's full RFM segmentation,
   since that's already covered there — this one focuses on
   sales/ops metrics.)
   ============================================================ */

/* -----------------------------------------------------------
   1. REPEAT PURCHASE RATE
      % of customers with more than 1 delivered order
   ----------------------------------------------------------- */
WITH order_counts AS (
    SELECT customer_id, COUNT(*) AS orders_made
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    COUNT(*)                                                          AS total_buying_customers,
    SUM(CASE WHEN orders_made > 1 THEN 1 ELSE 0 END)                  AS repeat_customers,
    ROUND(SUM(CASE WHEN orders_made > 1 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                                                AS repeat_purchase_rate_pct
FROM order_counts;


/* -----------------------------------------------------------
   2. TOP 15 CUSTOMERS BY LIFETIME REVENUE
   ----------------------------------------------------------- */
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(o.order_id)              AS total_orders,
    ROUND(SUM(o.order_value), 2)   AS lifetime_revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id
ORDER BY lifetime_revenue DESC
LIMIT 15;


/* -----------------------------------------------------------
   3. NEW VS RETURNING CUSTOMERS PER MONTH
      A customer's first-ever delivered order = "new" that
      month, everything after = "returning".
   ----------------------------------------------------------- */
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
tagged AS (
    SELECT
        o.order_id,
        o.customer_id,
        strftime('%Y-%m', o.order_date) AS order_month,
        CASE WHEN o.order_date = f.first_order_date THEN 'New' ELSE 'Returning' END AS customer_type
    FROM orders o
    JOIN first_orders f ON f.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
)
SELECT
    order_month,
    customer_type,
    COUNT(DISTINCT customer_id) AS customers
FROM tagged
GROUP BY order_month, customer_type
ORDER BY order_month, customer_type;


/* -----------------------------------------------------------
   4. AVERAGE ORDER VALUE (AOV) BY CUSTOMER CITY TIER
   ----------------------------------------------------------- */
SELECT
    c.city_tier,
    COUNT(o.order_id)            AS total_orders,
    ROUND(AVG(o.order_value), 2) AS aov
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city_tier
ORDER BY aov DESC;
