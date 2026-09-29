-- Quem são os 10 maiores vendedores e como estão a nota e o atraso deles?
-- Um pedido com itens de vários vendedores conta para cada um.

WITH vendedor_pedido AS (
    SELECT DISTINCT vendedor_id, pedido_id
    FROM fato_itens
    WHERE status = 'delivered'
),
receita AS (
    SELECT vendedor_id, SUM(preco) AS receita
    FROM fato_itens
    WHERE status = 'delivered'
    GROUP BY vendedor_id
),
qualidade AS (
    SELECT vp.vendedor_id,
           COUNT(*)                                                  AS pedidos,
           AVG(p.nota_media)                                         AS nota_media,
           100.0 * AVG(CASE WHEN p.entregue_no_prazo = 0 THEN 1.0 ELSE 0 END) AS pct_atraso
    FROM vendedor_pedido vp
    JOIN fato_pedidos p ON p.pedido_id = vp.pedido_id
    GROUP BY vp.vendedor_id
)
SELECT RANK() OVER (ORDER BY r.receita DESC) AS posicao,
       substr(v.vendedor_id, 1, 8)           AS vendedor,
       v.estado,
       ROUND(r.receita, 2)                   AS receita,
       q.pedidos,
       ROUND(q.nota_media, 2)                AS nota_media,
       ROUND(q.pct_atraso, 1)                AS pct_atraso
FROM receita r
JOIN qualidade q    ON q.vendedor_id = r.vendedor_id
JOIN dim_vendedor v ON v.vendedor_id = r.vendedor_id
ORDER BY posicao
LIMIT 10;
