# Dicionário de dados e indicadores

A base é **simulada**, gerada no notebook com semente fixa (42) e data de referência em
**30/09/2025**. Ela é uma fotografia: não tem histórico nem data de saída dos associados.

São dois arquivos:

- `data/associados_simulados.csv`: 5.000 linhas, uma por associado.
- `data/associados_rfv.csv`: 3.524 linhas, uma por associado ativo, com os scores e a classe RFV.

## Tabela `associados`

### Cadastro

| Campo | Tipo | Descrição |
|---|---|---|
| `associado_id` | texto | Chave única, de A00001 a A05000 |
| `nome` | texto | Rótulo fictício ("Associado 1", "Associado 2" e assim por diante) |
| `idade` | inteiro | Idade em anos, de 18 a 74. Em Pessoa Jurídica, é a idade de um responsável fictício pela empresa |
| `genero` | texto | M ou F. Em Pessoa Jurídica, é o gênero do responsável fictício |
| `estado` | texto | UF: RS, SC, PR, SP, MG ou RJ |
| `cidade` | texto | Cidade coerente com o estado (9 cidades) |
| `segmento` | texto | Pessoa Física, Pessoa Jurídica ou Agro |
| `data_associacao` | data | Data de entrada, entre 01/01/2018 e 30/09/2025 |
| `canal_aquisicao` | texto | Por onde o associado entrou: Agência, Digital, Indicação ou Campanha. Não é o canal de envio das campanhas |

### Categorias de produtos

| Campo | Tipo | Descrição |
|---|---|---|
| `tem_conta_corrente` | 0 ou 1 | Tem conta corrente |
| `tem_cartao_credito` | 0 ou 1 | Tem cartão de crédito |
| `tem_seguro` | 0 ou 1 | Tem pelo menos um seguro, de qualquer modalidade (a base não separa os tipos) |
| `tem_consorcio` | 0 ou 1 | Tem consórcio |
| `tem_previdencia` | 0 ou 1 | Tem previdência |
| `tem_credito_rural` | 0 ou 1 | Tem crédito rural (muito mais comum no segmento Agro) |
| `qtd_produtos` | inteiro | Soma dos seis campos `tem_*`, de 0 a 6. Conta categorias de produtos, não contratos. Não inclui investimentos |

### Comportamento e relacionamento

| Campo | Tipo | Descrição |
|---|---|---|
| `transacoes_ultimo_trimestre` | inteiro | Transações no último trimestre. Ajustado depois do status na geração dos dados |
| `saldo_medio_cc` | decimal (R$) | Saldo médio em conta corrente. Zero para quem não tem conta |
| `valor_investido` | decimal (R$) | Valor investido. Zero para quem não investe |
| `nps_score` | inteiro | Nota de recomendação, de 0 a 10. É a nota individual, não o NPS |
| `dias_desde_ultimo_acesso` | inteiro | Dias desde o último acesso, de 0 a 365. Ajustado depois do status na geração dos dados |
| `acessos_app_mes` | inteiro | Acessos ao app no mês. Ajustado depois do status na geração dos dados |
| `status` | texto | Ativo, Inativo ou Churned. Sorteado a partir de um score de risco |

### Campanhas

| Campo | Tipo | Descrição |
|---|---|---|
| `campanhas_recebidas` | inteiro | Quantidade de campanhas que o associado recebeu |
| `campanhas_abertas` | inteiro | Quantidade que ele abriu (menor ou igual às recebidas) |
| `campanhas_convertidas` | inteiro | Quantidade que ele converteu (menor ou igual às abertas) |
| `taxa_abertura_campanha` | decimal | Abertas / recebidas do associado, com 2 casas. Zero para quem não recebeu campanha |
| `taxa_conversao_campanha` | decimal | Convertidas / abertas do associado, com 2 casas. Zero para quem não abriu nenhuma |

As contagens são ocorrências por associado, não campanhas únicas. A base não informa a janela de
tempo, o canal de envio, o custo nem a receita das campanhas.

## Tabela `associados_rfv`

Só os associados ativos entram na segmentação RFV.

| Campo | Tipo | Descrição |
|---|---|---|
| `associado_id` | texto | Chave que liga com a tabela `associados` |
| `score_recencia` | decimal | 1 menos o valor normalizado de `dias_desde_ultimo_acesso` (menos dias, score maior) |
| `score_frequencia` | decimal | Valor normalizado de `transacoes_ultimo_trimestre` |
| `score_valor` | decimal | Valor normalizado de `saldo_medio_cc` |
| `score_rfv` | decimal | Média dos três scores, com pesos iguais |
| `segmento_rfv` | texto | Classe pelo quartil do score: Baixo, Moderado, Alto ou Muito alto |
| `saldo_medio_cc` | decimal (R$) | Cópia do campo da tabela `associados` |
| `valor_investido` | decimal (R$) | Cópia do campo da tabela `associados` |

A normalização usa `MinMaxScaler` (de 0 a 1) sobre os associados ativos. Os scores são gravados com
4 casas decimais e a classe é definida antes do arredondamento. As classes são relativas: mostram
a posição do associado dentro da base ativa e não medem risco de saída.

## Indicadores

| Indicador | Fórmula | Observação |
|---|---|---|
| Total de associados | Contagem de linhas da tabela `associados` | |
| % de ativos | Ativos / total de associados | |
| Taxa de churn | Churned / total de associados | Fotografia em 30/09/2025. Não é taxa mensal nem anual |
| % de promotores | Notas 9 ou 10 / respostas | |
| % de neutros | Notas 7 ou 8 / respostas | |
| % de detratores | Notas de 0 a 6 / respostas | |
| NPS | % de promotores menos % de detratores | De -100 a +100 pontos. Os neutros entram no total de respostas |
| Nota média de recomendação | Média de `nps_score` | Escala de 0 a 10. Não é o NPS |
| Penetração de uma categoria | Associados com a categoria / total de associados | |
| Média de categorias de produtos | Média de `qtd_produtos` | Seis categorias, sem investimentos |
| Público potencial de cartão | Ativos com conta corrente e sem cartão de crédito | Não considera elegibilidade nem interesse |
| Taxa de abertura | Soma de abertas / soma de recebidas | Entre quem recebeu campanha |
| Conversão sobre aberturas | Soma de convertidas / soma de abertas | |
| Conversão sobre recebimentos | Soma de convertidas / soma de recebidas | Funil completo |
| Saldo médio em CC | Média de `saldo_medio_cc` entre quem tem conta corrente | |

As taxas de campanha usam a razão entre as somas, e não a média das taxas individuais.
Nesta base, todos os 5.000 associados têm nota de recomendação.

## Modelo de dados no Power BI

- `associados` (1) para `produtos_posse` (N): a tabela `produtos_posse` é a `associados` com as
  seis colunas `tem_*` transformadas em linhas, uma por categoria de produto.
- `associados` (1) para `associados_rfv` (1): só os ativos têm linha em `associados_rfv`.

## Limites da base

- Os dados são simulados e as relações entre as variáveis foram definidas na geração. Os
  resultados mostram associações, e não causas.
- Não há data de saída. A taxa de churn é uma proporção na fotografia da base, e o tempo de
  associação é contado até a data de referência, inclusive para quem saiu.
- Uso do app, transações e dias sem acesso são ajustados depois do sorteio do status. Nesta base,
  eles são consequência do status e não servem como sinal antecipado de saída.
- O canal de aquisição é a origem do associado, e não o canal de envio das campanhas.
