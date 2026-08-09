E-commerce Sales Analytics Dashboard
End-to-end sales analytics project on a synthetic Indian D2C/marketplace dataset (modeled after
a typical Amazon/Flipkart seller panel export) — built to practice the full analyst pipeline:
SQL for analysis → Excel for a formula-driven dashboard → Power BI for interactive
visualization.
Dataset
Synthetic, generated for this project (generate_data.py) — no real customer data used.
Table
Rows
Description
customers
1,200
customer_id, city, city tier, signup date, demographics
products
86
7 categories (Electronics, Fashion, Home & Kitchen, Beauty, Books, Sports, Grocery)
orders
8,000
Jan 2024 – Jun 2026, order value, payment method, status, delivery timing
order_items
13,404
line-item level detail (qty, price, discount, line total)
What's in this repo
Code
sql/
  01_schema.sql              -- table structure + sanity checks
  02_sales_analysis.sql      -- monthly revenue, YoY growth, category performance,
                                 top products, city-tier split, payment mix,
                                 order status breakdown, delivery performance
  03_customer_analysis.sql   -- repeat purchase rate, top customers,
                                 new vs returning trend, AOV by city tier

Ecommerce_Sales_Dashboard.xlsx  -- formula-driven Excel dashboard (SUMIFS/COUNTIFS,
                                    zero hardcoded numbers, 5 charts, KPI cards)

powerbi/
  data/                       -- star-schema CSVs ready to import into Power BI Desktop
  PowerBI_Build_Guide.md      -- step-by-step import + DAX measures + page layout

data/                         -- raw generated CSVs + SQLite database (ecommerce.db)
Key metrics covered
Monthly revenue trend & YoY growth
Category-wise revenue and gross margin
Top-selling products and top customers
City-tier (Tier 1/2/3) revenue distribution — Indian e-commerce growth story
Payment method mix (UPI-heavy, as expected for Indian D2C)
Order status breakdown (Delivered / Cancelled / Returned / RTO)
Delivery performance — late delivery % by city tier
Repeat purchase rate, new vs returning customers
How each piece was built
Data generation — generate_data.py (Python/pandas) creates realistic, internally
consistent orders, items, customers and products with seasonal and behavioral variation
(e.g. exponential customer purchase-frequency skew, category-appropriate pricing).
SQL — loaded into SQLite (data/ecommerce.db), queries written and tested to run
error-free (window functions for YoY, CTEs for repeat-rate and cohort-style new/returning
split).
Excel — openpyxl-built workbook. All summary sheets use live SUMIFS/COUNTIFS/
AVERAGE formulas referencing the raw data sheets — nothing is hardcoded, so the dashboard
recalculates if the raw data changes. Verified with LibreOffice recalculation (0 formula
errors across 5,882 formulas).
Power BI — since a .pbix can't be generated outside Power BI Desktop, this project
ships the cleaned star-schema CSVs plus a full build guide (relationships, DAX measures,
page layout) so the report can be assembled in ~20–30 minutes and published/screenshotted
for the portfolio.
Sample insight
Tier 2/3 cities contribute a meaningful share of delivered revenue despite longer average
delivery times — a common finding in real Indian e-commerce data and a good talking point in
an interview about this project.# ecommerce-sales-analytics-dashboard
End-to-end e-commerce sales analytics project on a synthetic Indian D2C dataset — SQL analysis (revenue trends, category performance, delivery metrics), a formula-driven Excel dashboard, and a Power BI build guide with DAX measures.
