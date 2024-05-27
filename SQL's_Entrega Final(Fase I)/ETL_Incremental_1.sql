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
    original_data JSONB,
    new_data JSONB,
    query TEXT
) WITH (fillfactor=100);

-- Debugging: Check if historico_mudancas table created successfully
SELECT 'Audit table created', COUNT(*) FROM audit.historico_mudancas;

-- Trigger function to record changes
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS trigger AS $body$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit.historico_mudancas (schema_name, table_name, user_name, action, original_data, new_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), to_jsonb(OLD), to_jsonb(NEW), current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit.historico_mudancas (schema_name, table_name, user_name, action, original_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), to_jsonb(OLD), current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit.historico_mudancas (schema_name, table_name, user_name, action, new_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), to_jsonb(NEW), current_query());
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
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'trabalho') LOOP
        EXECUTE format('CREATE TRIGGER %I_if_modified_trg AFTER INSERT OR UPDATE OR DELETE ON trabalho.%I FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();', rec.table_name, rec.table_name);
    END LOOP;
END $$;

-- Debugging: Check if triggers created for all tables
SELECT 'Triggers created for all tables', COUNT(*) FROM pg_trigger WHERE tgname LIKE '%_if_modified_trg';

-- Set schema for the data warehouse
SET search_path = DataWare;

-- Function to update Data Warehouse dimensions
CREATE OR REPLACE FUNCTION update_dimensions() RETURNS void AS $$
BEGIN
    -- Update Cliente Dimension
    INSERT INTO DataWare.Cliente (IDCliente, NomeCompletoCli, CPF_Cli, IDEnderecoCliente)
    SELECT 
        (new_data->>'IDCliente')::INT,
        new_data->>'NomeCompletoCli',
        (new_data->>'CPF_Cli')::NUMERIC,
        (new_data->>'IDCliente')::INT
    FROM audit.historico_mudancas
    WHERE table_name = 'Cliente' AND action = 'I'
    ON CONFLICT (IDCliente) DO UPDATE SET
        NomeCompletoCli = EXCLUDED.NomeCompletoCli,
        CPF_Cli = EXCLUDED.CPF_Cli,
        IDEnderecoCliente = EXCLUDED.IDEnderecoCliente;

    -- Update EnderecoCliente Dimension
    INSERT INTO DataWare.EnderecoCliente (IDEnderecoCliente, LogradouroCli, BairroCli, MunicipioCli, EstadoCli)
    SELECT 
        (new_data->>'IDCliente')::INT,
        new_data->>'LogradouroCli',
        new_data->>'BairroCli',
        new_data->>'MunicipioCli',
        new_data->>'EstadoCli'
    FROM audit.historico_mudancas
    WHERE table_name = 'Cliente' AND action = 'I'
    ON CONFLICT (IDEnderecoCliente) DO UPDATE SET
        LogradouroCli = EXCLUDED.LogradouroCli,
        BairroCli = EXCLUDED.BairroCli,
        MunicipioCli = EXCLUDED.MunicipioCli,
        EstadoCli = EXCLUDED.EstadoCli;

    -- Update Produto Dimension
    INSERT INTO DataWare.Produto (IDProduto, NumLote, NomeProd, ValorProd, IDCategoria)
    SELECT 
        (new_data->>'IDProduto')::INT,
        (new_data->>'NumLote')::INT,
        new_data->>'NomeProd',
        (new_data->>'ValorVenda')::REAL,
        c.IDCategoria
    FROM audit.historico_mudancas
    JOIN (
        SELECT DISTINCT CategoriaProd, ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria
        FROM trabalho.Produto
    ) c ON (new_data->>'CategoriaProd') = c.CategoriaProd
    WHERE table_name = 'Produto' AND action = 'I'
    ON CONFLICT (IDProduto, NumLote) DO UPDATE SET
        NomeProd = EXCLUDED.NomeProd,
        ValorProd = EXCLUDED.ValorProd,
        IDCategoria = EXCLUDED.IDCategoria;

    -- Update Fornecedor Dimension
    INSERT INTO DataWare.Fornecedor (CNPJ, NomeFor)
    SELECT 
        (new_data->>'CNPJ')::NUMERIC,
        new_data->>'NomeFor'
    FROM audit.historico_mudancas
    WHERE table_name = 'Fornecedor' AND action = 'I'
    ON CONFLICT (CNPJ) DO UPDATE SET
        NomeFor = EXCLUDED.NomeFor;

    -- Update CategoriaProduto Dimension
    INSERT INTO DataWare.CategoriaProduto (IDCategoria, CategoriaProd)
    SELECT DISTINCT
        ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria,
        CategoriaProd
    FROM trabalho.Produto
    ON CONFLICT (IDCategoria) DO NOTHING;

    -- Update Calendario Dimension
    INSERT INTO DataWare.Calendario (Data, DiaSemana, Mes, Trimestre, Ano)
    SELECT DISTINCT
        DataCompleta AS Data,
        TO_CHAR(DataCompleta, 'Day') AS DiaSemana,
        EXTRACT(MONTH FROM DataCompleta) AS Mes,
        EXTRACT(QUARTER FROM DataCompleta) AS Trimestre,
        EXTRACT(YEAR FROM DataCompleta) AS Ano
    FROM (
        SELECT to_date(new_data->>'Data', 'YYYY-MM-DD') AS DataCompleta
        FROM audit.historico_mudancas
        WHERE table_name = 'Compra' AND action = 'I'
        UNION
        SELECT to_date(new_data->>'DFabProd', 'YYYY-MM-DD') AS DataCompleta
        FROM audit.historico_mudancas
        WHERE table_name = 'Produto' AND action = 'I'
        UNION
        SELECT to_date(new_data->>'DValProd', 'YYYY-MM-DD') AS DataCompleta
        FROM audit.historico_mudancas
        WHERE table_name = 'Produto' AND action = 'I'
        UNION
        SELECT to_date(new_data->>'DataValCar', 'YYYY-MM-DD') AS DataCompleta
        FROM audit.historico_mudancas
        WHERE table_name = 'Cliente' AND action = 'I'
    ) AS DistinctDates
    ON CONFLICT (Data) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Function to update Data Warehouse facts
