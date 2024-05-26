-- Drop and recreate audit schema for capturing changes
DROP SCHEMA IF EXISTS audit CASCADE;
CREATE SCHEMA audit;
SET search_path = audit;

-- Table for recording changes
CREATE TABLE audit.historico_mudancas (
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    user_name TEXT,
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    action TEXT NOT NULL CHECK (action IN ('I','D','U')),
    original_data TEXT,
    new_data TEXT,
    query TEXT
) WITH (fillfactor=100);

-- Debugging: Check if historico_mudancas table created successfully
SELECT 'Audit table created', COUNT(*) FROM audit.historico_mudancas;

-- Trigger function to record changes
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS trigger AS $body$
DECLARE
    v_old_data TEXT;
    v_new_data TEXT;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.historico_mudancas (schema_name, table_name, user_name, action, original_data, new_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), v_old_data, v_new_data, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := ROW(OLD.*);
        INSERT INTO audit.historico_mudancas (schema_name, table_name, user_name, action, original_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), v_old_data, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.historico_mudancas (schema_name, table_name, user_name, action, new_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), v_new_data, current_query());
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Debugging: Check if the trigger function created successfully
SELECT 'Trigger function created successfully';

-- Create triggers for each table to capture changes

-- Cliente Table
CREATE TRIGGER cliente_if_modified_trg
AFTER INSERT OR UPDATE OR DELETE ON trabalho.Cliente
FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
-- Debugging: Check if trigger created for Cliente table
SELECT 'Cliente trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'cliente_if_modified_trg';

-- Funcionario Table
CREATE TRIGGER funcionario_if_modified_trg
AFTER INSERT OR UPDATE OR DELETE ON trabalho.Funcionario
FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
-- Debugging: Check if trigger created for Funcionario table
SELECT 'Funcionario trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'funcionario_if_modified_trg';

-- Produto Table
CREATE TRIGGER produto_if_modified_trg
AFTER INSERT OR UPDATE OR DELETE ON trabalho.Produto
FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
-- Debugging: Check if trigger created for Produto table
SELECT 'Produto trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'produto_if_modified_trg';

-- Compra Table
CREATE TRIGGER compra_if_modified_trg
AFTER INSERT OR UPDATE OR DELETE ON trabalho.Compra
FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
-- Debugging: Check if trigger created for Compra table
SELECT 'Compra trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'compra_if_modified_trg';

-- Possui Table
CREATE TRIGGER possui_if_modified_trg
AFTER INSERT OR UPDATE OR DELETE ON trabalho.Possui
FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
-- Debugging: Check if trigger created for Possui table
SELECT 'Possui trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'possui_if_modified_trg';

-- Fornece Table
CREATE TRIGGER fornece_if_modified_trg
AFTER INSERT OR UPDATE OR DELETE ON trabalho.Fornece
FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
-- Debugging: Check if trigger created for Fornece table
SELECT 'Fornece trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'fornece_if_modified_trg';

-- Create shadow tables for capturing inserts
CREATE TABLE audit.ins_Cliente AS SELECT * FROM trabalho.Cliente WHERE 1=0;
CREATE TABLE audit.ins_Funcionario AS SELECT * FROM trabalho.Funcionario WHERE 1=0;
CREATE TABLE audit.ins_Produto AS SELECT * FROM trabalho.Produto WHERE 1=0;
CREATE TABLE audit.ins_Compra AS SELECT * FROM trabalho.Compra WHERE 1=0;
CREATE TABLE audit.ins_Possui AS SELECT * FROM trabalho.Possui WHERE 1=0;
CREATE TABLE audit.ins_Fornece AS SELECT * FROM trabalho.Fornece WHERE 1=0;

-- Debugging: Check if shadow tables created successfully
SELECT 'Shadow tables created successfully';

-- Functions to capture inserts into shadow tables

-- Cliente Insert Function
CREATE OR REPLACE FUNCTION audit.ins_Cliente_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.ins_Cliente VALUES (NEW.IDCliente, NEW.NomeCompletoCli, NEW.LogradouroCli, NEW.BairroCli, NEW.MunicipioCli, NEW.EstadoCli, NEW.CPF_Cli, NEW.NumCartao, NEW.DataValCar, NEW.CVC, NEW.NomeCar);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Cliente Insert Trigger
CREATE TRIGGER cliente_insert_trg
AFTER INSERT ON trabalho.Cliente
FOR EACH ROW EXECUTE PROCEDURE audit.ins_Cliente_func();
-- Debugging: Check if Cliente insert trigger created
SELECT 'Cliente insert trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'cliente_insert_trg';

-- Repeat similar functions and triggers for other tables
-- Funcionario Insert Function
CREATE OR REPLACE FUNCTION audit.ins_Funcionario_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.ins_Funcionario VALUES (NEW.IDFuncionario, NEW.NomeCompFunc, NEW.CPFFunc, NEW.SalarioFunc);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Funcionario Insert Trigger
CREATE TRIGGER funcionario_insert_trg
AFTER INSERT ON trabalho.Funcionario
FOR EACH ROW EXECUTE PROCEDURE audit.ins_Funcionario_func();
-- Debugging: Check if Funcionario insert trigger created
SELECT 'Funcionario insert trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'funcionario_insert_trg';

