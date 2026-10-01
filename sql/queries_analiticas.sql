-- =====================================================================
-- Queries analíticas: CRM e marketing de associados
--
-- Tabelas:
--   associados      = data/associados_simulados.csv (um registro por associado)
--   associados_rfv  = data/associados_rfv.csv (somente associados ativos, com scores e classe RFV)
--
-- Os dados são simulados.
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
-- Público já engajado e pronto para uma campanha de cartão.
-- O percentual é calculado sobre os ativos com conta corrente de cada segmento.
-- ---------------------------------------------------------------------
SELECT
    segmento,
    COUNT(*) AS ativos_com_conta,
    SUM(CASE WHEN tem_cartao_credito = 0 THEN 1 ELSE 0 END) AS sem_cartao,
    ROUND(100.0 * SUM(CASE WHEN tem_cartao_credito = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_sem_cartao
FROM associados
WHERE status = 'Ativo'
  AND tem_conta_corrente = 1
GROUP BY segmento
ORDER BY sem_cartao DESC;


-- ---------------------------------------------------------------------
-- 3. NPS por segmento
-- Promotores: nota 9 ou 10 | Neutros: 7 ou 8 | Detratores: 0 a 6
-- NPS = % promotores - % detratores
-- ---------------------------------------------------------------------
SELECT
    segmento,
    COUNT(*) AS total_associados,
    ROUND(AVG(nps_score), 2) AS nota_media,
    ROUND(100.0 * SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promotores,
    ROUND(100.0 * SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detratores,
    ROUND(100.0 * (SUM(CASE WHEN nps_score >= 9 THEN 1 ELSE 0 END)
                 - SUM(CASE WHEN nps_score <= 6 THEN 1 ELSE 0 END)) / COUNT(*), 1) AS nps
FROM associados
GROUP BY segmento
ORDER BY nps DESC;


-- ---------------------------------------------------------------------
-- 4. Perfil médio: Ativo x Churned
-- O que diferencia quem saiu de quem continua ativo?
-- ---------------------------------------------------------------------
SELECT
    status,
    COUNT(*) AS associados,
    ROUND(AVG(idade), 2) AS idade_media,
    ROUND(AVG(qtd_produtos), 2) AS produtos_medio,
    ROUND(AVG(nps_score), 2) AS nps_medio,
    ROUND(AVG(transacoes_ultimo_trimestre), 2) AS transacoes_media,
    ROUND(AVG(dias_desde_ultimo_acesso), 2) AS dias_sem_acesso_medio
FROM associados
WHERE status IN ('Ativo', 'Churned')
GROUP BY status
ORDER BY status;


-- ---------------------------------------------------------------------
-- 5. Taxas de abertura e conversão por canal de aquisição
-- Considera apenas quem recebeu pelo menos uma campanha.
-- Taxa de abertura  = total de abertas / total de recebidas
-- Taxa de conversão = total de convertidas / total de abertas
-- ---------------------------------------------------------------------
SELECT
    canal_aquisicao,
    COUNT(*) AS associados,
    SUM(campanhas_recebidas) AS recebidas,
    SUM(campanhas_abertas) AS abertas,
    SUM(campanhas_convertidas) AS convertidas,
    ROUND(100.0 * SUM(campanhas_abertas) / SUM(campanhas_recebidas), 1) AS taxa_abertura_pct,
    ROUND(100.0 * SUM(campanhas_convertidas) / SUM(campanhas_abertas), 1) AS taxa_conversao_pct
FROM associados
WHERE campanhas_recebidas > 0
GROUP BY canal_aquisicao
ORDER BY taxa_conversao_pct DESC;


-- ---------------------------------------------------------------------
-- 6. Distribuição dos segmentos RFV com saldo e investimento médios
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
             WHEN 'Premium' THEN 1
             WHEN 'Potencial' THEN 2
             WHEN 'Atenção' THEN 3
             WHEN 'Em risco' THEN 4
         END;
