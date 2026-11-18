/* =====================================================================
   TRABALHO PRÁTICO 03 - OPERADORES E FUNÇÕES SQL (POSTGRESQL)
   Banco de dados: clinica_veterinaria (Clínica Veterinária PetVida)
   Aluno: ____________________   RA: ____________________

   Pré-requisito: as tabelas e os dados do Trabalho 01 já devem existir.
   Execute conectado ao banco clinica_veterinaria (Alt+X no DBeaver).
   ===================================================================== */

/* =====================================================================
   COMPLEMENTOS DE DADOS (garantem retorno em todas as consultas)
   Os comandos abaixo são seguros para rodar mais de uma vez.
   ===================================================================== */

-- Um tutor sem e-mail cadastrado (coluna opcional), usado na questão 2
UPDATE tutor
   SET email = NULL
 WHERE id_tutor = 10;

-- Uma consulta sem observações (coluna opcional)
UPDATE consulta
   SET observacoes = NULL
 WHERE id_consulta = 10;

-- Duas consultas realizadas recentemente (2 e 10 dias atrás), para que as
-- questões com janela de "últimos 30 dias" sempre retornem dados
UPDATE consulta
   SET data_hora = DATE_TRUNC('hour', NOW()) - INTERVAL '2 days'
 WHERE id_consulta = 9;

UPDATE consulta
   SET data_hora = DATE_TRUNC('hour', NOW()) - INTERVAL '10 days'
 WHERE id_consulta = 6;


/* =====================================================================
   BLOCO A - OPERADORES LÓGICOS E DE COMPARAÇÃO
   ===================================================================== */

-- QUESTÃO 1 - Precedência lógica com parênteses [AND, OR, ( )]
-- Regra de negócio: a gerência quer listar os serviços de alto valor
-- (a partir de R$ 150,00) das categorias EXAME ou CIRURGIA, para revisar
-- a tabela de preços dos procedimentos mais caros.
-- O que mudaria sem os parênteses: o AND é avaliado antes do OR, então a
-- condição viraria  categoria = 'EXAME' OR (categoria = 'CIRURGIA' AND
-- valor >= 150). Todos os exames entrariam no resultado, inclusive os
-- baratos (como o Hemograma de R$ 75,00), e o filtro de valor só valeria
-- para as cirurgias.
SELECT descricao,
       categoria,
       valor,
       duracao_min
FROM servico
WHERE (categoria = 'EXAME' OR categoria = 'CIRURGIA')
  AND valor >= 150
ORDER BY valor DESC;


-- QUESTÃO 2 - Negação e verificação de nulos [NOT IN, IS NOT NULL]
-- Regra de negócio: campanha de comunicação por e-mail destinada aos
-- tutores que NÃO moram em Belo Horizonte. Só podem receber a campanha
-- os tutores que possuem e-mail cadastrado (coluna opcional); por isso
-- o tutor com e-mail nulo é descartado.
SELECT nome,
       cidade,
       email
FROM tutor
WHERE cidade NOT IN ('Belo Horizonte')
  AND email IS NOT NULL
ORDER BY cidade, nome;

-- QUESTÃO 2 (complemento) - Tutores sem e-mail [IS NULL]
-- Regra de negócio: tutores que precisam ser contatados por telefone,
-- pois não possuem e-mail.
SELECT nome,
       telefone
FROM tutor
WHERE email IS NULL;


-- QUESTÃO 3 - Intervalos inclusivos e listas [BETWEEN, IN]
-- Regra de negócio: seleção de animais de porte médio (entre 5 kg e
-- 30 kg, limites incluídos) das espécies CACHORRO e GATO, para um
-- programa de controle de peso oferecido pela clínica.
SELECT nome,
       especie,
       peso_kg
FROM animal
WHERE peso_kg BETWEEN 5 AND 30
  AND especie IN ('CACHORRO', 'GATO')
ORDER BY peso_kg DESC;