-- Produto Insert Function
CREATE OR REPLACE FUNCTION audit.ins_Produto_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.ins_Produto VALUES (NEW.IDProduto, NEW.NumLote, NEW.NomeProd, NEW.CategoriaProd, NEW.DescricaoProd, NEW.DFabProd, NEW.DValProd, NEW.ValorVenda);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Produto Insert Trigger
CREATE TRIGGER produto_insert_trg
AFTER INSERT ON trabalho.Produto
FOR EACH ROW EXECUTE PROCEDURE audit.ins_Produto_func();
-- Debugging: Check if Produto insert trigger created
SELECT 'Produto insert trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'produto_insert_trg';

-- Compra Insert Function
CREATE OR REPLACE FUNCTION audit.ins_Compra_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.ins_Compra VALUES (NEW.IDCompra, NEW.Data);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Compra Insert Trigger
CREATE TRIGGER compra_insert_trg
AFTER INSERT ON trabalho.Compra
FOR EACH ROW EXECUTE PROCEDURE audit.ins_Compra_func();
-- Debugging: Check if Compra insert trigger created
SELECT 'Compra insert trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'compra_insert_trg';

-- Possui Insert Function
CREATE OR REPLACE FUNCTION audit.ins_Possui_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.ins_Possui VALUES (NEW.QtdCompra, NEW.IDCompra, NEW.IDProduto, NEW.NumLote);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Possui Insert Trigger
CREATE TRIGGER possui_insert_trg
AFTER INSERT ON trabalho.Possui
FOR EACH ROW EXECUTE PROCEDURE audit.ins_Possui_func();
-- Debugging: Check if Possui insert trigger created
SELECT 'Possui insert trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'possui_insert_trg';

-- Fornece Insert Function
CREATE OR REPLACE FUNCTION audit.ins_Fornece_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.ins_Fornece VALUES (NEW.QtdFornecida, NEW.ValorCompra, NEW.CNPJ, NEW.IDProduto, NEW.NumLote);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;

-- Fornece Insert Trigger
CREATE TRIGGER fornece_insert_trg
AFTER INSERT ON trabalho.Fornece
FOR EACH ROW EXECUTE PROCEDURE audit.ins_Fornece_func();
-- Debugging: Check if Fornece insert trigger created
SELECT 'Fornece insert trigger created successfully', COUNT(*) FROM pg_trigger WHERE tgname = 'fornece_insert_trg';

-- Updating the Calendar table in Data Warehouse
INSERT INTO DataWare.Dim_Data (Data_ID, DataCompleta, DiaSemana, Dia, Mes, Trimestre, Ano)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY DataCompleta) + (SELECT COALESCE(MAX(Data_ID), 0) FROM DataWare.Dim_Data) AS Data_ID,
    DataCompleta,
    TO_CHAR(DataCompleta, 'Day') AS DiaSemana,
    EXTRACT(DAY FROM DataCompleta) AS Dia,
    EXTRACT(MONTH FROM DataCompleta) AS Mes,
    EXTRACT(QUARTER FROM DataCompleta) AS Trimestre,
    EXTRACT(YEAR FROM DataCompleta) AS Ano
FROM (
    SELECT Data AS DataCompleta FROM audit.ins_Compra
    UNION
    SELECT DFabProd AS DataCompleta FROM audit.ins_Produto
    UNION
    SELECT DValProd AS DataCompleta FROM audit.ins_Produto
    UNION
    SELECT DataValCar AS DataCompleta FROM audit.ins_Cliente
) AS DistinctDates
WHERE DataCompleta NOT IN (SELECT DataCompleta FROM DataWare.Dim_Data);

-- Debugging: Validate Calendar table update
SELECT 'Calendar table updated', COUNT(*) FROM DataWare.Dim_Data;

-- Loading data into Fact tables from incremental tables
-- Fato_Receita_Detalhada
INSERT INTO DataWare.Fato_Receita_Detalhada (IDFato, Compra_ID, Cliente_ID, Endereco_ID, Produto_ID, Fornecedor_ID, Categoria_ID, Data_ID, Hora, Quantidade, Valor)
SELECT
    ROW_NUMBER() OVER (ORDER BY comp.IDCompra) + (SELECT COALESCE(MAX(IDFato), 0) FROM DataWare.Fato_Receita_Detalhada) AS IDFato,
    comp.IDCompra,
    cli.IDCliente,
    cli.IDCliente AS Endereco_ID,
    prod.IDProduto,
    fornec.Fornecedor_ID,
    cat.Categoria_ID,
    data.Data_ID,
    EXTRACT(TIME FROM comp.Data) AS Hora,
    pos.QtdCompra AS Quantidade,
    (pos.QtdCompra * prod.ValorVenda) AS Valor
