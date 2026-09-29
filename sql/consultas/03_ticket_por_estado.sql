-- Qual o ticket médio por estado do cliente?
-- Considera só estados com pelo menos 500 pedidos entregues, para evitar médias instáveis.

WITH estado AS (
    SELECT c.estado,
           COUNT(*)           AS pedidos,
           AVG(p.valor_itens) AS ticket_medio,
           AVG(p.valor_frete) AS frete_medio
    FROM fato_pedidos p
    JOIN dim_cliente c ON c.cliente_id = p.cliente_id
    WHERE p.status = 'delivered' AND p.valor_itens IS NOT NULL
    GROUP BY c.estado
    HAVING COUNT(*) >= 500
)
SELECT RANK() OVER (ORDER BY ticket_medio DESC) AS posicao,
       estado,
       pedidos,
       ROUND(ticket_medio, 2) AS ticket_medio,
       ROUND(frete_medio, 2)  AS frete_medio
FROM estado
ORDER BY posicao;
