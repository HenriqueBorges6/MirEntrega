-- Set schema for the data warehouse
SET search_path = DataWare;

-- Truncate all tables to ensure a clean load
TRUNCATE TABLE Fato_Receita_Detalhada;
TRUNCATE TABLE Fato_Receita_Agregada;
TRUNCATE TABLE Dim_Cliente;
TRUNCATE TABLE Dim_Endereco;
TRUNCATE TABLE Dim_Produto;
TRUNCATE TABLE Dim_Fornecedor;
TRUNCATE TABLE Dim_Categoria;
TRUNCATE TABLE Dim_Data;
TRUNCATE TABLE Dim_Funcionario;

-- Set schema for the operational database
SET search_path = trabalho;

-- Debugging test: Check if operational tables have data before loading
SELECT 'Cliente table count: ', COUNT(*) FROM Cliente;
SELECT 'Produto table count: ', COUNT(*) FROM Produto;
SELECT 'Fornecedor table count: ', COUNT(*) FROM Fornecedor;
SELECT 'Compra table count: ', COUNT(*) FROM Compra;
SELECT 'Funcionario table count: ', COUNT(*) FROM Funcionario;

-- Load data into Dim_Cliente
INSERT INTO DataWare.Dim_Cliente (Cliente_ID, NomeCompletoCli, CPF_Cli)
SELECT IDCliente, NomeCompletoCli, CPF_Cli
FROM Cliente
ON CONFLICT (Cliente_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Cliente
SELECT 'Dim_Cliente row count after insert: ', COUNT(*) FROM DataWare.Dim_Cliente;
SELECT * FROM DataWare.Dim_Cliente LIMIT 5;

-- Load data into Dim_Endereco
INSERT INTO DataWare.Dim_Endereco (Endereco_ID, LogradouroCli, BairroCli, MunicipioCli, EstadoCli)
SELECT IDCliente AS Endereco_ID, LogradouroCli, BairroCli, MunicipioCli, EstadoCli
FROM Cliente
ON CONFLICT (Endereco_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Endereco
SELECT 'Dim_Endereco row count after insert: ', COUNT(*) FROM DataWare.Dim_Endereco;
SELECT * FROM DataWare.Dim_Endereco LIMIT 5;

-- Load data into Dim_Produto
INSERT INTO DataWare.Dim_Produto (Produto_ID, NomeProd, CategoriaProd, DescricaoProd)
SELECT IDProduto, NomeProd, CategoriaProd, DescricaoProd
FROM Produto
ON CONFLICT (Produto_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Produto
SELECT 'Dim_Produto row count after insert: ', COUNT(*) FROM DataWare.Dim_Produto;
SELECT * FROM DataWare.Dim_Produto LIMIT 5;

-- Load data into Dim_Fornecedor
INSERT INTO DataWare.Dim_Fornecedor (Fornecedor_ID, NomeFor, CNPJ)
SELECT ROW_NUMBER() OVER (ORDER BY CNPJ) AS Fornecedor_ID, NomeFor, CNPJ
FROM Fornecedor
ON CONFLICT (Fornecedor_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Fornecedor
SELECT 'Dim_Fornecedor row count after insert: ', COUNT(*) FROM DataWare.Dim_Fornecedor;
SELECT * FROM DataWare.Dim_Fornecedor LIMIT 5;

-- Load data into Dim_Categoria
INSERT INTO DataWare.Dim_Categoria (Categoria_ID, NomeCategoria)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS Categoria_ID,
    CategoriaProd AS NomeCategoria
FROM Produto
ON CONFLICT (Categoria_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Categoria
SELECT 'Dim_Categoria row count after insert: ', COUNT(*) FROM DataWare.Dim_Categoria;
SELECT * FROM DataWare.Dim_Categoria LIMIT 5;

-- Load data into Dim_Data
INSERT INTO DataWare.Dim_Data (Data_ID, DataCompleta, DiaSemana, Dia, Mes, Trimestre, Ano)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY DataCompleta) AS Data_ID,
    DataCompleta,
    TO_CHAR(DataCompleta, 'Day') AS DiaSemana,
    EXTRACT(DAY FROM DataCompleta) AS Dia,
    EXTRACT(MONTH FROM DataCompleta) AS Mes,
    EXTRACT(QUARTER FROM DataCompleta) AS Trimestre,
    EXTRACT(YEAR FROM DataCompleta) AS Ano
FROM (
    SELECT Data AS DataCompleta FROM Compra
    UNION
    SELECT DFabProd AS DataCompleta FROM Produto
    UNION
    SELECT DValProd AS DataCompleta FROM Produto
    UNION
    SELECT DataValCar AS DataCompleta FROM Cliente
) AS DistinctDates
ON CONFLICT (Data_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Data
SELECT 'Dim_Data row count after insert: ', COUNT(*) FROM DataWare.Dim_Data;
SELECT * FROM DataWare.Dim_Data LIMIT 5;

-- Load data into Dim_Funcionario
INSERT INTO DataWare.Dim_Funcionario (Funcionario_ID, NomeCompFunc, CPFFunc, SalarioFunc, Cargo)
SELECT 
    f.IDFuncionario, 
    f.NomeCompFunc, 
    f.CPFFunc, 
    f.SalarioFunc,
    CASE 
        WHEN g.IDFuncionario IS NOT NULL THEN 'Gerente'
        WHEN a.IDFuncionario IS NOT NULL THEN 'Administrador'
        WHEN s.IDFuncionario IS NOT NULL THEN 'Seguranca'
        WHEN at.IDFuncionario IS NOT NULL THEN 'Atendente'
        ELSE 'Funcionario'
    END AS Cargo
FROM Funcionario f
LEFT JOIN Gerente g ON f.IDFuncionario = g.IDFuncionario
LEFT JOIN Administrador a ON f.IDFuncionario = a.IDFuncionario
LEFT JOIN Seguranca s ON f.IDFuncionario = s.IDFuncionario
LEFT JOIN Atendente at ON f.IDFuncionario = at.IDFuncionario
ON CONFLICT (Funcionario_ID) DO NOTHING;

-- Debugging test: Validate data in Dim_Funcionario
SELECT 'Dim_Funcionario row count after insert: ', COUNT(*) FROM DataWare.Dim_Funcionario;
SELECT * FROM DataWare.Dim_Funcionario LIMIT 5;

-- Load data into Fato_Receita_Detalhada
INSERT INTO DataWare.Fato_Receita_Detalhada (IDFato, Compra_ID, Cliente_ID, Endereco_ID, Produto_ID, Fornecedor_ID, Categoria_ID, Data_ID, Hora, Quantidade, Valor)
SELECT
    ROW_NUMBER() OVER (ORDER BY comp.IDCompra) AS IDFato,
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
FROM Compra comp
JOIN Realiza rea ON comp.IDCompra = rea.IDCompra
JOIN Cliente cli ON rea.IDCliente = cli.IDCliente
JOIN Possui pos ON comp.IDCompra = pos.IDCompra
JOIN Produto prod ON pos.IDProduto = prod.IDProduto AND pos.NumLote = prod.NumLote
JOIN (
    SELECT CNPJ, ROW_NUMBER() OVER (ORDER BY CNPJ) AS Fornecedor_ID FROM Fornecedor
) fornec ON prod.IDProduto = fornec.CNPJ
JOIN (
    SELECT DISTINCT
        CategoriaProd,
        ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS Categoria_ID
    FROM Produto
) cat ON prod.CategoriaProd = cat.CategoriaProd
JOIN (
    SELECT DISTINCT
        DataCompleta,
        ROW_NUMBER() OVER (ORDER BY DataCompleta) AS Data_ID
    FROM (
        SELECT Data AS DataCompleta FROM Compra
        UNION
        SELECT DFabProd AS DataCompleta FROM Produto
        UNION
        SELECT DValProd AS DataCompleta FROM Produto
        UNION
        SELECT DataValCar AS DataCompleta FROM Cliente
    ) AS DistinctDates
) data ON DATE(comp.Data) = data.DataCompleta
ON CONFLICT (IDFato) DO NOTHING;

-- Debugging test: Validate data in Fato_Receita_Detalhada
SELECT 'Fato_Receita_Detalhada row count after insert: ', COUNT(*) FROM DataWare.Fato_Receita_Detalhada;
SELECT * FROM DataWare.Fato_Receita_Detalhada LIMIT 5;

-- Load data into Fato_Receita_Agregada
INSERT INTO DataWare.Fato_Receita_Agregada (IDFato, Cliente_ID, Endereco_ID, Produto_ID, Fornecedor_ID, Categoria_ID, Data_ID, Valor_Agregado)
SELECT
    ROW_NUMBER() OVER (ORDER BY cli.IDCliente) AS IDFato,
    cli.IDCliente,
    cli.IDCliente AS Endereco_ID,
    prod.IDProduto,
    fornec.Fornecedor_ID,
    cat.Categoria_ID,
    data.Data_ID,
    SUM(pos.QtdCompra * prod.ValorVenda) AS Valor_Agregado
FROM Compra comp
JOIN Realiza rea ON comp.IDCompra = rea.IDCompra
JOIN Cliente cli ON rea.IDCliente = cli.IDCliente
JOIN Possui pos ON comp.IDCompra = pos.IDCompra
JOIN Produto prod ON pos.IDProduto = prod.IDProduto AND pos.NumLote = prod.NumLote
JOIN (
    SELECT CNPJ, ROW_NUMBER() OVER (ORDER BY CNPJ) AS Fornecedor_ID FROM Fornecedor
) fornec ON prod.IDProduto = fornec.CNPJ
JOIN (
    SELECT DISTINCT
        CategoriaProd,
        ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS Categoria_ID
    FROM Produto
) cat ON prod.CategoriaProd = cat.CategoriaProd
JOIN (
    SELECT DISTINCT
        DataCompleta,
        ROW_NUMBER() OVER (ORDER BY DataCompleta) AS Data_ID
    FROM (
        SELECT Data AS DataCompleta FROM Compra
        UNION
        SELECT DFabProd AS DataCompleta FROM Produto
        UNION
        SELECT DValProd AS DataCompleta FROM Produto
        UNION
        SELECT DataValCar AS DataCompleta FROM Cliente
    ) AS DistinctDates
) data ON DATE(comp.Data) = data.DataCompleta
GROUP BY cli.IDCliente, cli.IDCliente, prod.IDProduto, fornec.Fornecedor_ID, cat.Categoria_ID, data.Data_ID
ON CONFLICT (IDFato) DO NOTHING;

-- Debugging test: Validate data in Fato_Receita_Agregada
SELECT 'Fato_Receita_Agregada row count after insert: ', COUNT(*) FROM DataWare.Fato_Receita_Agregada;
SELECT * FROM DataWare.Fato_Receita_Agregada LIMIT 5;

-- Final validation queries to ensure data integrity

-- Check the number of rows in each dimension table
SELECT 'Dim_Cliente row count: ', COUNT(*) FROM DataWare.Dim_Cliente;
SELECT 'Dim_Endereco row count: ', COUNT(*) FROM DataWare.Dim_Endereco;
SELECT 'Dim_Produto row count: ', COUNT(*) FROM DataWare.Dim_Produto;
SELECT 'Dim_Fornecedor row count: ', COUNT(*) FROM DataWare.Dim_Fornecedor;
SELECT 'Dim_Categoria row count: ', COUNT(*) FROM DataWare.Dim_Categoria;
SELECT 'Dim_Data row count: ', COUNT(*) FROM DataWare.Dim_Data;
SELECT 'Dim_Funcionario row count: ', COUNT(*) FROM DataWare.Dim_Funcionario;

-- Check the number of rows in each fact table
SELECT 'Fato_Receita_Detalhada row count: ', COUNT(*) FROM DataWare.Fato_Receita_Detalhada;
SELECT 'Fato_Receita_Agregada row count: ', COUNT(*) FROM DataWare.Fato_Receita_Agregada;

-- Validate sample data in fact tables
SELECT * FROM DataWare.Fato_Receita_Detalhada LIMIT 10;
SELECT * FROM DataWare.Fato_Receita_Agregada LIMIT 10;
