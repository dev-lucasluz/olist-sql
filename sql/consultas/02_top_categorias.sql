-- Quais categorias concentram a receita?
-- Mostra a participação de cada categoria e o percentual acumulado.

WITH categoria AS (
    SELECT p.categoria,
           SUM(f.preco) AS receita,
           COUNT(*)     AS itens
    FROM fato_itens f
    JOIN dim_produto p ON p.produto_id = f.produto_id
    WHERE f.status = 'delivered'
    GROUP BY p.categoria
)
SELECT categoria,
       ROUND(receita, 2)                                       AS receita,
       itens,
       ROUND(100.0 * receita / SUM(receita) OVER (), 1)        AS pct_receita,
       ROUND(100.0 * SUM(receita) OVER (ORDER BY receita DESC, categoria)
             / SUM(receita) OVER (), 1)                        AS pct_acumulado
FROM categoria
ORDER BY receita DESC
LIMIT 15;
