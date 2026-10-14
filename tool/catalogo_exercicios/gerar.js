// Gera o JSON do catalogo (app V003) e a migration SQL (backend) a partir de catalogo_fonte.js.
// Uso: node gerar.js <exercises.json da free-exercise-db> <saida_json> <saida_sql>
const fs = require('fs');
const path = require('path');
const fonte = require(path.join(__dirname, 'catalogo_fonte.js'));
const [, , fedbPath, saidaJson, saidaSql] = process.argv;
// Videos de execucao no YouTube (gerados por buscar_videos.js e validados via oEmbed).
const videosPath = path.join(__dirname, 'videos.json');
const videos = fs.existsSync(videosPath) ? JSON.parse(fs.readFileSync(videosPath, 'utf8')) : {};

const fedbIds = new Set(JSON.parse(fs.readFileSync(fedbPath, 'utf8')).map(e => e.id));
const IMG = id => `https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${id}/0.jpg`;

const erros = [];
const ids = new Set();
const lista = fonte.map(([id, nome, grupo, equip, nivel, img, dica, errosComuns, passos]) => {
  if (ids.has(id)) erros.push(`id duplicado: ${id}`);
  ids.add(id);
  if (!fedbIds.has(img)) erros.push(`imagem inexistente na base: ${img} (${id})`);
  if (!Array.isArray(passos) || passos.length < 3) erros.push(`passo a passo curto: ${id}`);
  return {
    id, nome, grupoMuscular: grupo, equipamento: equip, nivel,
    thumbnailUrl: IMG(img),
    videoUrl: videos[id] ? videos[id].url : null,
    instrucoes: dica,
    errosComuns: errosComuns,
    descricao: passos.map((p, i) => `${i + 1}. ${p}`).join('\n'),
  };
});
if (erros.length) { console.error(erros.join('\n')); process.exit(1); }

fs.writeFileSync(saidaJson, JSON.stringify(lista, null, 1) + '\n', 'utf8');

const q = s => (s == null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
const grupos = [...new Set(lista.map(e => e.grupoMuscular))];
let sql = `-- Migration V2026101404: catalogo de exercicios e grupos musculares do Meu Treino (V003).
--
-- Motivo: a tabela exercicios tinha apenas registros de teste ("teste") e
-- grupo_muscular nao tinha categorias reais. Esta carga cria ${grupos.length} grupos e
-- ${lista.length} exercicios, cada um com descricao passo a passo (coluna descricao),
-- nivel (1 iniciante, 2 intermediario, 3 avancado) e imagem demonstrativa (foto)
-- da free-exercise-db (dominio publico / Unlicense).
-- Gerada a partir do mesmo catalogo usado pelo app (assets/data/exercicios_catalogo.json).
-- Idempotente: nao duplica grupo nem exercicio ja existente com o mesmo nome.

`;
for (const g of grupos) {
  sql += `INSERT INTO grupo_muscular (nome, descricao, dh_created_at)
SELECT ${q(g)}, ${q('Grupo muscular do catalogo Meu Treino')}, NOW()
WHERE NOT EXISTS (SELECT 1 FROM grupo_muscular WHERE LOWER(nome) = LOWER(${q(g)}));\n\n`;
}
for (const e of lista) {
  sql += `INSERT INTO exercicios (nome, descricao, nivel, foto, cod_grup_musc, dh_created_at)
SELECT ${q(e.nome)}, ${q(e.descricao)}, ${e.nivel}, ${q(e.thumbnailUrl)},
       (SELECT MIN(id) FROM grupo_muscular WHERE LOWER(nome) = LOWER(${q(e.grupoMuscular)})), NOW()
WHERE NOT EXISTS (SELECT 1 FROM exercicios WHERE LOWER(nome) = LOWER(${q(e.nome)}));\n\n`;
}
fs.writeFileSync(saidaSql, sql, 'utf8');

const porGrupo = {};
lista.forEach(e => { porGrupo[e.grupoMuscular] = (porGrupo[e.grupoMuscular] || 0) + 1; });
console.log(`OK: ${lista.length} exercicios, ${grupos.length} grupos`);
console.log(porGrupo);
