import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

random.seed(42)
np.random.seed(42)

# ---------------- CONFIG ----------------
N_CUSTOMERS = 1200
N_PRODUCTS = 150
N_ORDERS = 8000
START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2026, 6, 30)

cities = ["Mumbai","Delhi","Bengaluru","Hyderabad","Ahmedabad","Chennai","Kolkata",
          "Pune","Jaipur","Surat","Lucknow","Kanpur","Nagpur","Indore","Bhopal",
          "Patna","Ghaziabad","Vadodara","Coimbatore","Guwahati"]

city_tier = {c: ("Tier 1" if c in ["Mumbai","Delhi","Bengaluru","Hyderabad","Chennai","Kolkata","Pune"] else
                  "Tier 2" if c in ["Ahmedabad","Jaipur","Surat","Lucknow","Kanpur","Nagpur","Indore","Bhopal","Vadodara","Coimbatore"] else
                  "Tier 3") for c in cities}

categories = {
    "Electronics": ["Smartphone","Earbuds","Smartwatch","Laptop","Power Bank","Bluetooth Speaker","Tablet","Camera"],
    "Fashion": ["Men's T-Shirt","Women's Kurti","Jeans","Sneakers","Handbag","Sunglasses","Formal Shirt","Saree"],
    "Home & Kitchen": ["Mixer Grinder","Non-stick Pan","Bedsheet Set","LED Bulb","Storage Box","Water Bottle","Cushion Cover"],
    "Beauty & Personal Care": ["Face Wash","Shampoo","Perfume","Lipstick","Trimmer","Moisturizer"],
    "Books": ["Fiction Novel","Self-help Book","Competitive Exam Guide","Comic Book"],
    "Sports & Fitness": ["Yoga Mat","Dumbbells Set","Cricket Bat","Football","Resistance Band"],
    "Grocery": ["Basmati Rice 5kg","Cooking Oil 1L","Green Tea Pack","Dry Fruits Combo","Spices Combo"]
}

payment_methods = ["UPI","Credit Card","Debit Card","Net Banking","Cash on Delivery"]
payment_weights = [0.42, 0.18, 0.14, 0.08, 0.18]

order_status = ["Delivered","Delivered","Delivered","Delivered","Delivered","Cancelled","Returned","RTO"]
order_status_weights = [0.72,0.72,0.72,0.72,0.72,0.08,0.10,0.10]  # will normalize

first_names = ["Aarav","Vivaan","Aditya","Vihaan","Arjun","Sai","Reyansh","Krishna","Ishaan","Rohan",
               "Ananya","Diya","Saanvi","Aadhya","Myra","Pari","Anika","Navya","Riya","Priya",
               "Rahul","Amit","Suresh","Ramesh","Vikas","Neha","Pooja","Kavya","Isha","Sneha",
               "Karan","Manish","Deepak","Suraj","Ankit","Nisha","Swati","Meera","Tanvi","Yash"]
last_names = ["Sharma","Verma","Gupta","Kumar","Singh","Patel","Reddy","Iyer","Nair","Rao",
              "Mishra","Yadav","Chauhan","Joshi","Malhotra","Kapoor","Agarwal","Bansal","Chatterjee","Das"]

def random_date(start, end):
    delta = end - start
    rand_days = random.randint(0, delta.days)
    return start + timedelta(days=rand_days, hours=random.randint(0,23), minutes=random.randint(0,59))

# ---------------- CUSTOMERS ----------------
customers = []
for cid in range(1, N_CUSTOMERS+1):
    city = random.choice(cities)
    signup_date = random_date(START_DATE, END_DATE - timedelta(days=30))
    customers.append({
        "customer_id": cid,
        "customer_name": f"{random.choice(first_names)} {random.choice(last_names)}",
        "city": city,
        "city_tier": city_tier[city],
        "signup_date": signup_date.strftime("%Y-%m-%d"),
        "gender": random.choice(["Male","Female"]),
        "age": random.randint(18,55)
    })
customers_df = pd.DataFrame(customers)

