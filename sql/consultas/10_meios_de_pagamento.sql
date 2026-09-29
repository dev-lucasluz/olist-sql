-- Como os clientes pagam?

WITH pagamento AS (
    SELECT op.payment_type,
           COUNT(DISTINCT op.order_id)  AS pedidos,
           SUM(op.payment_value)        AS valor,
           AVG(op.payment_installments) AS parcelas_medias
    FROM order_payments op
    JOIN fato_pedidos p ON p.pedido_id = op.order_id
    WHERE p.status = 'delivered'
    GROUP BY op.payment_type
)
SELECT payment_type                                            AS meio_pagamento,
       pedidos,
       ROUND(valor, 2)                                         AS valor,
       ROUND(100.0 * valor / SUM(valor) OVER (), 1)            AS pct_valor,
       ROUND(parcelas_medias, 1)                               AS parcelas_medias
FROM pagamento
ORDER BY valor DESC;
