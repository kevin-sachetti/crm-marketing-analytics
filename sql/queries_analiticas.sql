-- =====================================================================
-- Queries analíticas: CRM e marketing de associados
--
-- Tabelas:
--   associados      = data/associados_simulados.csv (um registro por associado)
--   associados_rfv  = data/associados_rfv.csv (somente associados ativos, com scores e classe RFV)
--
-- Os dados são simulados, com data de referência em 30/09/2025.
-- As divisões usam NULLIF para evitar erro de divisão por zero.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Top 10 cidades por associados ativos
-- Onde está a base ativa? Ajuda a direcionar ações regionais e presenciais.
-- ---------------------------------------------------------------------
SELECT
    cidade,
    estado,
    COUNT(*) AS associados_ativos
FROM associados
WHERE status = 'Ativo'
GROUP BY cidade, estado
ORDER BY associados_ativos DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 2. Cross-sell: associados ativos com conta corrente e sem cartão de crédito, por segmento
-- Público potencial para uma oferta de cartão, sujeito a elegibilidade e interesse.
-- O percentual é calculado sobre os ativos com conta corrente de cada segmento.
-- ---------------------------------------------------------------------
SELECT
    segmento,
    COUNT(*) AS ativos_com_conta,
    SUM(CASE WHEN tem_cartao_credito = 0 THEN 1 ELSE 0 END) AS sem_cartao,
    ROUND(100.0 * SUM(CASE WHEN tem_cartao_credito = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_sem_cartao
FROM associados
WHERE status = 'Ativo'
  AND tem_conta_corrente = 1
GROUP BY segmento
ORDER BY sem_cartao DESC;


-- ---------------------------------------------------------------------
-- 3. NPS por segmento
-- A nota de recomendação vai de 0 a 10.
-- Promotores: nota 9 ou 10 | Neutros: 7 ou 8 | Detratores: 0 a 6
-- NPS = % promotores - % detratores, sobre todas as respostas (de -100 a +100 pontos).
-- A nota média é outro indicador e não deve ser confundida com o NPS.
-- ---------------------------------------------------------------------
SELECT
    segmento,
    COUNT(nps_score) AS respostas,
    ROUND(AVG(nps_score), 2) AS nota_media,
    ROUND(100.0 * SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END) / NULLIF(COUNT(nps_score), 0), 1) AS pct_promotores,
    ROUND(100.0 * SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END) / NULLIF(COUNT(nps_score), 0), 1) AS pct_detratores,
    ROUND(100.0 * (SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END)
                 - SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END)) / NULLIF(COUNT(nps_score), 0), 1) AS nps
FROM associados
GROUP BY segmento
ORDER BY nps DESC;


-- ---------------------------------------------------------------------
-- 4. Perfil médio: Ativo x Churned
-- O que diferencia quem tem status Churned de quem continua ativo?
-- Nesta base simulada, transações e dias sem acesso refletem o próprio status.
-- ---------------------------------------------------------------------
SELECT
    status,
    COUNT(*) AS associados,
    ROUND(AVG(idade), 2) AS idade_media,
    ROUND(AVG(qtd_produtos), 2) AS media_categorias_produtos,
    ROUND(AVG(nps_score), 2) AS nota_media_recomendacao,
    ROUND(AVG(transacoes_ultimo_trimestre), 2) AS transacoes_media,
    ROUND(AVG(dias_desde_ultimo_acesso), 2) AS dias_sem_acesso_medio
FROM associados
WHERE status IN ('Ativo', 'Churned')
GROUP BY status
ORDER BY status;


