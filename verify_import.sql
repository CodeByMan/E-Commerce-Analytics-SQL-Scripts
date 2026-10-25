USE Brz_Ecomerce;

SELECT 'orders' AS table_name, COUNT(*) AS rows_loaded FROM dbo.orders
UNION ALL SELECT 'customer', COUNT(*) FROM dbo.customer
UNION ALL SELECT 'order_item', COUNT(*) FROM dbo.order_item
UNION ALL SELECT 'order_payments', COUNT(*) FROM dbo.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM dbo.order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM dbo.products
UNION ALL SELECT 'sellers', COUNT(*) FROM dbo.sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM dbo.geolocation
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM dbo.product_category_name_translation;

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('orders', 'customer', 'order_item', 'order_payments', 'order_reviews',
                     'products', 'sellers', 'geolocation', 'product_category_name_translation')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SELECT COUNT(*) AS duplicate_order_ids FROM (
    SELECT order_id FROM dbo.orders GROUP BY order_id HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS duplicate_customer_ids FROM (
    SELECT customer_id FROM dbo.customer GROUP BY customer_id HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS duplicate_order_items FROM (
    SELECT order_id, order_item_id FROM dbo.order_item
    GROUP BY order_id, order_item_id HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS duplicate_payment_rows FROM (
    SELECT order_id, payment_sequential FROM dbo.order_payments
    GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS orders_without_customers
FROM dbo.orders AS o
LEFT JOIN dbo.customer AS c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS items_without_orders
FROM dbo.order_item AS i
LEFT JOIN dbo.orders AS o ON o.order_id = i.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS items_without_products
FROM dbo.order_item AS i
LEFT JOIN dbo.products AS p ON p.product_id = i.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS items_without_sellers
FROM dbo.order_item AS i
LEFT JOIN dbo.sellers AS s ON s.seller_id = i.seller_id
WHERE s.seller_id IS NULL;

SELECT COUNT(*) AS payments_without_orders
FROM dbo.order_payments AS p
LEFT JOIN dbo.orders AS o ON o.order_id = p.order_id
WHERE o.order_id IS NULL;
