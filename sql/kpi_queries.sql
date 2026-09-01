--fix data type--
ALTER TABLE olist_final
    ALTER COLUMN order_purchase_timestamp TYPE timestamp USING order_purchase_timestamp::timestamp,
    ALTER COLUMN order_approved_at TYPE timestamp USING order_approved_at::timestamp,
    ALTER COLUMN order_delivered_carrier_date TYPE timestamp USING order_delivered_carrier_date::timestamp,
    ALTER COLUMN order_delivered_customer_date TYPE timestamp USING order_delivered_customer_date::timestamp,
    ALTER COLUMN order_estimated_delivery_date TYPE timestamp USING order_estimated_delivery_date::timestamp;

	SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'olist_final' AND column_name LIKE 'order_%';

-- What percentage of orders are late, and what's the revenue/satisfaction context?
SELECT
    COUNT(*) AS total_orders,
    SUM(is_late) AS late_orders,
    ROUND(AVG(is_late) * 100, 2) AS late_delivery_rate_pct,
    ROUND(SUM(total_price)::numeric, 2) AS total_revenue,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM olist_final;


-- Is revenue growing month over month, and how does delivery performance track alongside it?
WITH monthly AS (
    SELECT
        order_month,
        COUNT(*) AS order_count,
        SUM(total_price) AS monthly_revenue,
        AVG(is_late) * 100 AS late_delivery_rate_pct
    FROM olist_final
    WHERE order_month >= '2017-01'   -- exclude the sparse pre-launch months
    GROUP BY order_month
)
SELECT
    order_month,
    order_count,
    ROUND(monthly_revenue::numeric, 2) AS m onthly_revenue,
    ROUND(late_delivery_rate_pct::numeric, 2) AS late_delivery_rate_pct,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY order_month), 0) * 100)::numeric
    , 2) AS revenue_growth_pct_mom
FROM monthly
ORDER BY order_month;


-- Which product categories should we protect and invest in?
WITH category_revenue AS (
    SELECT
        product_category_name_english AS category,
        COUNT(*) AS order_count,
        SUM(total_price) AS total_revenue,
        AVG(is_late) * 100 AS late_delivery_rate_pct
    FROM olist_final
    GROUP BY product_category_name_english
)
SELECT
    category,
    order_count,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND(late_delivery_rate_pct::numeric, 2) AS late_delivery_rate_pct,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_revenue
ORDER BY total_revenue DESC
LIMIT 15;


-- Which states are our biggest markets, and where should we focus expansion?
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_price)::numeric, 2) AS total_revenue,
    ROUND((SUM(total_price) * 100.0 / SUM(SUM(total_price)) OVER ())::numeric, 2) AS pct_of_total_revenue
FROM olist_final
GROUP BY customer_state
ORDER BY total_revenue DESC;


-- Which states have the worst delivery reliability?
SELECT
    customer_state,
    COUNT(*) AS order_count,
    ROUND(AVG(is_late) * 100, 2) AS late_delivery_rate_pct
FROM olist_final
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY late_delivery_rate_pct DESC;


-- How much does a late delivery actually cost us in customer satisfaction?
SELECT
    is_late,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM olist_final
GROUP BY is_late;


-- Which payment methods drive the most revenue, and do any carry a hidden delivery-risk cost?
SELECT
    payment_type,
    COUNT(*) AS order_count,
    ROUND(SUM(total_price)::numeric, 2) AS total_revenue,
    ROUND((SUM(total_price) * 100.0 / SUM(SUM(total_price)) OVER ())::numeric, 2) AS pct_of_total_revenue,
    ROUND(AVG(is_late) * 100, 2) AS late_delivery_rate_pct
FROM olist_final
GROUP BY payment_type
ORDER BY total_revenue DESC;


-- What percentage of our customer base is repeat business, and how much revenue does each group drive?
WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS order_count,
        SUM(total_price) AS customer_revenue
    FROM olist_final
    GROUP BY customer_unique_id
)
SELECT
    CASE WHEN order_count > 1 THEN 'repeat' ELSE 'one_time' END AS buyer_type,
    COUNT(*) AS customer_count,
    ROUND(SUM(customer_revenue)::numeric, 2) AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_customer_base
FROM customer_orders
GROUP BY buyer_type;