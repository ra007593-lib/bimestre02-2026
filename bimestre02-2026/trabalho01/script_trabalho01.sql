/* =====================================================================
   JUSTIFICATIVA DA ESCOLHA DO TEMA
   Escolhi uma clínica veterinária porque é um negócio real, e antes era um curso que me chamava atenção em fazer

   ===================================================================== */


DROP DATABASE IF EXISTS clinica_veterinaria;
CREATE DATABASE clinica_veterinaria
    ENCODING 'UTF8'
    TEMPLATE template0;

CREATE TABLE tutor (
    id_tutor SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15) NOT NULL,
    email VARCHAR(100) UNIQUE,
    cidade VARCHAR(60) NOT NULL DEFAULT 'Belo Horizonte',
    data_cadastro DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE animal (
    id_animal SERIAL PRIMARY KEY,
    id_tutor INTEGER NOT NULL,
    nome VARCHAR(60) NOT NULL,
    especie VARCHAR(20) NOT NULL,
    raca VARCHAR(60) DEFAULT 'SRD',
    sexo CHAR(1) NOT NULL,
    data_nascimento DATE NOT NULL,
    peso_kg NUMERIC(5,2)  NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_animal_tutor FOREIGN KEY (id_tutor)
        REFERENCES tutor (id_tutor) ON DELETE RESTRICT,
    CONSTRAINT ck_animal_especie CHECK
        (especie IN ('CACHORRO','GATO','COELHO','AVE','OUTRO')),
    CONSTRAINT ck_animal_sexo CHECK (sexo IN ('M','F')),
    CONSTRAINT ck_animal_peso CHECK (peso_kg > 0),
    CONSTRAINT ck_animal_nasc CHECK (data_nascimento <= CURRENT_DATE)
);

