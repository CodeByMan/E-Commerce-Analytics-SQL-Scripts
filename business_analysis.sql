USE Brz_Ecomerce;

SELECT TOP (10) customer_state AS estado, COUNT(*) AS clientes
FROM dbo.customer
GROUP BY customer_state
ORDER BY clientes DESC, estado;

WITH primeras_compras AS (
    SELECT c.customer_id, MIN(o.order_purchase_timestamp) AS primera_compra
    FROM dbo.orders AS o
    JOIN dbo.customer AS c ON c.customer_id = o.customer_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_id
), clientes_mensuales AS (
    SELECT DATEFROMPARTS(YEAR(primera_compra), MONTH(primera_compra), 1) AS mes,
           COUNT(*) AS nuevos_clientes
    FROM primeras_compras
    GROUP BY YEAR(primera_compra), MONTH(primera_compra)
), crecimiento AS (
    SELECT mes, nuevos_clientes,
           LAG(nuevos_clientes) OVER (ORDER BY mes) AS mes_anterior
    FROM clientes_mensuales
)
SELECT mes, nuevos_clientes, mes_anterior,
       (nuevos_clientes - mes_anterior) * 100.0 / NULLIF(mes_anterior, 0)
           AS crecimiento_porcentaje
FROM crecimiento
ORDER BY mes;

SELECT TOP (10) c.customer_city AS ciudad, c.customer_state AS estado,
       COUNT(*) AS ordenes
FROM dbo.orders AS o
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
GROUP BY c.customer_city, c.customer_state
ORDER BY ordenes DESC, estado, ciudad;

SELECT TOP (10) categoria_producto, SUM(total_unidades_vendidas) AS unidades
FROM dbo.vw_info_producto
GROUP BY categoria_producto
ORDER BY unidades DESC, categoria_producto;

SELECT TOP (10) categoria_producto, SUM(total_unidades_vendidas) AS unidades
FROM dbo.vw_info_producto
GROUP BY categoria_producto
ORDER BY unidades, categoria_producto;

SELECT customer_id, total_compra_cliente,
       total_compra_cliente * 1.0 / NULLIF(total_productos_comprados, 0)
           AS gasto_por_item
FROM dbo.vw_info_clientes
ORDER BY gasto_por_item DESC;

WITH pagos AS (
    SELECT order_id, SUM(payment_value) AS pago_orden
    FROM dbo.order_payments
    GROUP BY order_id
)
SELECT AVG(CAST(pago_orden AS DECIMAL(18,2))) AS ticket_promedio_por_orden
FROM pagos;

SELECT TOP (10) oi.product_id,
       SUM(oi.price) AS ventas_items,
       SUM(oi.freight_value) AS flete,
       SUM(oi.price) - SUM(oi.freight_value) AS ventas_menos_flete
FROM dbo.order_item AS oi
GROUP BY oi.product_id
ORDER BY ventas_menos_flete DESC, oi.product_id;

WITH categorias AS (
    SELECT categoria_producto, SUM(total_acumulado_real) AS ventas
    FROM dbo.vw_info_producto
    GROUP BY categoria_producto
), ranking AS (
    SELECT categoria_producto, ventas,
           ROW_NUMBER() OVER (ORDER BY ventas DESC, categoria_producto) AS posicion
    FROM categorias
)
SELECT SUM(CASE WHEN posicion <= 10 THEN ventas ELSE 0 END) * 100.0
           / NULLIF(SUM(ventas), 0) AS porcentaje_top_10,
       SUM(CASE WHEN posicion > 10 THEN ventas ELSE 0 END) * 100.0
           / NULLIF(SUM(ventas), 0) AS porcentaje_resto
FROM ranking;

SELECT TOP (10) seller_id, cant_ordenes,
       DENSE_RANK() OVER (ORDER BY cant_ordenes DESC) AS posicion
FROM dbo.vw_info_vendedores
ORDER BY cant_ordenes DESC, seller_id;

WITH vendedores AS (
    SELECT seller_id, total_ventas, cant_ordenes,
           ROW_NUMBER() OVER (ORDER BY total_ventas DESC, seller_id) AS posicion
    FROM dbo.vw_info_vendedores
)
SELECT SUM(CASE WHEN posicion <= 10 THEN total_ventas ELSE 0 END) * 100.0
           / NULLIF(SUM(total_ventas), 0) AS porcentaje_ventas_top_10,
       SUM(CASE WHEN posicion <= 10 THEN cant_ordenes ELSE 0 END)
           AS ordenes_top_10
FROM vendedores;

WITH entregas_vendedor AS (
    SELECT DISTINCT oi.seller_id, o.order_id,
           DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
               AS dias_entrega
    FROM dbo.order_item AS oi
    JOIN dbo.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date >= o.order_purchase_timestamp
), promedios AS (
    SELECT seller_id, AVG(CAST(dias_entrega AS DECIMAL(10,2))) AS dias_promedio
    FROM entregas_vendedor
    GROUP BY seller_id
)
SELECT TOP (10) seller_id, dias_promedio,
       ROW_NUMBER() OVER (ORDER BY dias_promedio, seller_id) AS posicion
FROM promedios
ORDER BY dias_promedio, seller_id;

SELECT c.customer_state AS estado,
       AVG(CAST(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
           AS DECIMAL(10,2))) AS dias_promedio
FROM dbo.orders AS o
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date >= o.order_purchase_timestamp
GROUP BY c.customer_state
ORDER BY dias_promedio;

SELECT t.product_category_name_english AS categoria,
       AVG(CAST(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
           AS DECIMAL(10,2))) AS dias_promedio