FROM audit.ins_Compra comp
JOIN audit.ins_Realiza rea ON comp.IDCompra = rea.IDCompra
JOIN trabalho.Cliente cli ON rea.IDCliente = cli.IDCliente
JOIN audit.ins_Possui pos ON comp.IDCompra = pos.IDCompra
JOIN trabalho.Produto prod ON pos.IDProduto = prod.IDProduto AND pos.NumLote = prod.NumLote
JOIN (
    SELECT CNPJ, ROW_NUMBER() OVER (ORDER BY CNPJ) AS Fornecedor_ID FROM trabalho.Fornecedor
) fornec ON prod.IDProduto = fornec.CNPJ
JOIN (
    SELECT DISTINCT
        CategoriaProd,
        ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS Categoria_ID
    FROM trabalho.Produto
) cat ON prod.CategoriaProd = cat.CategoriaProd
JOIN (
    SELECT DISTINCT
        DataCompleta,
        ROW_NUMBER() OVER (ORDER BY DataCompleta) + (SELECT COALESCE(MAX(Data_ID), 0) FROM DataWare.Dim_Data) AS Data_ID
    FROM (
        SELECT Data AS DataCompleta FROM audit.ins_Compra
        UNION
        SELECT DFabProd AS DataCompleta FROM audit.ins_Produto
        UNION
        SELECT DValProd AS DataCompleta FROM audit.ins_Produto
        UNION
        SELECT DataValCar AS DataCompleta FROM audit.ins_Cliente
    ) AS DistinctDates
) data ON DATE(comp.Data) = data.DataCompleta
ON CONFLICT (IDFato) DO NOTHING;

-- Debugging: Validate Fato_Receita_Detalhada table update
SELECT 'Fato_Receita_Detalhada updated', COUNT(*) FROM DataWare.Fato_Receita_Detalhada;

-- Fato_Receita_Agregada
INSERT INTO DataWare.Fato_Receita_Agregada (IDFato, Cliente_ID, Endereco_ID, Produto_ID, Fornecedor_ID, Categoria_ID, Data_ID, Valor_Agregado)
SELECT
    ROW_NUMBER() OVER (ORDER BY cli.IDCliente) + (SELECT COALESCE(MAX(IDFato), 0) FROM DataWare.Fato_Receita_Agregada) AS IDFato,
    cli.IDCliente,
    cli.IDCliente AS Endereco_ID,
    prod.IDProduto,
    fornec.Fornecedor_ID,
    cat.Categoria_ID,
    data.Data_ID,
    SUM(pos.QtdCompra * prod.ValorVenda) AS Valor_Agregado
FROM audit.ins_Compra comp
JOIN audit.ins_Realiza rea ON comp.IDCompra = rea.IDCompra
JOIN trabalho.Cliente cli ON rea.IDCliente = cli.IDCliente
JOIN audit.ins_Possui pos ON comp.IDCompra = pos.IDCompra
JOIN trabalho.Produto prod ON pos.IDProduto = prod.IDProduto AND pos.NumLote = prod.NumLote
JOIN (
    SELECT CNPJ, ROW_NUMBER() OVER (ORDER BY CNPJ) AS Fornecedor_ID FROM trabalho.Fornecedor
) fornec ON prod.IDProduto = fornec.CNPJ
JOIN (
    SELECT DISTINCT
        CategoriaProd,
        ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS Categoria_ID
    FROM trabalho.Produto
) cat ON prod.CategoriaProd = cat.CategoriaProd
JOIN (
    SELECT DISTINCT
        DataCompleta,
        ROW_NUMBER() OVER (ORDER BY DataCompleta) + (SELECT COALESCE(MAX(Data_ID), 0) FROM DataWare.Dim_Data) AS Data_ID
    FROM (
        SELECT Data AS DataCompleta FROM audit.ins_Compra
        UNION
        SELECT DFabProd AS DataCompleta FROM audit.ins_Produto
        UNION
        SELECT DValProd AS DataCompleta FROM audit.ins_Produto
        UNION
        SELECT DataValCar AS DataCompleta FROM audit.ins_Cliente
    ) AS DistinctDates
) data ON DATE(comp.Data) = data.DataCompleta
GROUP BY cli.IDCliente, cli.IDCliente, prod.IDProduto, fornec.Fornecedor_ID, cat.Categoria_ID, data.Data_ID
ON CONFLICT (IDFato) DO NOTHING;

-- Debugging: Validate Fato_Receita_Agregada table update
SELECT 'Fato_Receita_Agregada updated', COUNT(*) FROM DataWare.Fato_Receita_Agregada;

-- Truncate incremental tables after loading data into the warehouse
TRUNCATE TABLE audit.ins_Cliente;
TRUNCATE TABLE audit.ins_Funcionario;
TRUNCATE TABLE audit.ins_Produto;
TRUNCATE TABLE audit.ins_Compra;
TRUNCATE TABLE audit.ins_Possui;
TRUNCATE TABLE audit.ins_Fornece;

-- Debugging: Check if incremental tables truncated
SELECT 'Incremental tables truncated';