CREATE OR REPLACE FUNCTION update_facts() RETURNS void AS $$
BEGIN
    -- Update ReceitaDetalhada Fact Table
    INSERT INTO DataWare.ReceitaDetalhada (IDCompra, IDCliente, IDEnderecoCliente, IDProduto, NumLote, CNPJ, IDCategoria, Data, QuantidadeProd, ValorCompra)
    SELECT 
        (new_data->>'IDCompra')::INT,
        (new_data->>'IDCliente')::INT,
        (new_data->>'IDCliente')::INT, -- Assuming EnderecoCliente is the same as Cliente ID
        (new_data->>'IDProduto')::INT,
        (new_data->>'NumLote')::INT,
        (new_data->>'CNPJ')::NUMERIC,
        c.IDCategoria,
        to_date(new_data->>'Data', 'YYYY-MM-DD') AS Data,
        (new_data->>'QtdCompra')::INT,
        (new_data->>'QtdCompra')::INT * (new_data->>'ValorVenda')::REAL AS ValorCompra
    FROM audit.historico_mudancas
    JOIN (
        SELECT DISTINCT CategoriaProd, ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria
        FROM trabalho.Produto
    ) c ON (new_data->>'CategoriaProd') = c.CategoriaProd
    WHERE table_name = 'Compra' AND action = 'I'
    ON CONFLICT (IDCompra) DO NOTHING;

    -- Update ReceitaAgregada Fact Table
    INSERT INTO DataWare.ReceitaAgregada (IDCliente, IDEnderecoCliente, IDProduto, NumLote, CNPJ, IDCategoria, Data, ValorAgregado)
    SELECT 
        (new_data->>'IDCliente')::INT,
        (new_data->>'IDCliente')::INT, -- Assuming EnderecoCliente is the same as Cliente ID
        (new_data->>'IDProduto')::INT,
        (new_data->>'NumLote')::INT,
        (new_data->>'CNPJ')::NUMERIC,
        c.IDCategoria,
        to_date(new_data->>'Data', 'YYYY-MM-DD') AS Data,
        SUM((new_data->>'QtdCompra')::INT * (new_data->>'ValorVenda')::REAL) AS ValorAgregado
    FROM audit.historico_mudancas
    JOIN (
        SELECT DISTINCT CategoriaProd, ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria
        FROM trabalho.Produto
    ) c ON (new_data->>'CategoriaProd') = c.CategoriaProd
    WHERE table_name = 'Compra' AND action = 'I'
    GROUP BY (new_data->>'IDCliente'), (new_data->>'IDProduto'), (new_data->>'NumLote'), (new_data->>'CNPJ'), c.IDCategoria, to_date(new_data->>'Data', 'YYYY-MM-DD')
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Call the functions to update the dimensions and facts
SELECT update_dimensions();
SELECT update_facts();

-- Truncate audit table after processing
TRUNCATE TABLE audit.historico_mudancas;

-- Debugging: Check if dimensions and facts updated
SELECT 'Dimensions and facts updated successfully';

-- Final checks
SELECT * FROM DataWare.ReceitaDetalhada LIMIT 10;
SELECT * FROM DataWare.ReceitaAgregada LIMIT 10;
