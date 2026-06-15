# Customização - Contas a Pagar

## Diálogos Customizados

### 1. Dialog de Baixa (`_showBaixaDialog`)
**Localização:** `conta_pagar_grid_screen.dart:137`

**Estrutura:**
```dart
Future<void> _showBaixaDialog(BuildContext context, ContaPagar conta)
```

**Campos:**
- Data de Pagamento (DatePicker)
- Valor Pago (TextField numérico)
- Conta Bancária (Dropdown)
- Forma de Pagamento (Dropdown)
- Observação (TextField multi-linha)

**Validações:**
- Data obrigatória
- Valor obrigatório e > 0
- Conta bancária obrigatória
- Forma de pagamento obrigatória

**Ações:**
- Cancelar (fecha sem salvar)
- Confirmar (salva e atualiza grid)

---

### 2. Dialog de Parcelamento (`_showParcelamentoDialog`)
**Localização:** `conta_pagar_grid_screen.dart:??`

**Estrutura:**
```dart
Future<void> _showParcelamentoDialog(BuildContext context, ContaPagar conta)
```

**Campos:**
- Número de Parcelas (TextField numérico, 2-60)
- Data da 1ª Parcela (DatePicker)
- Preview das parcelas (lista read-only)

**Validações:**
- Número de parcelas: 2 a 60
- Data obrigatória
- Calcula automaticamente valor de cada parcela

**Comportamento:**
- Divide o valor original em N parcelas iguais
- Gera datas mensais automáticas
- Mostra preview antes de confirmar
- Cria múltiplas contas no banco

**Ações:**
- Cancelar (fecha sem criar parcelas)
- Gerar Parcelas (cria N contas e fecha dialog)

---

### 3. Dialog de Anexo PDF (`_showAnexoDialog`)
**Localização:** `conta_pagar_grid_screen.dart:95`

**Estrutura:**
```dart
Future<void> _showAnexoDialog(BuildContext context, ContaPagar conta)
```

**Comportamento:**
- Abre FilePicker com filtro .pdf
- Valida extensão
- Copia arquivo para pasta do app
- Atualiza campo `pdfPath` da conta
- Mostra preview do nome do arquivo

**Validações:**
- Apenas arquivos PDF
- Arquivo deve existir no sistema

**Ações:**
- Cancelar (fecha sem anexar)
- Selecionar (abre file picker)

---

### 4. Dialog de Visualização de Anexo (`_showViewAnexoDialog`)
**Localização:** `conta_pagar_grid_screen.dart:130`

**Estrutura:**
```dart
void _showViewAnexoDialog(BuildContext context, String pdfPath)
```

**Comportamento:**
- Exibe informações do PDF anexado
- Mostra nome do arquivo
- Botão para abrir arquivo no visualizador padrão

**Ações:**
- Fechar
- Abrir PDF (abre com app externo)

---

### 5. Dialog de Erro (`_showError`)
**Localização:** `conta_pagar_grid_screen.dart:204`

**Estrutura:**
```dart
void _showError(BuildContext context, String msg)
```

**Uso:**
- Exibe mensagens de erro
- Botão OK para fechar

---

## Ações Customizadas na Grid

### Action: Baixar
- **Ícone:** `Icons.payment`
- **Visível quando:** `status == StatusConta.ABER` (Aberta)
- **Função:** Abre `_showBaixaDialog`

### Action: Parcelar
- **Ícone:** `Icons.splitscreen`
- **Visível quando:** `status == StatusConta.ABER` (Aberta)
- **Função:** Abre `_showParcelamentoDialog`

### Action: Anexar PDF
- **Ícone:** `Icons.attach_file`
- **Visível sempre**
- **Função:** Abre `_showAnexoDialog`

### Action: Ver Anexo
- **Ícone:** `Icons.picture_as_pdf`
- **Visível quando:** `pdfPath != null && pdfPath.isNotEmpty`
- **Função:** Abre `_showViewAnexoDialog`

---

## Card Customizado

**Localização:** `ContaPagarCard` widget inline

**Informações exibidas:**
- Fornecedor (título principal)
- Descrição
- Valor (formatado em R$)
- Data de Vencimento
- Status (chip colorido)
- Parcela (se for parcelada)
- Anexo PDF (ícone se existir)
- Dados de baixa (quando paga):
  - Data de Pagamento
  - Valor Pago
  - Conta Bancária
  - Forma de Pagamento

**Cores de Status:**
- `ABER` (Aberta): Laranja
- `PAGA` (Paga): Verde
- `CANC` (Cancelada): Vermelho

---

## Dependências do Sistema

### Packages:
- `file_picker` - Seleção de arquivos PDF
- `open_file` - Abertura de PDFs no visualizador padrão

### Models Relacionados:
- `ContaPagar`
- `ContaBancaria`
- `FormaPagamento`
- `StatusConta` (enum)

### Services:
- `ContaPagarService` - CRUD e lógica de negócio
- `ContaBancariaService` - Listagem de contas
- `FormaPagamentoService` - Listagem de formas
