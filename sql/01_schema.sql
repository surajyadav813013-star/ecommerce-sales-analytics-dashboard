/* ============================================================
   E-COMMERCE SALES ANALYTICS DASHBOARD
   File: 01_schema.sql
   Purpose: Table structure for the 4 core tables used in this
   project. Built this on a synthetic dataset modeled after a
   typical Indian D2C/marketplace seller (like Amazon/Flipkart
   seller panel exports) so I could practice real analyst SQL
   without needing an actual company's data.
   ============================================================ */

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   TEXT,
    city            TEXT,
    city_tier       TEXT,       -- Tier 1 / Tier 2 / Tier 3
    signup_date     DATE,
    gender          TEXT,
    age             INTEGER
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT,
    category        TEXT,
    price           REAL,
    cost_price      REAL
);

CREATE TABLE orders (
    order_id                INTEGER PRIMARY KEY,
    customer_id             INTEGER REFERENCES customers(customer_id),
    order_date              DATE,
    order_datetime          DATETIME,
    city                    TEXT,
    city_tier               TEXT,
    payment_method          TEXT,   -- UPI / Credit Card / Debit Card / Net Banking / COD
    order_status            TEXT,   -- Delivered / Cancelled / Returned / RTO
    order_value             REAL,
    promised_delivery_days  INTEGER,
    actual_delivery_days    REAL,
    delivered_late          BOOLEAN,
    delivery_date           DATE
);

CREATE TABLE order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER REFERENCES orders(order_id),
    product_id      INTEGER REFERENCES products(product_id),
    quantity        INTEGER,
    unit_price      REAL,
    discount_pct    REAL,
    line_total      REAL
);

/* Quick sanity checks I always run first on a new dataset */
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