-- ---------------------------------------------------------------------
-- 5. Taxas de abertura e conversão por canal de aquisição
-- Considera apenas quem recebeu pelo menos uma campanha.
-- Taxa de abertura             = total de abertas / total de recebidas
-- Conversão sobre aberturas    = total de convertidas / total de abertas
-- Conversão sobre recebimentos = total de convertidas / total de recebidas
-- O canal de aquisição é a origem do associado, não o canal de envio da campanha.
-- ---------------------------------------------------------------------
SELECT
    canal_aquisicao,
    COUNT(*) AS associados,
    SUM(campanhas_recebidas) AS recebidas,
    SUM(campanhas_abertas) AS abertas,
    SUM(campanhas_convertidas) AS convertidas,
    ROUND(100.0 * SUM(campanhas_abertas) / NULLIF(SUM(campanhas_recebidas), 0), 1) AS taxa_abertura_pct,
    ROUND(100.0 * SUM(campanhas_convertidas) / NULLIF(SUM(campanhas_abertas), 0), 1) AS conversao_sobre_aberturas_pct,
    ROUND(100.0 * SUM(campanhas_convertidas) / NULLIF(SUM(campanhas_recebidas), 0), 1) AS conversao_sobre_recebimentos_pct
FROM associados
WHERE campanhas_recebidas > 0
GROUP BY canal_aquisicao
ORDER BY conversao_sobre_aberturas_pct DESC;


-- ---------------------------------------------------------------------
-- 6. Distribuição das classes RFV com saldo e investimento médios
-- As classes são os quartis do score RFV entre os ativos (classificação relativa).
-- A tabela associados_rfv já traz saldo_medio_cc e valor_investido, então não é preciso join.
-- ---------------------------------------------------------------------
SELECT
    segmento_rfv,
    COUNT(*) AS associados,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_ativos,
    ROUND(AVG(score_rfv), 3) AS score_rfv_medio,
    ROUND(AVG(saldo_medio_cc), 2) AS saldo_medio_cc,
    ROUND(AVG(valor_investido), 2) AS valor_investido_medio
FROM associados_rfv
GROUP BY segmento_rfv
ORDER BY CASE segmento_rfv
             WHEN 'Muito alto' THEN 1
             WHEN 'Alto' THEN 2
             WHEN 'Moderado' THEN 3
             WHEN 'Baixo' THEN 4
         END;


-- ---------------------------------------------------------------------
-- 7. Indicadores gerais da base
-- A taxa de churn é a proporção de associados com status Churned na base, numa fotografia
-- em 30/09/2025. Não é uma taxa mensal ou anual, porque a base não tem data de saída.
-- O saldo médio considera apenas quem tem conta corrente.
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS total_associados,
    SUM(CASE WHEN status = 'Ativo' THEN 1 ELSE 0 END) AS ativos,
    ROUND(100.0 * SUM(CASE WHEN status = 'Ativo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_ativos,
    SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS taxa_churn_pct,
    ROUND(AVG(qtd_produtos), 2) AS media_categorias_produtos,
    ROUND(AVG(CASE WHEN tem_conta_corrente = 1 THEN saldo_medio_cc END), 2) AS saldo_medio_cc_com_conta
FROM associados;


-- ---------------------------------------------------------------------
-- 8. Composição do NPS
-- Os neutros não entram na fórmula do NPS, mas fazem parte do total de respostas (denominador).
-- ---------------------------------------------------------------------
SELECT
    COUNT(nps_score) AS respostas,
    SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END) AS promotores,
    SUM(CASE WHEN nps_score BETWEEN 7 AND 8 THEN 1 ELSE 0 END) AS neutros,
    SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END) AS detratores,
    ROUND(100.0 * SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END) / NULLIF(COUNT(nps_score), 0), 1) AS pct_promotores,
    ROUND(100.0 * SUM(CASE WHEN nps_score BETWEEN 7 AND 8 THEN 1 ELSE 0 END) / NULLIF(COUNT(nps_score), 0), 1) AS pct_neutros,
    ROUND(100.0 * SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END) / NULLIF(COUNT(nps_score), 0), 1) AS pct_detratores,
    ROUND(100.0 * (SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END)
                 - SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END)) / NULLIF(COUNT(nps_score), 0), 1) AS nps,
    ROUND(AVG(nps_score), 2) AS nota_media_recomendacao
FROM associados;
