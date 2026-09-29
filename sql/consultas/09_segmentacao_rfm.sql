-- Segmentação de clientes por recência, frequência e valor (RFM simplificado).
-- Recência: quão recente foi a última compra em relação aos demais clientes.
-- Como a maioria compra uma única vez, a frequência entra como "recomprou sim/não".

WITH base AS (
    SELECT c.cliente_unico_id,
           MAX(d.data)          AS ultima_compra,
           COUNT(*)             AS pedidos,
           SUM(p.valor_itens)   AS valor
    FROM fato_pedidos p
    JOIN dim_cliente c ON c.cliente_id = p.cliente_id
    JOIN dim_data d    ON d.data_id = p.data_compra_id
    WHERE p.status = 'delivered' AND p.valor_itens IS NOT NULL
    GROUP BY c.cliente_unico_id
),
pontuacao AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY ultima_compra) AS r,   -- 4 = compra mais recente
           NTILE(4) OVER (ORDER BY valor)         AS m    -- 4 = maior valor
    FROM base
),
segmento AS (
    SELECT valor,
           CASE
               WHEN r >= 3 AND pedidos >= 2 THEN '1 recorrente recente'
               WHEN r >= 3 AND m = 4        THEN '2 alto valor recente'
               WHEN r <= 2 AND m = 4        THEN '3 alto valor em risco'
               WHEN r <= 2                  THEN '4 inativo'
               ELSE                              '5 regular'
           END AS segmento
    FROM pontuacao
)
SELECT segmento,
       COUNT(*)                                             AS clientes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_clientes,
       ROUND(SUM(valor), 2)                                 AS receita,
       ROUND(100.0 * SUM(valor) / SUM(SUM(valor)) OVER (), 1) AS pct_receita
FROM segmento
GROUP BY segmento
ORDER BY segmento;
