-- ============================================================
-- Superstore — Sales & Profitability Analysis
-- Dataset: superstore_clean.csv
-- Table: orders
-- ============================================================


-- В1. Сколько заказов в каждой категории товаров и какую долю они занимают?
SELECT category,
       COUNT(order_id) AS total_orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM orders
GROUP BY category
ORDER BY total_orders DESC;


-- В2. Какая категория товаров приносит наибольшую общую прибыль?
SELECT category,
       COUNT(order_id) AS total_orders,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit), 2) AS total_profit,
       ROUND(AVG(profit_margin), 3) AS avg_margin
FROM orders
GROUP BY category
ORDER BY total_profit DESC;


-- В3. Подтверждается ли, что скидка выше 20% снижает прибыль заказа?
SELECT 
    CASE 
        WHEN discount > 0.2 THEN 'Высокая скидка (>20%)'
        ELSE 'Низкая скидка (<=20%)'
    END AS discount_group,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(profit), 2) AS avg_profit,
    ROUND(100.0 * SUM(CASE WHEN profit > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS profitable_share_pct
FROM orders
GROUP BY discount_group
ORDER BY avg_profit DESC;


-- В4. Сравнение средней прибыли и срока доставки между быстрыми и медленными заказами.
SELECT 
    CASE 
        WHEN delivery_days <= 4 THEN 'Быстрая доставка (<=4 дня)'
        ELSE 'Медленная доставка (>4 дней)'
    END AS delivery_group,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(profit), 2) AS avg_profit,
    ROUND(AVG(shipping_cost), 2) AS avg_shipping_cost
FROM orders
GROUP BY delivery_group;


-- В5. Какой рынок (Market) даёт наибольшую среднюю прибыль на заказ?
SELECT market,
       COUNT(order_id) AS total_orders,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(AVG(profit), 2) AS avg_profit
FROM orders
GROUP BY market
ORDER BY avg_profit DESC;


-- В6. Какие 5 заказов принесли наибольшую прибыль?
SELECT order_id,
       category,
       sub_category,
       market,
       segment,
       ROUND(sales, 2) AS sales,
       ROUND(profit, 2) AS profit
FROM orders
ORDER BY profit DESC
LIMIT 5;


-- В7. Различается ли средняя прибыль между сегментами клиентов?
SELECT segment,
       COUNT(order_id) AS total_orders,
       ROUND(AVG(sales), 2) AS avg_sales,
       ROUND(AVG(profit), 2) AS avg_profit,
       ROUND(AVG(discount), 3) AS avg_discount
FROM orders
GROUP BY segment
ORDER BY avg_profit DESC;


-- В8. Разделить заказы на группы по марже прибыли и показать количество в каждой.
WITH margin_groups AS (
    SELECT order_id,
           profit_margin,
           CASE
               WHEN profit_margin < 0          THEN 'Убыточные'
               WHEN profit_margin BETWEEN 0 AND 0.1 THEN 'Низкая маржа'
               ELSE 'Высокая маржа'
           END AS margin_tier
    FROM orders
)
SELECT margin_tier,
       COUNT(*) AS total_orders,
       ROUND(AVG(profit_margin), 3) AS avg_margin
FROM margin_groups
GROUP BY margin_tier
ORDER BY avg_margin DESC;


-- В9. Какие топ-3 подкатегории по прибыли внутри каждой категории товаров?
WITH subcat_stats AS (
    SELECT category,
           sub_category,
           ROUND(SUM(profit), 2) AS total_profit,
           COUNT(order_id) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(profit) DESC) AS profit_rank
    FROM orders
    GROUP BY category, sub_category
)
SELECT profit_rank,
       category,
       sub_category,
       total_profit,
       total_orders
FROM subcat_stats
WHERE profit_rank <= 3
ORDER BY category, profit_rank;


-- В10. Как прибыль каждого заказа соотносится со средней прибылью по его категории?
SELECT order_id,
       category,
       market,
       ROUND(profit, 2) AS profit,
       ROUND(AVG(profit) OVER (PARTITION BY category), 2) AS category_avg_profit,
       ROUND(profit - AVG(profit) OVER (PARTITION BY category), 2) AS diff_from_avg,
       RANK() OVER (PARTITION BY category ORDER BY profit DESC) AS rank_in_category
FROM orders
ORDER BY category, rank_in_category
LIMIT 20;
