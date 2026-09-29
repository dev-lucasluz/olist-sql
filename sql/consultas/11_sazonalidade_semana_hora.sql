-- Em que dia da semana e período do dia os clientes mais compram?
-- Percentual sobre o total de pedidos.

WITH pedidos AS (
    SELECT d.dia_semana_num,
           d.dia_semana,
           CASE WHEN p.hora_compra < 6  THEN 'madrugada'
                WHEN p.hora_compra < 12 THEN 'manha'
                WHEN p.hora_compra < 18 THEN 'tarde'
                ELSE 'noite' END AS periodo
    FROM fato_pedidos p
    JOIN dim_data d ON d.data_id = p.data_compra_id
    WHERE p.status NOT IN ('canceled', 'unavailable')
)
SELECT dia_semana,
       COUNT(*)                                                    AS pedidos,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)          AS pct_total,
       ROUND(100.0 * SUM(periodo = 'madrugada') / COUNT(*), 1)     AS pct_madrugada,
       ROUND(100.0 * SUM(periodo = 'manha') / COUNT(*), 1)         AS pct_manha,
       ROUND(100.0 * SUM(periodo = 'tarde') / COUNT(*), 1)         AS pct_tarde,
       ROUND(100.0 * SUM(periodo = 'noite') / COUNT(*), 1)         AS pct_noite
FROM pedidos
GROUP BY dia_semana_num, dia_semana
ORDER BY dia_semana_num;