# ---------------- PRODUCTS ----------------
products = []
pid = 1
for cat, items in categories.items():
    for item in items:
        for variant in range(1, random.randint(2,4)):
            base_price = {
                "Electronics": random.randint(800, 45000),
                "Fashion": random.randint(299, 3499),
                "Home & Kitchen": random.randint(199, 5999),
                "Beauty & Personal Care": random.randint(149, 1999),
                "Books": random.randint(99, 799),
                "Sports & Fitness": random.randint(199, 4999),
                "Grocery": random.randint(99, 1299)
            }[cat]
            cost_pct = random.uniform(0.55, 0.75)
            products.append({
                "product_id": pid,
                "product_name": f"{item} - Variant {variant}",
                "category": cat,
                "price": base_price,
                "cost_price": round(base_price*cost_pct,2)
            })
            pid += 1
products_df = pd.DataFrame(products).head(N_PRODUCTS)
products_df["product_id"] = range(1, len(products_df)+1)

# ---------------- ORDERS + ORDER ITEMS ----------------
# give customers a purchase-frequency skew (RFM-like realism: some are one-timers, some frequent)
customer_weights = np.random.exponential(scale=1.0, size=N_CUSTOMERS)
customer_weights = customer_weights / customer_weights.sum()

orders = []
order_items = []
order_id = 1
oi_id = 1

status_pool = ["Delivered"]*72 + ["Cancelled"]*8 + ["Returned"]*10 + ["RTO"]*10

for _ in range(N_ORDERS):
    cust = customers_df.sample(1, weights=customer_weights).iloc[0]
    signup = datetime.strptime(cust["signup_date"], "%Y-%m-%d")
    order_date = random_date(max(signup, START_DATE), END_DATE)
    status = random.choice(status_pool)
    payment = random.choices(payment_methods, weights=payment_weights, k=1)[0]

    n_items = random.choices([1,2,3,4], weights=[0.55,0.28,0.12,0.05])[0]
    chosen_products = products_df.sample(n_items)

    order_value = 0
    for _, prod in chosen_products.iterrows():
        qty = random.choices([1,2,3], weights=[0.75,0.2,0.05])[0]
        unit_price = prod["price"]
        discount_pct = random.choice([0,0,0,0.05,0.1,0.15,0.2,0.25])
        line_total = round(unit_price*qty*(1-discount_pct),2)
        order_value += line_total
        order_items.append({
            "order_item_id": oi_id,
            "order_id": order_id,
            "product_id": prod["product_id"],
            "quantity": qty,
            "unit_price": unit_price,
            "discount_pct": discount_pct,
            "line_total": line_total
        })
        oi_id += 1

    # delivery timing
    if status == "Delivered":
        promised_days = random.choice([2,3,4,5,7])
        actual_days = max(1, promised_days + random.choice([-1,0,0,0,1,1,2,3]))
        delivery_date = order_date + timedelta(days=actual_days)
        delivered_late = actual_days > promised_days
    else:
        promised_days = random.choice([2,3,4,5,7])
        actual_days = None
        delivery_date = None
        delivered_late = None

    orders.append({
        "order_id": order_id,
        "customer_id": cust["customer_id"],
        "order_date": order_date.strftime("%Y-%m-%d"),
        "order_datetime": order_date.strftime("%Y-%m-%d %H:%M:%S"),
        "city": cust["city"],
        "city_tier": cust["city_tier"],
        "payment_method": payment,
        "order_status": status,
        "order_value": round(order_value,2),
        "promised_delivery_days": promised_days,
        "actual_delivery_days": actual_days,
        "delivered_late": delivered_late,
        "delivery_date": delivery_date.strftime("%Y-%m-%d") if delivery_date else None
    })
    order_id += 1

orders_df = pd.DataFrame(orders)
order_items_df = pd.DataFrame(order_items)

# ---------------- SAVE ----------------
customers_df.to_csv("data/customers.csv", index=False)
products_df.to_csv("data/products.csv", index=False)
orders_df.to_csv("data/orders.csv", index=False)
order_items_df.to_csv("data/order_items.csv", index=False)

print("customers:", customers_df.shape)
print("products:", products_df.shape)
print("orders:", orders_df.shape)
print("order_items:", order_items_df.shape)
print(orders_df.head(3).to_string())
