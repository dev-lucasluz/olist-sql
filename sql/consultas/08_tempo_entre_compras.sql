-- De quanto em quanto tempo quem recompra volta a comprar?

WITH pedidos AS (
    SELECT c.cliente_unico_id,
           p.pedido_id,
           d.data,
           LAG(d.data) OVER (PARTITION BY c.cliente_unico_id
                             ORDER BY d.data, p.pedido_id) AS data_anterior
    FROM fato_pedidos p
    JOIN dim_cliente c ON c.cliente_id = p.cliente_id
    JOIN dim_data d    ON d.data_id = p.data_compra_id
    WHERE p.status NOT IN ('canceled', 'unavailable')
),
intervalos AS (
    SELECT julianday(data) - julianday(data_anterior) AS dias
    FROM pedidos
    WHERE data_anterior IS NOT NULL
)
SELECT COUNT(*)                                           AS recompras,
       ROUND(AVG(dias), 1)                                AS media_dias,
       ROUND(100.0 * AVG(CASE WHEN dias = 0 THEN 1.0 ELSE 0 END), 1)  AS pct_no_mesmo_dia,
       ROUND(100.0 * AVG(CASE WHEN dias <= 30 THEN 1.0 ELSE 0 END), 1) AS pct_em_ate_30_dias,
       ROUND(100.0 * AVG(CASE WHEN dias > 90 THEN 1.0 ELSE 0 END), 1)  AS pct_apos_90_dias
FROM intervalos;
