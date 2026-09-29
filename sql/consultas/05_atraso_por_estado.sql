-- Em quais estados as entregas mais atrasam?
-- Atraso = entrega depois da data estimada informada ao cliente.

SELECT c.estado,
       COUNT(*)                                       AS pedidos,
       ROUND(100.0 * AVG(1 - p.entregue_no_prazo), 1) AS pct_atrasados,
       ROUND(AVG(p.dias_entrega), 1)                  AS dias_medios_entrega,
       ROUND(AVG(CASE WHEN p.entregue_no_prazo = 0 THEN p.dias_atraso END), 1) AS dias_medios_atraso
FROM fato_pedidos p
JOIN dim_cliente c ON c.cliente_id = p.cliente_id
WHERE p.status = 'delivered' AND p.entregue_no_prazo IS NOT NULL
GROUP BY c.estado
HAVING COUNT(*) >= 300
ORDER BY pct_atrasados DESC
LIMIT 10;
