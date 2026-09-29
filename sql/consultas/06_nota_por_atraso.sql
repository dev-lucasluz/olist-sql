-- O atraso na entrega derruba a nota da avaliação?

WITH faixa AS (
    SELECT CASE
               WHEN dias_atraso = 0 THEN 1
               WHEN dias_atraso <= 3 THEN 2
               WHEN dias_atraso <= 7 THEN 3
               ELSE 4
           END AS ordem,
           CASE
               WHEN dias_atraso = 0 THEN 'no prazo'
               WHEN dias_atraso <= 3 THEN '1 a 3 dias de atraso'
               WHEN dias_atraso <= 7 THEN '4 a 7 dias de atraso'
               ELSE 'mais de 7 dias de atraso'
           END AS faixa_atraso,
           nota_media
    FROM fato_pedidos
    WHERE status = 'delivered' AND dias_atraso IS NOT NULL AND nota_media IS NOT NULL
)
SELECT faixa_atraso,
       COUNT(*)                                                   AS pedidos,
       ROUND(AVG(nota_media), 2)                                  AS nota_media,
       ROUND(100.0 * AVG(CASE WHEN nota_media <= 2 THEN 1.0 ELSE 0 END), 1) AS pct_notas_1_e_2
FROM faixa
GROUP BY ordem, faixa_atraso
ORDER BY ordem;