FROM dbo.order_item AS oi
JOIN dbo.orders AS o ON o.order_id = oi.order_id
JOIN dbo.products AS p ON p.product_id = oi.product_id
LEFT JOIN dbo.product_category_name_translation AS t
    ON t.product_category_name = p.product_category_name
WHERE o.order_delivered_customer_date >= o.order_purchase_timestamp
GROUP BY t.product_category_name_english
ORDER BY dias_promedio;

SELECT c.customer_state AS estado, t.product_category_name_english AS categoria,
       AVG(CAST(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
           AS DECIMAL(10,2))) AS dias_promedio
FROM dbo.order_item AS oi
JOIN dbo.orders AS o ON o.order_id = oi.order_id
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
JOIN dbo.products AS p ON p.product_id = oi.product_id
LEFT JOIN dbo.product_category_name_translation AS t
    ON t.product_category_name = p.product_category_name
WHERE o.order_delivered_customer_date >= o.order_purchase_timestamp
GROUP BY c.customer_state, t.product_category_name_english
ORDER BY estado, categoria;

SELECT COUNT(*) AS entregas,
       SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END)
           AS a_tiempo,
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
           AS fuera_de_tiempo,
       SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END)
           * 100.0 / NULLIF(COUNT(*), 0) AS porcentaje_a_tiempo
FROM dbo.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

SELECT c.customer_state AS estado, c.customer_city AS ciudad,
       COUNT(*) AS entregas,
       SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
           AS retrasos,
       SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
           * 100.0 / NULLIF(COUNT(*), 0) AS porcentaje_retrasos
FROM dbo.orders AS o
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state, c.customer_city
ORDER BY porcentaje_retrasos DESC, entregas DESC;

SELECT c.customer_state AS estado, COUNT(*) AS entregas,
       SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
           * 100.0 / NULLIF(COUNT(*), 0) AS porcentaje_retrasos
FROM dbo.orders AS o
JOIN dbo.customer AS c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY porcentaje_retrasos DESC;

SELECT metodo_pago, SUM(veces_usado) AS veces_usado
FROM dbo.vw_info_pagos
GROUP BY metodo_pago
ORDER BY veces_usado DESC;

WITH pago_por_orden AS (
    SELECT order_id, payment_type,
           SUM(payment_value) AS total_por_tipo
    FROM dbo.order_payments
    GROUP BY order_id, payment_type
)
SELECT payment_type AS metodo_pago,
       AVG(CAST(total_por_tipo AS DECIMAL(18,2))) AS promedio_por_orden_y_tipo
FROM pago_por_orden
GROUP BY payment_type
ORDER BY promedio_por_orden_y_tipo DESC;

WITH pagos_por_orden AS (
    SELECT order_id, COUNT(*) AS pagos
    FROM dbo.order_payments
    GROUP BY order_id
)
SELECT COUNT(*) AS ordenes_con_pago,
       SUM(CASE WHEN pagos > 1 THEN 1 ELSE 0 END) AS ordenes_con_multiples_pagos,
       SUM(CASE WHEN pagos = 1 THEN 1 ELSE 0 END) AS ordenes_con_un_pago,
       SUM(CASE WHEN pagos > 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0)
           AS porcentaje_multiples_pagos
FROM pagos_por_orden;

SELECT o.order_status AS estado_orden,
       COUNT(*) AS resenas,
       AVG(CAST(r.review_score AS DECIMAL(5,2))) AS puntuacion_media
FROM dbo.orders AS o
JOIN dbo.order_reviews AS r ON r.order_id = o.order_id
GROUP BY o.order_status
ORDER BY puntuacion_media;

WITH resena_orden AS (
    SELECT order_id, AVG(CAST(review_score AS DECIMAL(5,2))) AS puntuacion
    FROM dbo.order_reviews
    GROUP BY order_id
), categoria_orden AS (
    SELECT DISTINCT oi.order_id, t.product_category_name_english AS categoria
    FROM dbo.order_item AS oi
    JOIN dbo.products AS p ON p.product_id = oi.product_id
    JOIN dbo.product_category_name_translation AS t
        ON t.product_category_name = p.product_category_name
)
SELECT co.categoria, COUNT(*) AS ordenes_con_resena,
       AVG(ro.puntuacion) AS puntuacion_media,
       AVG(CASE WHEN ro.puntuacion <= 2 THEN 1.0 ELSE 0.0 END) * 100.0
           AS porcentaje_resenas_negativas
FROM categoria_orden AS co
JOIN resena_orden AS ro ON ro.order_id = co.order_id
GROUP BY co.categoria
ORDER BY porcentaje_resenas_negativas DESC;

WITH resena_orden AS (
    SELECT order_id, AVG(CAST(review_score AS DECIMAL(5,2))) AS puntuacion
    FROM dbo.order_reviews GROUP BY order_id
), entregas AS (
    SELECT o.order_id, r.puntuacion,
           DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
               AS dias_entrega
    FROM dbo.orders AS o
    JOIN resena_orden AS r ON r.order_id = o.order_id
    WHERE o.order_delivered_customer_date >= o.order_purchase_timestamp
), rangos AS (
    SELECT order_id, puntuacion, dias_entrega,
           CASE WHEN dias_entrega <= 5 THEN '0-5 dias'
                WHEN dias_entrega <= 10 THEN '6-10 dias'
                WHEN dias_entrega <= 20 THEN '11-20 dias'
                WHEN dias_entrega <= 30 THEN '21-30 dias'
                ELSE 'Mas de 30 dias' END AS rango
    FROM entregas
)
SELECT rango, COUNT(*) AS ordenes,
       AVG(CAST(dias_entrega AS DECIMAL(10,2))) AS dias_promedio,
       AVG(puntuacion) AS puntuacion_media
FROM rangos
GROUP BY rango
ORDER BY MIN(dias_entrega);
