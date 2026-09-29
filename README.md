# olist-sql

Modelagem dimensional e análises em SQL sobre o dataset público de e-commerce da Olist. Parte de um banco SQLite gerado pelo projeto [olist-etl-java](https://github.com/dev-lucasluz/olist-etl-java), monta um esquema estrela e responde 13 perguntas de negócio usando CTEs e funções de janela.

## Modelo

Duas tabelas fato e quatro dimensões, criadas em `sql/01_modelo_dimensional.sql`:

```
                 dim_data
                    |
dim_cliente --- fato_pedidos            (1 linha por pedido)

dim_cliente --- fato_itens --- dim_produto     (1 linha por item vendido)
                   |
             dim_vendedor        (e dim_data)
```

- **fato_pedidos:** valor dos itens, frete, valor pago, parcelas, nota média, dias de entrega e dias de atraso.
- **fato_itens:** preço e frete de cada item, ligado a cliente, vendedor, produto e data.
- **dim_cliente:** separa `cliente_id` (cadastro em cada pedido) de `cliente_unico_id` (a pessoa). Análises de recompra usam o segundo.
- **dim_produto:** categoria em inglês, com o nome original quando falta tradução e `sem_categoria` quando o produto não tem categoria.
- **dim_data:** calendário de 2016 a 2018 com ano, mês, trimestre e dia da semana.

Os itens, pagamentos e avaliações são agregados por pedido antes de entrar em `fato_pedidos`, para que o join não multiplique linhas. O arquivo `sql/02_validacao.sql` confere se contagens e totais financeiros do modelo batem com as tabelas de origem (receita e valor pago conferem ao centavo).

## Perguntas respondidas

Cada consulta está em `sql/consultas/` e o resultado em `resultados/`.

| # | Pergunta | Técnicas |
|---|----------|----------|
| 01 | Como a receita evolui mês a mês? | `LAG`, média móvel com `ROWS BETWEEN` |
| 02 | Quais categorias concentram a receita? | soma acumulada com `SUM OVER` |
| 03 | Qual o ticket médio por estado? | `RANK`, `HAVING` |
| 04 | Quem são os maiores vendedores e como estão nota e atraso? | CTEs encadeadas, `RANK` |
| 05 | Em quais estados as entregas mais atrasam? | agregação condicional |
| 06 | O atraso derruba a nota da avaliação? | `CASE` em faixas |
| 07 | Quantos clientes compram mais de uma vez? | percentual com `SUM OVER ()` |
| 08 | Quanto tempo leva até a próxima compra? | `LAG` com `PARTITION BY` |
| 09 | Como segmentar clientes por recência e valor? | `NTILE`, segmentação RFM |
| 10 | Como os clientes pagam? | agregação, parcelas médias |
| 11 | Quando as pessoas compram (dia e período)? | agregação por período |
| 12 | Quais produtos formam a curva ABC? | Pareto com soma acumulada |
| 13 | Quantos clientes voltam após 1, 2 e 3 meses? | análise de coorte |

## Principais achados

- **Crescimento:** a receita mensal de pedidos entregues foi de cerca de R$ 112 mil em janeiro de 2017 para cerca de R$ 970 mil em maio de 2018. O pico foi em novembro de 2017 (R$ 988 mil), mês da Black Friday.
- **Concentração:** cinco categorias (`health_beauty`, `watches_gifts`, `bed_bath_table`, `sports_leisure` e `computers_accessories`) somam quase 40% da receita.
- **Curva ABC:** 26% dos produtos geram 80% da receita.
- **Atraso e satisfação:** pedidos no prazo têm nota média 4,29. Com mais de 7 dias de atraso, a nota cai para 1,70 e 79% das avaliações são 1 ou 2. É a relação mais forte entre as variáveis analisadas.
- **Geografia:** Alagoas (21%) e Maranhão (17%) têm as maiores taxas de entregas atrasadas. São Paulo tem o menor ticket médio (R$ 125) e o menor frete médio (R$ 17); os estados de maior ticket e frete estão no Norte, Nordeste e Centro-Oeste.
- **Recompra:** 97% dos clientes fizeram um único pedido. Entre quem recompra, quase 29% volta no mesmo dia (provavelmente pedidos divididos) e a média é de 79 dias.
- **Retenção:** de cada 100 clientes novos, menos de 1 volta no mês seguinte (entre 0,2 e 0,7 nas coortes). A retenção é baixa em todas as coortes.
- **Pagamento:** o cartão de crédito responde por 78,5% do valor, com 3,5 parcelas em média; o boleto vem em segundo, com 18%.
- **Perfil de compra:** o volume é maior de segunda a quinta. No domingo, 43% das compras acontecem à noite.

Essas leituras descrevem o dataset, que cobre 2016 a 2018 e é uma amostra da operação. Não valem como resultado geral da Olist.

## Como executar

Requisitos: Python 3.10 ou superior (usa só a biblioteca padrão) e o banco `olist.db` gerado pelo projeto olist-etl-java.

```bash
python executar.py ../olist-etl-java/olist.db
```

O script copia o banco para `olist_dw.db` (o original não é alterado), cria o modelo dimensional, roda a validação e executa as 13 consultas, gravando um arquivo Markdown por consulta em `resultados/`.

Para rodar uma consulta em um cliente SQL, como o DBeaver ou o SQLite Browser, abra `olist_dw.db` e cole o conteúdo do arquivo `.sql`.

## Estrutura

```
sql/
    01_modelo_dimensional.sql
    02_validacao.sql
    consultas/          13 consultas de negócio
resultados/             saída de cada consulta em Markdown
executar.py             monta o modelo, valida e executa as consultas
```

## Limitações

- O SQLite não tem função de mediana, então as análises usam médias. Nos tempos de entrega e de recompra a média é afetada por valores extremos.
- A segmentação RFM é simplificada: como 97% dos clientes compraram uma vez, a frequência entrou como recompra sim ou não, em vez de quartis.
- Setembro e outubro de 2018, além de 2016, têm pouquíssimos pedidos e ficam fora das análises de tendência.

## Dados

Dataset publicado pela Olist no Kaggle, sob licença CC BY-NC-SA 4.0. Os dados são anonimizados e não estão neste repositório.
