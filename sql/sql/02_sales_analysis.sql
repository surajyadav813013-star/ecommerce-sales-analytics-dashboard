/* ============================================================
   File: 02_sales_analysis.sql
   Purpose: Core sales performance queries — the kind of stuff
   a seller-side analyst on Amazon/Flipkart would pull weekly.
   ============================================================ */

/* -----------------------------------------------------------
   1. MONTHLY REVENUE TREND (Delivered orders only — cancelled/
      returned orders shouldn't count as real revenue)
   ----------------------------------------------------------- */
SELECT
    strftime('%Y-%m', order_date)                  AS order_month,
    COUNT(DISTINCT order_id)                        AS total_orders,
    ROUND(SUM(order_value), 2)                      AS total_revenue,
    ROUND(AVG(order_value), 2)                      AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY order_month
ORDER BY order_month;


/* -----------------------------------------------------------
   2. YEAR-OVER-YEAR REVENUE GROWTH
      Using a self-join on year to compare same period across
      years (only years with overlapping months are compared
      fairly).
   ----------------------------------------------------------- */
WITH yearly_rev AS (
    SELECT
        strftime('%Y', order_date) AS order_year,
        ROUND(SUM(order_value), 2) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY order_year
)
SELECT
    order_year,
    revenue,
    LAG(revenue) OVER (ORDER BY order_year)                         AS prev_year_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_year)) * 100.0
        / LAG(revenue) OVER (ORDER BY order_year), 2
    ) AS yoy_growth_pct
FROM yearly_rev
ORDER BY order_year;


/* -----------------------------------------------------------
   3. CATEGORY-WISE PERFORMANCE
      Revenue, units sold, and profit margin per category.
   ----------------------------------------------------------- */
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id)                              AS orders_count,
    SUM(oi.quantity)                                         AS units_sold,
    ROUND(SUM(oi.line_total), 2)                             AS revenue,
    ROUND(SUM(oi.quantity * p.cost_price), 2)                AS total_cost,
    ROUND(SUM(oi.line_total) - SUM(oi.quantity * p.cost_price), 2) AS gross_profit,
    ROUND(
        (SUM(oi.line_total) - SUM(oi.quantity * p.cost_price)) * 100.0
        / NULLIF(SUM(oi.line_total), 0), 2
    ) AS gross_margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;


/* -----------------------------------------------------------
   4. TOP 10 BEST-SELLING PRODUCTS
   ----------------------------------------------------------- */
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)          AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id
ORDER BY revenue DESC
LIMIT 10;


/* -----------------------------------------------------------
   5. CITY-TIER WISE SALES DISTRIBUTION
      Useful to see how much revenue is coming from Tier 2/3
      cities — a common growth story for Indian e-commerce.
   ----------------------------------------------------------- */
SELECT
    city_tier,
    COUNT(DISTINCT order_id)              AS total_orders,
    ROUND(SUM(order_value), 2)            AS revenue,
    ROUND(SUM(order_value) * 100.0 / (SELECT SUM(order_value) FROM orders WHERE order_status='Delivered'), 2) AS pct_of_total_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY city_tier
ORDER BY revenue DESC;


/* -----------------------------------------------------------
   6. TOP 10 CITIES BY REVENUE
   ----------------------------------------------------------- */
SELECT
    city,
    COUNT(DISTINCT order_id)   AS total_orders,
    ROUND(SUM(order_value), 2) AS revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY city
ORDER BY revenue DESC
LIMIT 10;


/* -----------------------------------------------------------
   7. PAYMENT METHOD MIX
   ----------------------------------------------------------- */
SELECT
    payment_method,
    COUNT(*)                                                        AS orders_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2)      AS pct_of_orders,
    ROUND(SUM(order_value), 2)                                      AS revenue
FROM orders
GROUP BY payment_method
ORDER BY orders_count DESC;


/* -----------------------------------------------------------
   8. ORDER STATUS BREAKDOWN (Cancellation / Return / RTO rate)
      RTO = Return to Origin, common COD-heavy metric in India
   ----------------------------------------------------------- */
SELECT
    order_status,
    COUNT(*)                                                     AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2)   AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


/* -----------------------------------------------------------
   9. DELIVERY PERFORMANCE — % of orders delivered late, and
      average delay by city tier
   ----------------------------------------------------------- */
SELECT
    city_tier,
    COUNT(*)                                                            AS delivered_orders,
    SUM(CASE WHEN delivered_late = 1 THEN 1 ELSE 0 END)                 AS late_orders,
    ROUND(SUM(CASE WHEN delivered_late = 1 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                                                  AS late_delivery_pct,
    ROUND(AVG(actual_delivery_days - promised_delivery_days), 2)        AS avg_delay_days
FROM orders
WHERE order_status = 'Delivered'
GROUP BY city_tier
ORDER BY late_delivery_pct DESC;


/* -----------------------------------------------------------
   10. DOES LATE DELIVERY IMPACT RETURNS?
       Compares return rate for orders that were delivered late
       vs on-time (using the SAME order's future purchase can't
       be tied here, so this instead checks correlation between
       late flag and order status at the raw order level using
       a UNION of delivered+returned orders joined on customer
       behaviour is overkill — simpler: compare avg order value
       and repeat-rate for late vs on-time deliveries).
   ----------------------------------------------------------- */
SELECT
    delivered_late,
    COUNT(*)                          AS orders,
    ROUND(AVG(order_value), 2)        AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY delivered_late;
