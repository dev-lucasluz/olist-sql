"""Monta o modelo dimensional sobre o banco do olist-etl-java e roda as consultas.

Uso:
    python executar.py [caminho/do/olist.db]

Sem argumento, usa ../olist-etl-java/olist.db. O original não é alterado: o
script trabalha em uma cópia chamada olist_dw.db.
"""
import shutil
import sqlite3
import sys
from pathlib import Path

RAIZ = Path(__file__).parent
BANCO_ORIGEM = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ.parent / "olist-etl-java" / "olist.db"
BANCO_DW = RAIZ / "olist_dw.db"
PASTA_RESULTADOS = RAIZ / "resultados"
LIMITE_LINHAS = 30


def tabela_markdown(colunas, linhas):
    cabecalho = "| " + " | ".join(colunas) + " |"
    separador = "| " + " | ".join("---" for _ in colunas) + " |"
    corpo = ["| " + " | ".join("" if v is None else str(v) for v in linha) + " |"
             for linha in linhas]
    return "\n".join([cabecalho, separador, *corpo])


def executar_consulta(conexao, arquivo):
    sql = arquivo.read_text(encoding="utf-8")
    cursor = conexao.execute(sql)
    colunas = [c[0] for c in cursor.description]
    linhas = cursor.fetchall()

    comentarios = [l[2:].strip() for l in sql.splitlines() if l.startswith("--")]
    texto = f"# {arquivo.stem}\n\n" + "\n".join(comentarios) + "\n\n"
    texto += tabela_markdown(colunas, linhas[:LIMITE_LINHAS]) + "\n"
    if len(linhas) > LIMITE_LINHAS:
        texto += f"\n(mostrando {LIMITE_LINHAS} de {len(linhas)} linhas)\n"
    (PASTA_RESULTADOS / f"{arquivo.stem}.md").write_text(texto, encoding="utf-8")
    return colunas, linhas


def main():
    if not BANCO_ORIGEM.exists():
        sys.exit(f"Banco nao encontrado: {BANCO_ORIGEM}\n"
                 "Rode antes o olist-etl-java ou informe o caminho do olist.db.")

    shutil.copyfile(BANCO_ORIGEM, BANCO_DW)
    PASTA_RESULTADOS.mkdir(exist_ok=True)
    conexao = sqlite3.connect(BANCO_DW)

    print("Criando modelo dimensional...")
    conexao.executescript((RAIZ / "sql" / "01_modelo_dimensional.sql").read_text(encoding="utf-8"))

    print("\nValidacao:")
    falhou = False
    for nome, esperado, obtido in conexao.execute(
            (RAIZ / "sql" / "02_validacao.sql").read_text(encoding="utf-8")):
        situacao = "ok" if esperado == obtido else "DIVERGENTE"
        falhou = falhou or situacao != "ok"
        print(f"  {nome:<32} esperado={esperado} obtido={obtido} {situacao}")
    if falhou:
        sys.exit("Validacao falhou; consultas nao executadas.")

    print("\nConsultas:")
    for arquivo in sorted((RAIZ / "sql" / "consultas").glob("*.sql")):
        colunas, linhas = executar_consulta(conexao, arquivo)
        print(f"  {arquivo.stem:<32} {len(linhas)} linhas")

    conexao.close()
    print(f"\nResultados em {PASTA_RESULTADOS}")


if __name__ == "__main__":
    main()
