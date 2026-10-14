# Catálogo de exercícios (fonte única)

`catalogo_fonte.js` é a lista oficial de exercícios do Meu Treino: nome, grupo, equipamento,
nível, imagem (id na free-exercise-db, domínio público) e a **descrição passo a passo**.

`gerar.js` produz, a partir dela:

- `assets/data/exercicios_catalogo.json` — catálogo carregado pelo app (`FitnessOfflineRepository`);
- a migration SQL do backend (`AppAcademia/src/main/resources/db/migration`).

```bash
curl -L -o exercises.json https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json
node tool/catalogo_exercicios/gerar.js exercises.json assets/data/exercicios_catalogo.json ../AppAcademia/src/main/resources/db/migration/V<nova_versao>__Seed_catalogo_exercicios.sql
```

Ao incluir exercícios novos, gere uma **nova** versão de migration (as já aplicadas não rodam de novo);
o SQL é idempotente por nome. Não altere os ids existentes: as fichas de treino referenciam esses ids.