/* =====================================================================
   BLOCO B - BUSCAS TEXTUAIS COM PADRÕES
   ===================================================================== */

-- QUESTÃO 4a - Busca case-insensitive com curinga [ILIKE, %]
-- Regra de negócio: localizar todas as consultas cujas observações
-- mencionem vacinação, independentemente de maiúsculas ou minúsculas e
-- da posição da palavra no texto (vacina, vacinação, VACINAL etc.).
SELECT id_consulta,
       data_hora,
       observacoes
FROM consulta
WHERE observacoes ILIKE '%vacin%'
ORDER BY data_hora;

-- QUESTÃO 4b - Curinga de caractere único [LIKE, _]
-- Regra de negócio: localizar veterinários com registro CRMV-MG que
-- começa com 13 e tem exatamente 5 dígitos (os três últimos podem ser
-- quaisquer: cada "_" representa exatamente um caractere).
SELECT nome,
       crmv,
       especialidade
FROM veterinario
WHERE crmv LIKE 'CRMV-MG 13___';


/* =====================================================================
   BLOCO C - FUNÇÕES MATEMÁTICAS E DE TEXTO
   ===================================================================== */

-- QUESTÃO 5 - Simulação numérica e arredondamentos [ROUND, TRUNC, CEIL]
-- Regra de negócio: simulação de reajuste de 7,5% na tabela de serviços,
-- comparando o valor original com o valor reajustado de três formas:
-- arredondado (ROUND), cortado (TRUNC) e arredondado para cima ao
-- próximo real inteiro (CEIL).
SELECT descricao,
       valor                                AS valor_original,
       valor * 1.075                        AS valor_reajustado_bruto,
       ROUND(valor * 1.075, 2)              AS valor_arredondado,
       TRUNC(valor * 1.075, 2)              AS valor_truncado,
       CEIL(valor * 1.075)                  AS valor_teto_inteiro
FROM servico
ORDER BY valor DESC;


-- QUESTÃO 6a - Classificação por módulo [MOD]
-- Regra de negócio: dividir os animais em dois lotes de atendimento
-- (Lote A para códigos pares e Lote B para ímpares) para organizar a
-- campanha de vacinação em dois dias diferentes.
SELECT id_animal,
       nome,
       MOD(id_animal, 2) AS resto_divisao,
       CASE
           WHEN MOD(id_animal, 2) = 0 THEN 'Lote A (código par)'
           ELSE 'Lote B (código ímpar)'
       END AS lote_campanha
FROM animal
ORDER BY lote_campanha, id_animal;

-- QUESTÃO 6b - Sorteio de registro [ORDER BY RANDOM() LIMIT 1]
-- Regra de negócio: sorteio de um brinde (banho grátis) entre os
-- animais ativos da clínica. A cada execução, o resultado pode mudar.
SELECT id_animal,
       nome,
       especie
FROM animal
WHERE ativo = TRUE
ORDER BY RANDOM()
LIMIT 1;


-- QUESTÃO 7 - Concatenação, padronização e extração [CONCAT, UPPER,
--             INITCAP, SPLIT_PART, LEFT]
-- Regra de negócio: gerar a etiqueta de identificação impressa na ficha
-- do paciente, juntando animal, espécie, raça e tutor. O CONCAT trata
-- valores nulos (a raça é opcional), o nome do animal sai em maiúsculas,
-- o nome do tutor é padronizado com INITCAP, e extraímos o primeiro nome
-- do tutor (SPLIT_PART) e a sigla da espécie (LEFT) para o chamado
-- pelo painel da recepção.
SELECT CONCAT(a.nome, ' | ', a.especie, ' | ', a.raca, ' | Tutor: ', t.nome)
                                              AS etiqueta_ficha,
       UPPER(a.nome)                          AS nome_animal_maiusculo,
       INITCAP(LOWER(t.nome))                 AS nome_tutor_padronizado,
       SPLIT_PART(t.nome, ' ', 1)             AS primeiro_nome_tutor,
       LEFT(a.especie, 3)                     AS sigla_especie
