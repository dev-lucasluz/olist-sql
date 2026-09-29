-- Quantos clientes compram mais de uma vez?
-- Usa customer_unique_id, que identifica a mesma pessoa entre pedidos.

WITH por_cliente AS (
    SELECT c.cliente_unico_id,
           COUNT(*) AS pedidos
    FROM fato_pedidos p
    JOIN dim_cliente c ON c.cliente_id = p.cliente_id
    WHERE p.status NOT IN ('canceled', 'unavailable')
    GROUP BY c.cliente_unico_id
)
SELECT CASE WHEN pedidos = 1 THEN '1 pedido'
            WHEN pedidos = 2 THEN '2 pedidos'
            ELSE '3 ou mais pedidos' END AS faixa,
       COUNT(*)                                            AS clientes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_clientes
FROM por_cliente
GROUP BY faixa
ORDER BY MIN(pedidos);
