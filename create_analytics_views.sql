USE Brz_Ecomerce;

EXEC(N'CREATE OR ALTER VIEW dbo.vw_orders_detail AS
WITH pagos AS (
    SELECT order_id, SUM(payment_value) AS valor_pago,
           CASE WHEN COUNT(DISTINCT payment_type) = 1 THEN MAX(payment_type)
                ELSE ''mixed'' END AS tipo_pago
    FROM dbo.order_payments
    GROUP BY order_id
), resenas AS (
    SELECT order_id, AVG(CAST(review_score AS DECIMAL(5,2))) AS puntaje_resena
    FROM dbo.order_reviews
    GROUP BY order_id
)
SELECT o.order_id, o.order_status,
       o.order_purchase_timestamp AS fecha_compra,
       o.order_approved_at AS fecha_aprobacion,
       o.order_delivered_carrier_date AS fecha_envio_transportista,
       o.order_estimated_delivery_date AS fecha_entrega_estimada,
       oi.shipping_limit_date AS fecha_limite_envio,
       o.order_delivered_customer_date AS fecha_entrega_cliente,
       oi.product_id, t.product_category_name_english AS categoria_producto,
       oi.order_item_id, r.puntaje_resena, pg.tipo_pago, pg.valor_pago,
       oi.price AS precio, oi.freight_value AS valor_flete,
       c.customer_id, c.customer_zip_code_prefix AS codigo_postal_cliente,
       c.customer_city AS ciudad_cliente, c.customer_state AS estado_cliente,
       s.seller_id, s.seller_zip_code_prefix AS codigo_postal_vendedor,
       s.seller_city AS ciudad_vendedor, s.seller_state AS estado_vendedor
FROM dbo.orders AS o
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
LEFT JOIN dbo.order_item AS oi ON oi.order_id = o.order_id
LEFT JOIN dbo.products AS p ON p.product_id = oi.product_id
LEFT JOIN dbo.product_category_name_translation AS t
    ON t.product_category_name = p.product_category_name
LEFT JOIN dbo.sellers AS s ON s.seller_id = oi.seller_id
LEFT JOIN pagos AS pg ON pg.order_id = o.order_id
LEFT JOIN resenas AS r ON r.order_id = o.order_id');

EXEC(N'CREATE OR ALTER VIEW dbo.vw_info_clientes AS
WITH items AS (
    SELECT order_id, COUNT(*) AS unidades, SUM(freight_value) AS flete
    FROM dbo.order_item GROUP BY order_id
), pagos AS (
    SELECT order_id, SUM(payment_value) AS pago
    FROM dbo.order_payments GROUP BY order_id
), resenas AS (
    SELECT order_id, COUNT(*) AS cantidad
    FROM dbo.order_reviews GROUP BY order_id
)
SELECT c.customer_id, c.customer_zip_code_prefix AS codigo_postal_cliente,
       c.customer_city AS ciudad_cliente, c.customer_state AS estado_cliente,
       SUM(COALESCE(r.cantidad, 0)) AS cantidad_resenas,
       SUM(COALESCE(i.unidades, 0)) AS total_productos_comprados,
       SUM(p.pago) * 1.0 / NULLIF(SUM(i.unidades), 0) AS ticket_promedio_por_producto,
       SUM(p.pago) AS total_compra_cliente,
       SUM(i.flete) AS total_pago_flete,
       SUM(i.flete) * 100.0 / NULLIF(SUM(p.pago), 0) AS porcentaje_flete_sobre_compra
FROM dbo.customer AS c
JOIN dbo.orders AS o ON o.customer_id = c.customer_id
LEFT JOIN items AS i ON i.order_id = o.order_id
LEFT JOIN pagos AS p ON p.order_id = o.order_id
LEFT JOIN resenas AS r ON r.order_id = o.order_id
GROUP BY c.customer_id, c.customer_zip_code_prefix, c.customer_city, c.customer_state');

EXEC(N'CREATE OR ALTER VIEW dbo.vw_info_vendedores AS
WITH vendedor_orden AS (
    SELECT seller_id, order_id, COUNT(*) AS unidades, SUM(price) AS valor_items
    FROM dbo.order_item
    GROUP BY seller_id, order_id
), resenas AS (
    SELECT order_id, COUNT(*) AS cantidad,
           AVG(CAST(review_score AS DECIMAL(5,2))) AS puntaje
    FROM dbo.order_reviews GROUP BY order_id
)
SELECT s.seller_id, s.seller_zip_code_prefix AS codigo_postal_vendedor,
       s.seller_city AS ciudad_vendedor, s.seller_state AS estado_vendedor,
       COUNT(*) AS cant_ordenes, SUM(v.unidades) AS total_unidades_vendidas,
       COUNT(DISTINCT c.customer_id) AS cant_clientes_atendidos,
       COUNT(DISTINCT c.customer_city) AS cant_ciudades_atendidas,
       COUNT(DISTINCT c.customer_state) AS cant_estados_atendidos,
       SUM(v.valor_items) AS total_ventas,
       SUM(v.valor_items) * 1.0 / NULLIF(COUNT(*), 0) AS ticket_promedio_por_orden,
       COUNT(DISTINCT c.customer_id) * 1.0 / NULLIF(COUNT(DISTINCT c.customer_city), 0)
           AS promedio_clientes_por_ciudad,
       SUM(COALESCE(r.cantidad, 0)) AS total_resenas,
       AVG(r.puntaje) AS promedio_resena
FROM vendedor_orden AS v
JOIN dbo.sellers AS s ON s.seller_id = v.seller_id
JOIN dbo.orders AS o ON o.order_id = v.order_id
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
LEFT JOIN resenas AS r ON r.order_id = v.order_id
GROUP BY s.seller_id, s.seller_zip_code_prefix, s.seller_city, s.seller_state');

EXEC(N'CREATE OR ALTER VIEW dbo.vw_info_producto AS
SELECT oi.product_id, t.product_category_name_english AS categoria_producto,
       c.customer_state AS estado, c.customer_city AS ciudad,
       MIN(oi.price) AS precio_minimo, MAX(oi.price) AS precio_maximo,
       AVG(CAST(oi.price AS DECIMAL(18,2))) AS precio_promedio,
       SUM(oi.price) AS total_acumulado_real,
       COUNT(DISTINCT oi.order_id) AS total_ordenes_del_producto,
       COUNT(*) AS total_unidades_vendidas
FROM dbo.order_item AS oi
JOIN dbo.orders AS o ON o.order_id = oi.order_id
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
JOIN dbo.products AS p ON p.product_id = oi.product_id
LEFT JOIN dbo.product_category_name_translation AS t
    ON t.product_category_name = p.product_category_name
GROUP BY oi.product_id, t.product_category_name_english,
         c.customer_state, c.customer_city');

EXEC(N'CREATE OR ALTER VIEW dbo.vw_info_pagos AS
SELECT p.payment_type AS metodo_pago, c.customer_state AS estado_cliente,
       c.customer_city AS ciudad_cliente,
       COUNT(DISTINCT p.order_id) AS cantidad_de_ordenes,
       COUNT(*) AS veces_usado, SUM(p.payment_value) AS total_pagado
FROM dbo.order_payments AS p
JOIN dbo.orders AS o ON o.order_id = p.order_id
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
GROUP BY p.payment_type, c.customer_state, c.customer_city');

EXEC(N'CREATE OR ALTER VIEW dbo.vw_info_zonas AS
WITH items AS (
    SELECT order_id, COUNT(*) AS unidades, MIN(freight_value) AS flete_min,
           MAX(freight_value) AS flete_max,
           AVG(CAST(freight_value AS DECIMAL(18,2))) AS flete_prom
    FROM dbo.order_item GROUP BY order_id
), pagos AS (
    SELECT order_id, SUM(payment_value) AS pago
    FROM dbo.order_payments GROUP BY order_id
), resenas AS (
    SELECT order_id, AVG(CAST(review_score AS DECIMAL(5,2))) AS puntaje
    FROM dbo.order_reviews GROUP BY order_id
), zona AS (
    SELECT c.customer_state AS estado, c.customer_city AS ciudad,
           c.customer_zip_code_prefix AS codigo_zip,
           COUNT(DISTINCT c.customer_id) AS cant_clientes,
           SUM(p.pago) AS total_pagado, AVG(p.pago) AS pago_promedio,
           COUNT(*) AS total_ordenes, SUM(i.unidades) AS total_items_vendidos,
           AVG(r.puntaje) AS puntaje_prom_resena_por_orden,
           MIN(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS cant_dias_min_de_entrega,
           MAX(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS cant_dias_max_de_entrega,
           AVG(CAST(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS DECIMAL(10,2))) AS cant_dias_prom_de_entrega,
           MIN(i.flete_min) AS costo_min_flete,
           MAX(i.flete_max) AS costo_max_flete,
           AVG(i.flete_prom) AS costo_prom_flete
    FROM dbo.orders AS o
    JOIN dbo.customer AS c ON c.customer_id = o.customer_id
    LEFT JOIN items AS i ON i.order_id = o.order_id
    LEFT JOIN pagos AS p ON p.order_id = o.order_id
    LEFT JOIN resenas AS r ON r.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp
    GROUP BY c.customer_state, c.customer_city, c.customer_zip_code_prefix
), vendedores AS (
    SELECT c.customer_state AS estado, c.customer_city AS ciudad,
           c.customer_zip_code_prefix AS codigo_zip,
           COUNT(DISTINCT oi.seller_id) AS cant_vendedores
    FROM dbo.orders AS o
    JOIN dbo.customer AS c ON c.customer_id = o.customer_id
    JOIN dbo.order_item AS oi ON oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp
    GROUP BY c.customer_state, c.customer_city, c.customer_zip_code_prefix
)
SELECT z.*, COALESCE(v.cant_vendedores, 0) AS cant_vendedores
FROM zona AS z
LEFT JOIN vendedores AS v ON v.estado = z.estado AND v.ciudad = z.ciudad
    AND v.codigo_zip = z.codigo_zip');
