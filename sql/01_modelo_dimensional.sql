-- Modelo dimensional (esquema estrela) construído sobre o banco gerado pelo olist-etl-java.
--
-- Fatos:
--   fato_pedidos  uma linha por pedido  (entrega, pagamento, avaliação)
--   fato_itens    uma linha por item do pedido (receita por produto, vendedor, categoria)
-- Dimensões:
--   dim_data, dim_cliente, dim_vendedor, dim_produto

DROP TABLE IF EXISTS fato_itens;
DROP TABLE IF EXISTS fato_pedidos;
DROP TABLE IF EXISTS dim_produto;
DROP TABLE IF EXISTS dim_vendedor;
DROP TABLE IF EXISTS dim_cliente;
DROP TABLE IF EXISTS dim_data;

-- dim_data: um dia por linha, de 2016 a 2018 (período coberto pelo dataset).
CREATE TABLE dim_data AS
WITH RECURSIVE dias(dt) AS (
    SELECT DATE('2016-01-01')
    UNION ALL
    SELECT DATE(dt, '+1 day') FROM dias WHERE dt < '2018-12-31'
)
SELECT
    CAST(strftime('%Y%m%d', dt) AS INTEGER)  AS data_id,
    dt                                       AS data,
    CAST(strftime('%Y', dt) AS INTEGER)      AS ano,
    CAST(strftime('%m', dt) AS INTEGER)      AS mes,
    strftime('%Y-%m', dt)                    AS ano_mes,
    (CAST(strftime('%m', dt) AS INTEGER) + 2) / 3 AS trimestre,
    CAST(strftime('%w', dt) AS INTEGER)      AS dia_semana_num,
    CASE strftime('%w', dt)
        WHEN '0' THEN 'domingo'
        WHEN '1' THEN 'segunda'
        WHEN '2' THEN 'terca'
        WHEN '3' THEN 'quarta'
        WHEN '4' THEN 'quinta'
        WHEN '5' THEN 'sexta'
        WHEN '6' THEN 'sabado'
    END                                      AS dia_semana
FROM dias;

CREATE UNIQUE INDEX ix_dim_data ON dim_data (data_id);

-- dim_cliente: customer_id identifica o cadastro em um pedido; o mesmo comprador
-- tem vários customer_id, mas um único customer_unique_id.
CREATE TABLE dim_cliente AS
SELECT
    customer_id        AS cliente_id,
    customer_unique_id AS cliente_unico_id,
    customer_city      AS cidade,
    customer_state     AS estado
FROM customers;

CREATE UNIQUE INDEX ix_dim_cliente ON dim_cliente (cliente_id);
CREATE INDEX ix_dim_cliente_unico ON dim_cliente (cliente_unico_id);

CREATE TABLE dim_vendedor AS
SELECT
    seller_id     AS vendedor_id,
    seller_city   AS cidade,
    seller_state  AS estado
FROM sellers;

CREATE UNIQUE INDEX ix_dim_vendedor ON dim_vendedor (vendedor_id);

-- dim_produto: categoria em inglês quando existe tradução; senão o nome original;
-- produtos sem categoria ficam como 'sem_categoria'.
CREATE TABLE dim_produto AS
SELECT
    p.product_id                                   AS produto_id,
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'sem_categoria')                      AS categoria,
    p.product_weight_g                             AS peso_g,
    p.product_length_cm * p.product_height_cm * p.product_width_cm AS volume_cm3
FROM products p
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name;

CREATE UNIQUE INDEX ix_dim_produto ON dim_produto (produto_id);

-- fato_pedidos: itens, pagamentos e avaliações são agregados antes do join
-- para não multiplicar linhas (um pedido pode ter vários itens e pagamentos).
CREATE TABLE fato_pedidos AS
WITH itens AS (
    SELECT order_id,
           COUNT(*)           AS qtd_itens,
           SUM(price)         AS valor_itens,
           SUM(freight_value) AS valor_frete
    FROM order_items
    GROUP BY order_id
),
pagamentos AS (
    SELECT order_id,
           SUM(payment_value)        AS valor_pago,
           MAX(payment_installments) AS parcelas
    FROM order_payments
    GROUP BY order_id
),
avaliacoes AS (
    SELECT order_id,
           AVG(review_score) AS nota_media
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    o.order_id                                                        AS pedido_id,
    o.customer_id                                                     AS cliente_id,
    o.order_status                                                    AS status,
    CAST(strftime('%Y%m%d', o.order_purchase_timestamp) AS INTEGER)   AS data_compra_id,
    CAST(strftime('%H', o.order_purchase_timestamp) AS INTEGER)       AS hora_compra,
    i.qtd_itens,
    i.valor_itens,
    i.valor_frete,
    p.valor_pago,
    p.parcelas,
    a.nota_media,
    julianday(o.order_delivered_customer_date)
        - julianday(o.order_purchase_timestamp)                       AS dias_entrega,
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN date(o.order_delivered_customer_date) <= date(o.order_estimated_delivery_date) THEN 0
        ELSE julianday(date(o.order_delivered_customer_date))
             - julianday(date(o.order_estimated_delivery_date))
    END                                                               AS dias_atraso,
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN date(o.order_delivered_customer_date) <= date(o.order_estimated_delivery_date) THEN 1
        ELSE 0
    END                                                               AS entregue_no_prazo
FROM orders o
LEFT JOIN itens      i ON i.order_id = o.order_id
LEFT JOIN pagamentos p ON p.order_id = o.order_id
LEFT JOIN avaliacoes a ON a.order_id = o.order_id;

CREATE UNIQUE INDEX ix_fato_pedidos ON fato_pedidos (pedido_id);
CREATE INDEX ix_fato_pedidos_cliente ON fato_pedidos (cliente_id);
CREATE INDEX ix_fato_pedidos_data ON fato_pedidos (data_compra_id);

CREATE TABLE fato_itens AS
SELECT
    i.order_id                                                       AS pedido_id,
    i.order_item_id                                                  AS item_seq,
    o.customer_id                                                    AS cliente_id,
    i.seller_id                                                      AS vendedor_id,
    i.product_id                                                     AS produto_id,
    CAST(strftime('%Y%m%d', o.order_purchase_timestamp) AS INTEGER)  AS data_compra_id,
    o.order_status                                                   AS status,
    i.price                                                          AS preco,
    i.freight_value                                                  AS frete
FROM order_items i
JOIN orders o ON o.order_id = i.order_id;

CREATE INDEX ix_fato_itens_pedido ON fato_itens (pedido_id);
CREATE INDEX ix_fato_itens_vendedor ON fato_itens (vendedor_id);
CREATE INDEX ix_fato_itens_produto ON fato_itens (produto_id);
CREATE INDEX ix_fato_itens_data ON fato_itens (data_compra_id);
