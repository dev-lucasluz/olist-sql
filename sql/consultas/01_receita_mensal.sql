-- Como a receita evolui mês a mês?
-- Receita = soma do preço dos itens de pedidos entregues (frete fora).
-- Traz variação sobre o mês anterior e média móvel de 3 meses.
-- Período analisado: jan/2017 a ago/2018. Os meses de 2016 e de set/out 2018 têm
-- pouquíssimos pedidos (início e fim do dataset) e distorceriam as variações.

WITH mensal AS (
    SELECT d.ano_mes,
           SUM(f.preco)                AS receita,
           COUNT(DISTINCT f.pedido_id) AS pedidos
    FROM fato_itens f
    JOIN dim_data d ON d.data_id = f.data_compra_id
    WHERE f.status = 'delivered'
      AND d.ano_mes BETWEEN '2017-01' AND '2018-08'
    GROUP BY d.ano_mes
)
SELECT ano_mes,
       ROUND(receita, 2)                                  AS receita,
       pedidos,
       ROUND(receita / pedidos, 2)                        AS ticket_medio,
       ROUND(100.0 * (receita - LAG(receita) OVER (ORDER BY ano_mes))
             / LAG(receita) OVER (ORDER BY ano_mes), 1)   AS var_pct_mes_anterior,
       ROUND(AVG(receita) OVER (ORDER BY ano_mes
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movel_3m
FROM mensal
ORDER BY ano_mes;
