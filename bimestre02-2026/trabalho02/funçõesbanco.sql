
CREATE OR REPLACE FUNCTION fn_total_consulta(p_id_consulta INTEGER)
RETURNS NUMERIC(10,2) AS $$
DECLARE
    v_total NUMERIC(10,2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM consulta WHERE id_consulta = p_id_consulta) THEN
        RAISE EXCEPTION 'Consulta % não encontrada.', p_id_consulta;
    END IF;
    SELECT COALESCE(SUM(quantidade * valor_cobrado), 0)
      INTO v_total
      FROM consulta_servico
     WHERE id_consulta = p_id_consulta;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_idade_animal(p_id_animal INTEGER)
RETURNS TEXT AS $$
DECLARE
    v_nascimento DATE;
    v_idade      INTERVAL;
BEGIN
    SELECT data_nascimento INTO v_nascimento
      FROM animal
     WHERE id_animal = p_id_animal;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Animal % não encontrado.', p_id_animal;
    END IF;
    v_idade := AGE(CURRENT_DATE, v_nascimento);
    RETURN EXTRACT(YEAR  FROM v_idade)::INT || ' anos e ' ||
           EXTRACT(MONTH FROM v_idade)::INT || ' meses';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_agendar_consulta(
    p_id_animal      INTEGER,
    p_id_veterinario INTEGER,
    p_data_hora      TIMESTAMP,
    p_observacoes    TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_ativo_animal BOOLEAN;
    v_ativo_vet    BOOLEAN;
    v_novo_id      INTEGER;
BEGIN
    SELECT ativo INTO v_ativo_animal FROM animal WHERE id_animal = p_id_animal;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Animal % não encontrado.', p_id_animal;
    END IF;
    IF NOT v_ativo_animal THEN
        RAISE EXCEPTION 'O animal % está inativo e não pode ser agendado.', p_id_animal;
    END IF;
    SELECT ativo INTO v_ativo_vet FROM veterinario WHERE id_veterinario = p_id_veterinario;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Veterinário % não encontrado.', p_id_veterinario;
    END IF;
    IF NOT v_ativo_vet THEN
        RAISE EXCEPTION 'O veterinário % está inativo.', p_id_veterinario;
    END IF;
    IF p_data_hora <= NOW() THEN
        RAISE EXCEPTION 'A data do agendamento deve ser futura.';
    END IF;
    IF EXISTS (SELECT 1 FROM consulta
                WHERE id_veterinario = p_id_veterinario
                  AND data_hora = p_data_hora) THEN
        RAISE EXCEPTION 'O veterinário % já possui consulta em %.',
                        p_id_veterinario, p_data_hora;
    END IF;
    INSERT INTO consulta (id_animal, id_veterinario, data_hora, status, observacoes)
    VALUES (p_id_animal, p_id_veterinario, p_data_hora, 'AGENDADA', p_observacoes)
    RETURNING id_consulta INTO v_novo_id;

    RETURN v_novo_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_cancelar_consulta(p_id_consulta INTEGER)
RETURNS TEXT AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    SELECT status INTO v_status FROM consulta WHERE id_consulta = p_id_consulta;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Consulta % não encontrada.', p_id_consulta;
    END IF;
    IF v_status <> 'AGENDADA' THEN
        RAISE EXCEPTION 'Só é possível cancelar consultas agendadas (status atual: %).', v_status;
    END IF;
    UPDATE consulta SET status = 'CANCELADA' WHERE id_consulta = p_id_consulta;
    RETURN 'Consulta ' || p_id_consulta || ' cancelada com sucesso.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_historico_animal(p_id_animal INTEGER)
RETURNS TABLE (
    consulta_id      INTEGER,
    data_atendimento TIMESTAMP,
    veterinario      VARCHAR,
    situacao         VARCHAR,
    total_cobrado    NUMERIC
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM animal WHERE id_animal = p_id_animal) THEN
        RAISE EXCEPTION 'Animal % não encontrado.', p_id_animal;
    END IF;
    RETURN QUERY
    SELECT c.id_consulta,
           c.data_hora,
           v.nome,
           c.status,
           fn_total_consulta(c.id_consulta)
      FROM consulta c
      JOIN veterinario v ON v.id_veterinario = c.id_veterinario
     WHERE c.id_animal = p_id_animal
     ORDER BY c.data_hora DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_reajustar_precos(
    p_categoria  VARCHAR,
    p_percentual NUMERIC
) RETURNS INTEGER AS $$
DECLARE
    v_qtd INTEGER;
BEGIN
    IF p_percentual < -50 OR p_percentual > 100 THEN
        RAISE EXCEPTION 'Percentual % fora do limite permitido (-50 a 100).', p_percentual;
    END IF;
    UPDATE servico
       SET valor = ROUND(valor * (1 + p_percentual / 100), 2)
     WHERE categoria = UPPER(p_categoria);
    GET DIAGNOSTICS v_qtd = ROW_COUNT;
    IF v_qtd = 0 THEN
        RAISE EXCEPTION 'Nenhum serviço encontrado na categoria %.', p_categoria;
    END IF;

    RETURN v_qtd;
END;
$$ LANGUAGE plpgsql;


SELECT fn_total_consulta(4) AS total_consulta_4;

SELECT c.id_consulta, a.nome AS animal, fn_total_consulta(c.id_consulta) AS total
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
ORDER BY c.id_consulta;

SELECT nome, especie, fn_idade_animal(id_animal) AS idade
FROM animal
ORDER BY nome;

SELECT fn_agendar_consulta(1, 2, '2026-12-15 10:00', 'Retorno pós-vacina') AS id_nova_consulta;
SELECT fn_agendar_consulta(1, 2, '2026-12-15 10:00');   
SELECT fn_agendar_consulta(1, 2, '2026-01-10 10:00');  

SELECT fn_cancelar_consulta(11);
SELECT fn_cancelar_consulta(1);   

SELECT * FROM fn_historico_animal(1);

SELECT fn_reajustar_precos('VACINA', 10);
SELECT descricao, valor FROM servico WHERE categoria = 'VACINA';
SELECT fn_reajustar_precos('VACINA', 500);
