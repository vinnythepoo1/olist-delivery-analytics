# 🛒 Olist Brazilian E-Commerce — Late Delivery Analysis

## Project Overview
This project analyzes the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — a real-world dataset consisting of **9 relational tables** covering orders, customers, products, sellers, payments, and reviews.

The goal is to identify what drives late deliveries and build a machine learning model to predict whether an order will arrive after its estimated delivery date.

**Business Question:**
> Among delivered orders, what factors predict whether an order will arrive later than estimated — and which regions, categories, and sellers are most at risk?

---

## Key Findings

- **8.11%** of delivered orders arrived late (~7,826 out of 96,454)
- **Northeast Brazil** has the highest late delivery rates — Alagoas (24%), Maranhão (20%), Piauí (16%) — driven by distance from seller hubs
- **Late delivery severely impacts customer satisfaction** — average review score drops from 4.30 (on time) to 2.62 (late)
- **March/April 2018** saw a spike to 21.4% late rate — likely linked to Carnival season logistics backlog
- **Heavy products (10kg+)** have the highest late delivery rate
- **Top ML predictors:** shipping time, estimated delivery days, purchase month — all time-based features, confirming that late delivery is primarily a logistics speed problem

---

## Data Leakage Finding
During ML feature selection, `review_score` was identified as **data leakage** — customers only leave reviews after delivery, so this column cannot be known at prediction time. Removing it dropped the late-class F1 from 0.52 → 0.33, reflecting honest model performance. This mirrors a similar leakage finding in a previous Shopee project.

---

## Project Structure

```
olist-ecommerce-analysis/
│
├── data/
│   ├── raw/                         # Original 9 CSV files from Kaggle
│   │   ├── olist_customers_dataset.csv
│   │   ├── olist_geolocation_dataset.csv
│   │   ├── olist_order_items_dataset.csv
│   │   ├── olist_order_payments_dataset.csv
│   │   ├── olist_order_reviews_dataset.csv
│   │   ├── olist_orders_dataset.csv
│   │   ├── olist_products_dataset.csv
│   │   ├── olist_sellers_dataset.csv
│   │   └── product_category_name_translation.csv
│   │
│   └── processed/
│       └── olist_final.csv          # Fully merged and cleaned dataset (96,454 rows × 36 cols)
│
├── notebooks/
│   └── olist_ecommerce_analysis.ipynb   # Full analysis pipeline
│
├── dashboard/
│   └── Olist_E-Commerce_project.pbix    # Power BI dashboard (2 pages)
│
├── images/
│   ├── eda/                         # EDA charts (Plotly)
│   └── ml/                          # ML feature importance charts
│
└── README.md
```

---

## Analysis Pipeline

### 1. Data Loading
All 9 CSV files loaded and inspected for shape, dtypes, and null values.

### 2. Target Variable Construction
- Filtered to `delivered` orders only — other statuses (canceled, shipped) represent a different business problem
- `is_late = 1` if `order_delivered_customer_date > order_estimated_delivery_date`, else 0
- Result: **8.11% late rate** → imbalanced dataset

### 3. Join Pipeline
Merged all 9 tables to order-level granularity (one row = one order):

| Join Design Decision | Reason |
|---|---|
| Aggregate `order_items` before joining | Avoid 1-to-many row inflation |
| Aggregate `order_payments` before joining | Multiple payment methods per order |
| Deduplicate `order_reviews` by most recent | Some orders had multiple reviews |
| Use mode for product/seller per order | Multi-item orders need one representative value |

Final shape after all joins: **96,478 rows × 36 columns**

### 4. Data Cleaning
- Rows with nulls in critical columns dropped (< 30 rows, negligible)
- `review_score` nulls (646) → filled with median
- `product_category_name_english` nulls (1,380) → filled with 'unknown'
- Product dimension nulls → filled with column median
- Final shape: **96,454 rows × 30 columns, zero nulls**

### 5. Exploratory Data Analysis
EDA structured around 3 business angles:

**Angle 1 — Delivery Performance**
- Late rate by customer state
- Late rate by product category
- Late rate over time

**Angle 2 — Customer Experience**
- Review score vs late delivery

**Angle 3 — Seller & Product Analysis**
- Late rate by seller state
- Product weight vs late rate
- Category revenue vs late rate

### 6. Machine Learning
- **Model:** Random Forest Classifier
- **Class imbalance handling:** `class_weight='balanced'` (8.1% minority class)
- **Evaluation:** Precision, Recall, F1-Score (not accuracy)

**Results (after removing data leakage):**

| Class | Precision | Recall | F1-Score |
|---|---|---|---|
| On Time (0) | 0.93 | 0.98 | 0.96 |
| Late (1) | 0.56 | 0.23 | 0.33 |

**Top 3 Feature Importances:**
1. `shipping_time` — time from approval to carrier pickup
2. `estimated_delivery_days` — how optimistic Olist's delivery estimate was
3. `purchase_month` — seasonal demand effects

---

## Power BI Dashboard
Two-page interactive dashboard:
- **Page 1:** Late Delivery Analysis — map, time series, category breakdown, KPI cards
- **Page 2:** Seller & Product Analysis — seller state performance, weight group analysis, revenue vs late rate scatter

---

## Tools & Technologies
- **Python** — pandas, scikit-learn, Plotly
- **Jupyter Notebook**
- **Power BI Desktop**
- **GitHub**

---

## Dataset Source
[Olist Brazilian E-Commerce Public Dataset — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