CREATE TABLE veterinario (
    id_veterinario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    crmv VARCHAR(15)  NOT NULL UNIQUE,
    especialidade VARCHAR(50) NOT NULL DEFAULT 'Clínica Geral',
    data_admissao DATE NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE servico (
    id_servico SERIAL PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL UNIQUE,
    categoria VARCHAR(20) NOT NULL,
    valor NUMERIC(8,2)  NOT NULL,
    duracao_min INTEGER  NOT NULL DEFAULT 30,
    CONSTRAINT ck_servico_categoria CHECK
        (categoria IN ('CONSULTA','VACINA','EXAME','CIRURGIA','ESTETICA','PROCEDIMENTO')),
    CONSTRAINT ck_servico_valor   CHECK (valor >= 0),
    CONSTRAINT ck_servico_duracao CHECK (duracao_min > 0)
);


CREATE TABLE consulta (
    id_consulta SERIAL PRIMARY KEY,
    id_animal INTEGER NOT NULL,
    id_veterinario INTEGER NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    status VARCHAR(10)  NOT NULL DEFAULT 'AGENDADA',
    observacoes TEXT,
    CONSTRAINT fk_consulta_animal FOREIGN KEY (id_animal)
        REFERENCES animal (id_animal) ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_vet FOREIGN KEY (id_veterinario)
        REFERENCES veterinario (id_veterinario) ON DELETE RESTRICT,
    CONSTRAINT ck_consulta_status CHECK
        (status IN ('AGENDADA','REALIZADA','CANCELADA')),
    CONSTRAINT uq_consulta_vet_horario UNIQUE (id_veterinario, data_hora)
);


CREATE TABLE consulta_servico (
    id_consulta INTEGER NOT NULL,
    id_servico INTEGER NOT NULL,
    quantidade INTEGER NOT NULL DEFAULT 1,
    valor_cobrado  NUMERIC(8,2)  NOT NULL,
    CONSTRAINT pk_consulta_servico PRIMARY KEY (id_consulta, id_servico),
    CONSTRAINT fk_cs_consulta FOREIGN KEY (id_consulta)
        REFERENCES consulta (id_consulta) ON DELETE CASCADE,
    CONSTRAINT fk_cs_servico FOREIGN KEY (id_servico)
        REFERENCES servico (id_servico) ON DELETE RESTRICT,
    CONSTRAINT ck_cs_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_cs_valor      CHECK (valor_cobrado >= 0)
);

INSERT INTO tutor (nome, cpf, telefone, email, cidade, data_cadastro) VALUES
('Carlos Eduardo Mendes', '11111111111', '31991110001', 'carlos.mendes@email.com',  'Belo Horizonte', '2025-01-10'),
('Ana Paula Ribeiro',     '22222222222', '31991110002', 'ana.ribeiro@email.com',    'Belo Horizonte', '2025-02-15'),
('Marcos Vinícius Souza', '33333333333', '31991110003', 'marcos.souza@email.com',   'Contagem',       '2025-03-05'),
('Juliana Ferreira Lima', '44444444444', '31991110004', 'juliana.lima@email.com',   'Betim',          '2025-04-20'),
('Roberto Alves Pinto',   '55555555555', '31991110005', 'roberto.pinto@email.com',  'Belo Horizonte', '2025-05-12'),
('Fernanda Costa Rocha',  '66666666666', '31991110006', 'fernanda.rocha@email.com', 'Nova Lima',      '2025-06-30'),
('Lucas Gabriel Martins', '77777777777', '31991110007', 'lucas.martins@email.com',  'Belo Horizonte', '2025-07-18'),
('Patrícia Gomes Duarte', '88888888888', '31991110008', 'patricia.duarte@email.com','Contagem',       '2025-08-25'),
('Rafael Henrique Dias',  '99999999999', '31991110009', 'rafael.dias@email.com',    'Belo Horizonte', '2025-09-09'),
('Camila Nogueira Reis',  '10101010101', '31991110010', 'camila.reis@email.com',    'Sabará',         '2025-10-01');

INSERT INTO animal (id_tutor, nome, especie, raca, sexo, data_nascimento, peso_kg) VALUES
(1,  'Thor',   'CACHORRO', 'Labrador',         'M', '2020-03-14', 32.50),
(2,  'Mel',    'CACHORRO', 'Poodle',           'F', '2019-07-22',  7.80),
(3,  'Luna',   'GATO',     'SRD',              'F', '2021-11-05',  4.20),
(4,  'Rex',    'CACHORRO', 'Pastor Alemão',    'M', '2018-01-30', 38.00),
(5,  'Bela',   'CACHORRO', 'Shih Tzu',         'F', '2022-05-17',  6.10),
(6,  'Simba',  'GATO',     'Persa',            'M', '2020-09-09',  5.30),
(7,  'Nina',   'CACHORRO', 'Golden Retriever', 'F', '2021-02-28', 28.90),
(8,  'Pipoca', 'COELHO',   'Mini Lion',        'M', '2023-04-03',  1.90),
(9,  'Bolt',   'CACHORRO', 'Beagle',           'M', '2022-12-12', 11.40),
(10, 'Mia',    'GATO',     'Siamês',           'F', '2023-08-19',  3.70);

INSERT INTO veterinario (nome, crmv, especialidade, data_admissao) VALUES
('Dr. André Barbosa',      'CRMV-MG 10234', 'Clínica Geral',          '2019-03-01'),
('Dra. Beatriz Carvalho',  'CRMV-MG 11876', 'Clínica Geral',          '2020-06-15'),
('Dr. Henrique Tavares',   'CRMV-MG 12450', 'Diagnóstico por Imagem', '2021-01-10'),
('Dra. Larissa Moura',     'CRMV-MG 13002', 'Cirurgia',               '2021-08-23'),
('Dr. Otávio Nascimento',  'CRMV-MG 13977', 'Dermatologia',           '2022-02-07'),
('Dra. Renata Azevedo',    'CRMV-MG 14521', 'Odontologia',            '2023-05-02');

INSERT INTO servico (descricao, categoria, valor, duracao_min) VALUES
('Consulta clínica geral',     'CONSULTA',     120.00, 30),
('Vacina V10',                 'VACINA',        90.00, 15),
('Vacina antirrábica',         'VACINA',        60.00, 15),
('Hemograma completo',         'EXAME',         75.00, 20),
('Ultrassonografia',           'EXAME',        180.00, 40),
('Raio-X',                     'EXAME',        150.00, 30),
('Banho e tosa higiênica',     'ESTETICA',      80.00, 60),
('Castração',                  'CIRURGIA',     650.00, 120),
('Limpeza dentária',           'CIRURGIA',     320.00, 60),
('Vermifugação',               'PROCEDIMENTO',  45.00, 10);

INSERT INTO consulta (id_animal, id_veterinario, data_hora, status, observacoes) VALUES
(1,  1, '2026-09-02 09:00', 'REALIZADA', 'Check-up anual e vacinação'),
(2,  2, '2026-09-03 10:30', 'REALIZADA', 'Queixa de apatia; solicitado hemograma'),
(3,  1, '2026-09-10 14:00', 'REALIZADA', 'Suspeita de cálculo renal'),
(4,  3, '2026-09-15 11:00', 'REALIZADA', 'Claudicação no membro posterior'),
(5,  4, '2026-09-22 16:00', 'REALIZADA', 'Castração eletiva'),
(6,  2, '2026-10-05 08:30', 'REALIZADA', 'Reforço de vacina antirrábica'),
(7,  5, '2026-10-12 15:00', 'CANCELADA', 'Tutor cancelou por motivo de viagem'),
(8,  1, '2026-10-20 09:30', 'REALIZADA', 'Consulta e vermifugação'),
(9,  6, '2026-11-03 10:00', 'REALIZADA', 'Tártaro acentuado; limpeza realizada'),
(10, 3, '2026-11-10 14:30', 'AGENDADA',  'Retorno para avaliação');

INSERT INTO consulta_servico (id_consulta, id_servico, quantidade, valor_cobrado) VALUES
(1, 1,  1, 120.00),
(1, 2,  1,  90.00),
(2, 1,  1, 120.00),
(2, 4,  1,  75.00),
(3, 1,  1, 120.00),
(3, 5,  1, 180.00),
(4, 1,  1, 120.00),
(4, 6,  2, 150.00),
(5, 8,  1, 650.00),
(6, 1,  1, 120.00),
(6, 3,  1,  60.00),
(8, 1,  1, 120.00),
(8, 10, 1,  45.00),
(9, 1,  1, 120.00),
(9, 9,  1, 320.00),
(10, 1, 1, 120.00);

SELECT a.nome AS animal, a.especie, a.raca, t.nome AS tutor, t.telefone
FROM animal a
JOIN tutor t ON t.id_tutor = a.id_tutor
ORDER BY t.nome;

SELECT c.id_consulta, c.data_hora, a.nome AS animal,
       t.nome AS tutor, v.nome AS veterinario
FROM consulta c
JOIN animal      a ON a.id_animal      = c.id_animal
JOIN tutor       t ON t.id_tutor       = a.id_tutor
JOIN veterinario v ON v.id_veterinario = c.id_veterinario
WHERE c.status = 'REALIZADA'
ORDER BY c.data_hora;

SELECT especie, COUNT(*) AS total_animais, ROUND(AVG(peso_kg), 2) AS peso_medio_kg
FROM animal
GROUP BY especie
ORDER BY total_animais DESC;

SELECT v.nome, v.especialidade, COUNT(c.id_consulta) AS total_consultas
FROM veterinario v
LEFT JOIN consulta c ON c.id_veterinario = v.id_veterinario
GROUP BY v.id_veterinario, v.nome, v.especialidade
ORDER BY total_consultas DESC, v.nome;

SELECT c.id_consulta, a.nome AS animal,
       SUM(cs.quantidade * cs.valor_cobrado) AS total_faturado
FROM consulta c
JOIN animal a            ON a.id_animal    = c.id_animal
JOIN consulta_servico cs ON cs.id_consulta = c.id_consulta
WHERE c.status = 'REALIZADA'
GROUP BY c.id_consulta, a.nome
HAVING SUM(cs.quantidade * cs.valor_cobrado) > 200
ORDER BY total_faturado DESC;

SELECT s.categoria,
       SUM(cs.quantidade)                      AS qtd_servicos,
       SUM(cs.quantidade * cs.valor_cobrado)   AS receita_total
FROM servico s
JOIN consulta_servico cs ON cs.id_servico = s.id_servico
JOIN consulta c          ON c.id_consulta = cs.id_consulta
WHERE c.status = 'REALIZADA'
GROUP BY s.categoria
ORDER BY receita_total DESC;

SELECT nome, especie, peso_kg, data_nascimento
FROM animal
WHERE (especie = 'CACHORRO' AND peso_kg > 20)
   OR (especie = 'GATO'     AND data_nascimento >= '2021-01-01')
ORDER BY especie, nome;

SELECT t.nome AS tutor, COUNT(DISTINCT c.id_consulta) AS consultas,
       SUM(cs.quantidade * cs.valor_cobrado) AS total_gasto
FROM tutor t
JOIN animal a            ON a.id_tutor     = t.id_tutor
JOIN consulta c          ON c.id_animal    = a.id_animal
JOIN consulta_servico cs ON cs.id_consulta = c.id_consulta
WHERE c.status = 'REALIZADA'
GROUP BY t.id_tutor, t.nome
ORDER BY total_gasto DESC
LIMIT 5;

SELECT s.descricao, s.categoria, s.valor
FROM servico s
LEFT JOIN consulta_servico cs ON cs.id_servico = s.id_servico
WHERE cs.id_servico IS NULL;

SELECT c.data_hora, a.nome AS animal, c.status, c.observacoes
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
WHERE c.data_hora >= '2026-10-01' AND c.data_hora < '2026-11-01'
  AND (c.observacoes ILIKE '%vacina%' OR c.status = 'CANCELADA');