FROM animal a
INNER JOIN tutor t ON t.id_tutor = a.id_tutor
ORDER BY a.nome;


/* =====================================================================
   BLOCO D - FUNÇÕES DE DATA/HORA E FORMATAÇÃO
   ===================================================================== */

-- QUESTÃO 8 - Extração temporal e janela de período [EXTRACT,
--             DATE_TRUNC, INTERVAL]
-- Regra de negócio: relatório de movimento dos últimos 30 dias,
-- mostrando em que mês, dia da semana (0 = domingo ... 6 = sábado) e
-- hora cada consulta aconteceu. Ajuda a identificar os horários de
-- maior movimento da clínica.
SELECT id_consulta,
       data_hora,
       EXTRACT(YEAR FROM data_hora)      AS ano,
       EXTRACT(MONTH FROM data_hora)     AS mes,
       EXTRACT(DOW FROM data_hora)       AS dia_da_semana,
       EXTRACT(HOUR FROM data_hora)      AS hora,
       DATE_TRUNC('month', data_hora)    AS mes_referencia
FROM consulta
WHERE data_hora BETWEEN NOW() - INTERVAL '30 days' AND NOW()
ORDER BY data_hora;


-- QUESTÃO 9 - Tempo decorrido e projeção futura [AGE, NOW(), + INTERVAL]
-- Regra de negócio: controle de reforço vacinal. Para cada consulta
-- que aplicou vacina, mostra há quanto tempo foi realizada (AGE) e a
-- data prevista do reforço anual (data da consulta + 1 ano), usada
-- pela recepção para avisar os tutores.
SELECT a.nome                                         AS animal,
       s.descricao                                    AS vacina_aplicada,
       c.data_hora::DATE                              AS data_aplicacao,
       AGE(NOW(), c.data_hora)                        AS tempo_decorrido,
       (c.data_hora + INTERVAL '1 year')::DATE        AS data_reforco_previsto
FROM consulta c
INNER JOIN consulta_servico cs ON cs.id_consulta = c.id_consulta
INNER JOIN servico s           ON s.id_servico   = cs.id_servico
INNER JOIN animal a            ON a.id_animal    = c.id_animal
WHERE s.categoria = 'VACINA'
  AND c.status = 'REALIZADA'
ORDER BY c.data_hora;


-- QUESTÃO 10 - Relatório gerencial formatado [INNER JOIN, TO_CHAR,
--              LPAD, FORMAT]
-- Regra de negócio: relatório de faturamento por consulta realizada,
-- para a gerência. Une consulta, animal, veterinário e serviços
-- prestados; exibe o código da consulta com zeros à esquerda (LPAD),
-- a data no padrão brasileiro (DD/MM/YYYY), o total em reais (TO_CHAR)
-- e uma linha-resumo montada com FORMAT().
SELECT LPAD(c.id_consulta::TEXT, 6, '0')                         AS codigo_consulta,
       TO_CHAR(c.data_hora, 'DD/MM/YYYY')                        AS data_atendimento,
       a.nome                                                    AS animal,
       v.nome                                                    AS veterinario,
       CONCAT('R$ ',
              TO_CHAR(SUM(cs.quantidade * cs.valor_cobrado),
                      'FM999999990.00'))                         AS total_faturado,
       FORMAT('Consulta %s: %s atendido(a) por %s',
              LPAD(c.id_consulta::TEXT, 6, '0'), a.nome, v.nome) AS resumo
FROM consulta c
INNER JOIN animal a            ON a.id_animal       = c.id_animal
INNER JOIN veterinario v       ON v.id_veterinario  = c.id_veterinario
INNER JOIN consulta_servico cs ON cs.id_consulta    = c.id_consulta
WHERE c.status = 'REALIZADA'
GROUP BY c.id_consulta, c.data_hora, a.nome, v.nome
ORDER BY c.data_hora;
