// Gera o JSON do catalogo de alimentos (app V003) e a migration SQL (backend).
// Uso: node gerar.js <pasta com categories.csv/food.csv/nutrients.csv da taco-api> <saida_json> <saida_sql>
const fs = require('fs');
const path = require('path');
const fonte = require(path.join(__dirname, 'catalogo_fonte.js'));
const [, , tacoDir, saidaJson, saidaSql] = process.argv;

function csv(arquivo) {
  const texto = fs.readFileSync(path.join(tacoDir, arquivo), 'utf8');
  const linhas = [];
  let campo = '', linha = [], aspas = false;
  for (const ch of texto) {
    if (ch === '"') { aspas = !aspas; continue; }
    if (ch === ',' && !aspas) { linha.push(campo); campo = ''; continue; }
    if (ch === '\n' && !aspas) { linha.push(campo.replace(/\r$/, '')); linhas.push(linha); linha = []; campo = ''; continue; }
    campo += ch;
  }
  if (campo || linha.length) { linha.push(campo); linhas.push(linha); }
  const [cab, ...dados] = linhas;
  return dados.filter(l => l.length > 1).map(l => Object.fromEntries(cab.map((c, i) => [c.trim(), (l[i] || '').trim()])));
}

const categorias = Object.fromEntries(csv('categories.csv').map(c => [c.id, c.name]));
const alimentosTaco = Object.fromEntries(csv('food.csv').map(f => [f.id, f]));
const nutrientes = Object.fromEntries(csv('nutrients.csv').map(n => [n.foodId, n]));
// Na TACO, vazio/"Tr" (traco) significa quantidade desprezivel -> 0.
const num = v => { const n = parseFloat(String(v).replace(',', '.')); return Number.isFinite(n) ? n : 0; };
const fmt = n => String(Math.round(n * 10) / 10).replace('.', ',');

const GRUPO_SEM_TACO = { alim_11: 'Pescados e frutos do mar', alim_19: 'Leguminosas e derivados', alim_14: 'Suplementos', alim_15: 'Suplementos' };

const erros = [];
const ids = new Set();
const nomes = new Set();
const lista = fonte.map(([id, tacoId, nome, categoria, tipo, porcao, destaque, uso, valores]) => {
  if (ids.has(id)) erros.push(`id duplicado: ${id}`);
  if (nomes.has(nome.toLowerCase())) erros.push(`nome duplicado: ${nome}`);
  ids.add(id); nomes.add(nome.toLowerCase());
  let v, grupo, origem;
  if (tacoId != null) {
    const t = alimentosTaco[String(tacoId)], n = nutrientes[String(tacoId)];
    if (!t || !n) { erros.push(`TACO ${tacoId} inexistente (${id})`); return null; }
    v = { kcal: num(n.kcal), p: num(n.protein), c: num(n.carbohydrates), g: num(n.lipids), f: num(n.dietaryFiber) };
    grupo = categorias[t.categoryId];
    origem = `TACO 4ª ed. (NEPA/UNICAMP) - "${t.name}"`;
  } else {
    if (!valores) { erros.push(`sem TACO e sem valores: ${id}`); return null; }
    v = valores;
    grupo = GRUPO_SEM_TACO[id] || 'Outros';
    origem = 'referência do app (não consta na TACO; confira o rótulo)';
  }
  const descricao = [
    `Porção caseira: ${porcao}.`,
    `Destaque nutricional: ${destaque}`,
    `Como usar na dieta: ${uso}`,
    `Valores por 100 g: ${fmt(v.kcal)} kcal | ${fmt(v.p)} g proteína | ${fmt(v.c)} g carboidrato | ${fmt(v.g)} g gordura | ${fmt(v.f)} g fibra.`,
    `Fonte: ${origem}.`,
  ].join('\n');
  return {
    id, nome, categoria, tipo, grupo,
    porcaoPadraoGramas: 100,
    calorias: v.kcal, proteinas: v.p, carboidratos: v.c, gorduras: v.g, fibras: v.f,
    unidadeMedida: 'g',
    descricao,
  };
}).filter(Boolean);
if (erros.length) { console.error(erros.join('\n')); process.exit(1); }

fs.writeFileSync(saidaJson, JSON.stringify(lista, null, 1) + '\n', 'utf8');

const q = s => (s == null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
let sql = `-- Migration V2026101405: catalogo de alimentos do Meu Treino (V003) com descricao.
--
-- Motivo: alimentos tinha 12 itens reais sem descricao (todos com tipo FRUTA pelo
-- default da coluna) e registros de teste. Esta carga:
--   1) completa os itens existentes de mesmo nome (descricao, tipo, grupo, macros
--      da TACO) somente quando ainda estao sem descricao;
--   2) inclui os demais alimentos (${lista.length} no catalogo).
-- Valores por 100 g da TACO 4a ed. (NEPA/UNICAMP, 2011); itens fora da TACO usam
-- valores de referencia do app e indicam isso na descricao.
-- Descricao: porcao caseira, destaque nutricional, como usar e valores por 100 g.
-- Gerada a partir do mesmo catalogo do app (assets/data/alimentos_catalogo.json).
-- Idempotente por nome.

`;
for (const a of lista) {
  const campos = `descricao = ${q(a.descricao)}, tipo = ${q(a.tipo)}, grupo = ${q(a.grupo)}, categoria = ${q(a.categoria)},
       calorias = ${a.calorias}, proteinas = ${a.proteinas}, carboidratos = ${a.carboidratos}, gorduras = ${a.gorduras},
       fibras = ${a.fibras}, porcao_padrao_gramas = 100, unidade_medida = 'g', dh_updated_at = NOW()`;
  sql += `UPDATE alimentos SET ${campos}
 WHERE LOWER(nome) = LOWER(${q(a.nome)}) AND COALESCE(descricao, '') = '';

INSERT INTO alimentos (nome, descricao, tipo, grupo, categoria, calorias, proteinas, carboidratos, gorduras, fibras,
                       porcao_padrao_gramas, unidade_medida, dh_created_at)
SELECT ${q(a.nome)}, ${q(a.descricao)}, ${q(a.tipo)}, ${q(a.grupo)}, ${q(a.categoria)}, ${a.calorias}, ${a.proteinas},
       ${a.carboidratos}, ${a.gorduras}, ${a.fibras}, 100, 'g', NOW()
WHERE NOT EXISTS (SELECT 1 FROM alimentos WHERE LOWER(nome) = LOWER(${q(a.nome)}));

`;
}
fs.writeFileSync(saidaSql, sql, 'utf8');

const porCategoria = {};
lista.forEach(a => { porCategoria[a.categoria] = (porCategoria[a.categoria] || 0) + 1; });
console.log(`OK: ${lista.length} alimentos`, porCategoria);
