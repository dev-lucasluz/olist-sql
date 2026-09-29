-- Confere se o modelo dimensional bate com as tabelas de origem.
-- Cada linha deve ter esperado = obtido; o executar.py interrompe se alguma divergir.

SELECT 'pedidos' AS verificacao,
       (SELECT COUNT(*) FROM orders)       AS esperado,
       (SELECT COUNT(*) FROM fato_pedidos) AS obtido
UNION ALL
SELECT 'itens',
       (SELECT COUNT(*) FROM order_items),
       (SELECT COUNT(*) FROM fato_itens)
UNION ALL
SELECT 'receita de itens (centavos)',
       (SELECT CAST(ROUND(SUM(price) * 100) AS INTEGER) FROM order_items),
       (SELECT CAST(ROUND(SUM(preco) * 100) AS INTEGER) FROM fato_itens)
UNION ALL
SELECT 'valor pago (centavos)',
       (SELECT CAST(ROUND(SUM(payment_value) * 100) AS INTEGER) FROM order_payments),
       (SELECT CAST(ROUND(SUM(valor_pago) * 100) AS INTEGER) FROM fato_pedidos)
UNION ALL
SELECT 'itens sem produto na dimensao',
       0,
       (SELECT COUNT(*) FROM fato_itens f
        LEFT JOIN dim_produto p ON p.produto_id = f.produto_id
        WHERE p.produto_id IS NULL)
UNION ALL
SELECT 'pedidos fora da dim_data',
       0,
       (SELECT COUNT(*) FROM fato_pedidos f
        LEFT JOIN dim_data d ON d.data_id = f.data_compra_id
        WHERE d.data_id IS NULL);
