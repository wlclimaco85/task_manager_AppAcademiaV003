"""Gera lib/data/constants/app_version.dart a partir do pubspec.yaml e do Git.

Rode antes do build (web, Android ou iOS):
    python tool/gerar_versao.py

A mesma constante serve o app e o web, porque e compilada junto com o codigo.
"""
import datetime
import pathlib
import re
import subprocess

RAIZ = pathlib.Path(__file__).resolve().parent.parent
PUBSPEC = RAIZ / "pubspec.yaml"
SAIDA = RAIZ / "lib" / "data" / "constants" / "app_version.dart"


def ler_versao() -> tuple[str, str]:
    texto = PUBSPEC.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*([0-9.]+)\+(\d+)\s*$", texto, re.MULTILINE)
    if not m:
        raise SystemExit("version: <nome>+<build> nao encontrado no pubspec.yaml")
    return m.group(1), m.group(2)


def ler_commit() -> str:
    try:
        return subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=RAIZ, capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "sem-git"


def main() -> None:
    nome, build = ler_versao()
    commit = ler_commit()
    gerado_em = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    SAIDA.write_text(
        "// GERADO por tool/gerar_versao.py. Nao editar a mao.\n"
        f"const String kAppVersaoNome = '{nome}';\n"
        f"const String kAppVersaoBuild = '{build}';\n"
        f"const String kAppVersaoCommit = '{commit}';\n"
        f"const String kAppVersaoGeradaEm = '{gerado_em}';\n"
        "\n"
        "/// Texto curto mostrado no rodape: versao, build e commit.\n"
        "const String kAppVersaoTexto =\n"
        "    'Versao $kAppVersaoNome ($kAppVersaoBuild) - $kAppVersaoCommit';\n",
        encoding="utf-8",
    )
    print(f"app_version.dart gerado: {nome}+{build} ({commit})")


if __name__ == "__main__":
    main()
