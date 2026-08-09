# Power BI Dashboard — Build Guide
### E-commerce Sales Analytics Dashboard

**Note on this file:** Power BI's `.pbix` format is a proprietary binary that only Power BI
Desktop (Windows app) can create — it can't be generated from a script. So instead this folder
gives you everything ready to import: clean star-schema CSVs, the exact DAX measures to type in,
and a step-by-step visual layout. Following this takes about 20–30 minutes in Power BI Desktop
and gives you a genuine, screenshot-ready `.pbix` for your resume/GitHub.

---

## 1. Files in this folder (`/data`)

| File | Role | Rows |
|---|---|---|
| `orders.csv` | Fact table — one row per order | 8,000 |
| `order_items.csv` | Fact table — one row per line item | 13,404 |
| `products.csv` | Dimension table | 86 |
| `customers.csv` | Dimension table | 1,200 |

## 2. Import steps

1. Open Power BI Desktop → **Get Data → Text/CSV** → import all 4 CSVs.
2. Go to **Model view**. Create these relationships (drag column to column):
   - `orders[customer_id]` → `customers[customer_id]` (many-to-one)
   - `order_items[order_id]` → `orders[order_id]` (many-to-one)
   - `order_items[product_id]` → `products[product_id]` (many-to-one)
3. In **Power Query Editor**, set data types: `order_date`/`signup_date`/`delivery_date` →
   Date; `order_value`/`price`/`line_total` → Decimal Number; `delivered_late` → True/False.
4. Create a **Date table** (Modeling → New Table):
   ```
   DateTable = CALENDAR(DATE(2024,1,1), DATE(2026,6,30))
   ```
   Then add Year/Month columns and mark it as a Date Table (Modeling → Mark as Date Table).
   Relate `DateTable[Date]` → `orders[order_date]`.

## 3. DAX measures to create (Modeling → New Measure)

```dax
Total Revenue = CALCULATE(SUM(orders[order_value]), orders[order_status] = "Delivered")

Total Orders = CALCULATE(DISTINCTCOUNT(orders[order_id]), orders[order_status] = "Delivered")

Average Order Value = DIVIDE([Total Revenue], [Total Orders])

Cancelled Orders % =
DIVIDE(
    CALCULATE(COUNTROWS(orders), orders[order_status] = "Cancelled"),
    COUNTROWS(orders)
)

RTO + Returned % =
DIVIDE(
    CALCULATE(COUNTROWS(orders), orders[order_status] IN {"Returned","RTO"}),
    COUNTROWS(orders)
)

Late Delivery % =
DIVIDE(
    CALCULATE(COUNTROWS(orders), orders[delivered_late] = TRUE, orders[order_status]="Delivered"),
    CALCULATE(COUNTROWS(orders), orders[order_status]="Delivered")
)

YoY Revenue Growth % =
VAR CurrYear = [Total Revenue]
VAR PrevYear = CALCULATE([Total Revenue], SAMEPERIODLASTYEAR(DateTable[Date]))
RETURN DIVIDE(CurrYear - PrevYear, PrevYear)

Gross Profit =
SUMX(
    order_items,
    order_items[line_total] - (order_items[quantity] * RELATED(products[cost_price]))
)

Gross Margin % = DIVIDE([Gross Profit], SUM(order_items[line_total]))

Repeat Customers =
CALCULATE(
    DISTINCTCOUNT(orders[customer_id]),
    FILTER(
        VALUES(orders[customer_id]),
        CALCULATE(COUNTROWS(orders), orders[order_status]="Delivered") > 1
    )
)
```

## 4. Suggested page layout

**Page 1 — Executive Overview**
- KPI cards (top row): Total Revenue, Total Orders, Average Order Value, YoY Revenue Growth %
- Line chart: Total Revenue by Month (`DateTable[Month]` on axis)
- Bar chart: Revenue by Category
- Map or filled map: Revenue by City (use `orders[city]` — Power BI auto-geocodes Indian city names)
- Slicers: Date range, City Tier, Payment Method

**Page 2 — Customer Insights**
- Donut chart: New vs Returning customers by month
- Table: Top 15 customers by lifetime revenue
- Card: Repeat Purchase Rate
- Bar chart: AOV by City Tier

**Page 3 — Operations & Delivery**
- Bar chart: Late Delivery % by City Tier
- Stacked bar: Order Status breakdown (Delivered/Cancelled/Returned/RTO) by month
- Card: Gross Margin %
- Bar chart: Payment Method mix

## 5. Formatting tips for a resume-ready look

- Use a consistent 2–3 color theme (View → Themes → pick or customize).
- Format currency measures with `₹` and thousands separator (right-click measure → Format → Currency).
- Add a title text box per page and a consistent footer ("E-commerce Sales Analytics | Synthetic Dataset").
- Export each page as an image (File → Export → PDF, then screenshot) for your GitHub README and resume portfolio link.

## 6. Publishing (optional)

If you have a free Power BI account, **Publish** the report (Home → Publish) and share the
Power BI service link in your resume/portfolio alongside the screenshots.
