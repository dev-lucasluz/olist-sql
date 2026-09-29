-- Curva ABC de produtos por receita (princípio de Pareto).
-- A: produtos que somam até 80% da receita; B: de 80% a 95%; C: o restante.

WITH produto AS (
    SELECT produto_id, SUM(preco) AS receita
    FROM fato_itens
    WHERE status = 'delivered'
    GROUP BY produto_id
),
acumulado AS (
    SELECT produto_id,
           receita,
           1.0 * SUM(receita) OVER (ORDER BY receita DESC, produto_id
                                    ROWS UNBOUNDED PRECEDING)
               / SUM(receita) OVER () AS pct_acumulado
    FROM produto
)
SELECT CASE WHEN pct_acumulado <= 0.80 THEN 'A'
            WHEN pct_acumulado <= 0.95 THEN 'B'
            ELSE 'C' END                                            AS classe,
       COUNT(*)                                                     AS produtos,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_produtos,
       ROUND(SUM(receita), 2)                                       AS receita,
       ROUND(100.0 * SUM(receita) / SUM(SUM(receita)) OVER (), 1)   AS pct_receita
FROM acumulado
GROUP BY classe
ORDER BY classe;
