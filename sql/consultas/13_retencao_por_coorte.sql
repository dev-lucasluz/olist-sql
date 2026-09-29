-- Retenção por coorte: dos clientes que fizeram a primeira compra em um mês,
-- quantos voltaram a comprar 1, 2 e 3 meses depois?
-- Só entram coortes com pelo menos 500 clientes novos. O último mês completo do
-- dataset é ago/2018; meses de retenção além dele aparecem vazios (ainda sem dados),
-- e não como 0%.

WITH limite AS (
    SELECT 2018 * 12 + 8 AS idx_ultimo_mes
),
pedidos AS (
    SELECT c.cliente_unico_id AS cliente,
           d.ano * 12 + d.mes AS idx_mes
    FROM fato_pedidos p
    JOIN dim_cliente c ON c.cliente_id = p.cliente_id
    JOIN dim_data d    ON d.data_id = p.data_compra_id
    WHERE p.status NOT IN ('canceled', 'unavailable')
),
primeira AS (
    SELECT cliente, MIN(idx_mes) AS idx0
    FROM pedidos
    GROUP BY cliente
)
SELECT printf('%04d-%02d', (pr.idx0 - 1) / 12, (pr.idx0 - 1) % 12 + 1) AS coorte,
       COUNT(DISTINCT pr.cliente) AS clientes,
       CASE WHEN pr.idx0 + 1 > l.idx_ultimo_mes THEN NULL
            ELSE ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.idx_mes = pr.idx0 + 1 THEN p.cliente END)
                 / COUNT(DISTINCT pr.cliente), 2) END AS pct_mes_1,
       CASE WHEN pr.idx0 + 2 > l.idx_ultimo_mes THEN NULL
            ELSE ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.idx_mes = pr.idx0 + 2 THEN p.cliente END)
                 / COUNT(DISTINCT pr.cliente), 2) END AS pct_mes_2,
       CASE WHEN pr.idx0 + 3 > l.idx_ultimo_mes THEN NULL
            ELSE ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.idx_mes = pr.idx0 + 3 THEN p.cliente END)
                 / COUNT(DISTINCT pr.cliente), 2) END AS pct_mes_3
FROM primeira pr
CROSS JOIN limite l
JOIN pedidos p ON p.cliente = pr.cliente
WHERE pr.idx0 <= l.idx_ultimo_mes
GROUP BY pr.idx0
HAVING COUNT(DISTINCT pr.cliente) >= 500
ORDER BY pr.idx0;
