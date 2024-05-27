-- Set schema for the data warehouse
SET search_path = DataWare;

-- Truncate all tables to ensure a clean load
TRUNCATE TABLE ReceitaDetalhada CASCADE;
TRUNCATE TABLE ReceitaAgregada CASCADE;
TRUNCATE TABLE Cliente CASCADE;
TRUNCATE TABLE EnderecoCliente CASCADE;
TRUNCATE TABLE Produto CASCADE;
TRUNCATE TABLE Fornecedor CASCADE;
TRUNCATE TABLE CategoriaProduto CASCADE;
TRUNCATE TABLE Calendario CASCADE;

-- Set schema for the operational database
SET search_path = trabalho;

-- Debugging test: Check if operational tables have data before loading
SELECT 'Cliente table count: ', COUNT(*) FROM Cliente;
SELECT 'Produto table count: ', COUNT(*) FROM Produto;
SELECT 'Fornecedor table count: ', COUNT(*) FROM Fornecedor;
SELECT 'Compra table count: ', COUNT(*) FROM Compra;
SELECT 'Funcionario table count: ', COUNT(*) FROM Funcionario;

-- Load data into Cliente Dimension
INSERT INTO DataWare.Cliente (IDCliente, NomeCompletoCli, CPF_Cli, IDEnderecoCliente)
SELECT 
    IDCliente, 
    NomeCompletoCli, 
    CPF_Cli,
    IDCliente AS IDEnderecoCliente  -- Temporary mapping, to be adjusted later
FROM Cliente
ON CONFLICT (IDCliente) DO NOTHING;

-- Load data into EnderecoCliente Dimension
INSERT INTO DataWare.EnderecoCliente (IDEnderecoCliente, LogradouroCli, BairroCli, MunicipioCli, EstadoCli)
SELECT 
    IDCliente AS IDEnderecoCliente,
    LogradouroCli, 
    BairroCli, 
    MunicipioCli, 
    EstadoCli
FROM Cliente
ON CONFLICT (IDEnderecoCliente) DO NOTHING;

-- Load data into Produto Dimension
INSERT INTO DataWare.Produto (IDProduto, NumLote, NomeProd, ValorProd, IDCategoria)
SELECT 
    p.IDProduto, 
    p.NumLote, 
    p.NomeProd, 
    p.ValorVenda, 
    c.IDCategoria
FROM Produto p
JOIN (
    SELECT DISTINCT CategoriaProd, ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria
    FROM Produto
) c ON p.CategoriaProd = c.CategoriaProd
ON CONFLICT (IDProduto, NumLote) DO NOTHING;

-- Load data into Fornecedor Dimension
INSERT INTO DataWare.Fornecedor (CNPJ, NomeFor)
SELECT 
    CNPJ, 
    NomeFor 
FROM Fornecedor
ON CONFLICT (CNPJ) DO NOTHING;

-- Load data into CategoriaProduto Dimension
INSERT INTO DataWare.CategoriaProduto (IDCategoria, CategoriaProd)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria,
    CategoriaProd
FROM Produto
ON CONFLICT (IDCategoria) DO NOTHING;

-- Load data into Calendario Dimension
INSERT INTO DataWare.Calendario (Data, DiaSemana, Mes, Trimestre, Ano)
SELECT DISTINCT
    DataCompleta AS Data,
    TO_CHAR(DataCompleta, 'Day') AS DiaSemana,
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
ON CONFLICT (Data) DO NOTHING;

-- Load data into ReceitaDetalhada Fact Table
INSERT INTO DataWare.ReceitaDetalhada (IDCompra, IDCliente, IDEnderecoCliente, IDProduto, NumLote, CNPJ, IDCategoria, Data, QuantidadeProd, ValorCompra)
SELECT 
    c.IDCompra,
    r.IDCliente,
    r.IDCliente AS IDEnderecoCliente, -- Assuming EnderecoCliente is the same as Cliente ID
    p.IDProduto,
    p.NumLote,
    f.CNPJ,
    cat.IDCategoria,
    DATE(c.Data) AS Data,
    po.QtdCompra,
    po.QtdCompra * p.ValorVenda AS ValorCompra
FROM Compra c
JOIN Realiza r ON c.IDCompra = r.IDCompra
JOIN Possui po ON c.IDCompra = po.IDCompra
JOIN Produto p ON po.IDProduto = p.IDProduto AND po.NumLote = p.NumLote
JOIN Fornece f ON p.IDProduto = f.IDProduto AND p.NumLote = f.NumLote
JOIN (
    SELECT DISTINCT CategoriaProd, ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria
    FROM Produto
) cat ON p.CategoriaProd = cat.CategoriaProd
ON CONFLICT (IDCompra) DO NOTHING;

-- Load data into ReceitaAgregada Fact Table
INSERT INTO DataWare.ReceitaAgregada (IDCliente, IDEnderecoCliente, IDProduto, NumLote, CNPJ, IDCategoria, Data, ValorAgregado)
SELECT 
    r.IDCliente,
    r.IDCliente AS IDEnderecoCliente, -- Assuming EnderecoCliente is the same as Cliente ID
    p.IDProduto,
    p.NumLote,
    f.CNPJ,
    cat.IDCategoria,
    DATE(c.Data) AS Data,
    SUM(po.QtdCompra * p.ValorVenda) AS ValorAgregado
FROM Compra c
JOIN Realiza r ON c.IDCompra = r.IDCompra
JOIN Possui po ON c.IDCompra = po.IDCompra
JOIN Produto p ON po.IDProduto = p.IDProduto AND po.NumLote = p.NumLote
JOIN Fornece f ON p.IDProduto = f.IDProduto AND p.NumLote = f.NumLote
JOIN (
    SELECT DISTINCT CategoriaProd, ROW_NUMBER() OVER (ORDER BY CategoriaProd) AS IDCategoria
    FROM Produto
) cat ON p.CategoriaProd = cat.CategoriaProd
GROUP BY r.IDCliente, p.IDProduto, p.NumLote, f.CNPJ, cat.IDCategoria, DATE(c.Data)
ON CONFLICT DO NOTHING;

-- Final validation queries to ensure data integrity

-- Check the number of rows in each dimension table
SELECT 'Cliente row count: ', COUNT(*) FROM DataWare.Cliente;
SELECT 'EnderecoCliente row count: ', COUNT(*) FROM DataWare.EnderecoCliente;
SELECT 'Produto row count: ', COUNT(*) FROM DataWare.Produto;
SELECT 'Fornecedor row count: ', COUNT(*) FROM DataWare.Fornecedor;
SELECT 'CategoriaProduto row count: ', COUNT(*) FROM DataWare.CategoriaProduto;
SELECT 'Calendario row count: ', COUNT(*) FROM DataWare.Calendario;

-- Check the number of rows in each fact table
SELECT 'ReceitaDetalhada row count: ', COUNT(*) FROM DataWare.ReceitaDetalhada;
SELECT 'ReceitaAgregada row count: ', COUNT(*) FROM DataWare.ReceitaAgregada;

-- Validate sample data in fact tables
SELECT * FROM DataWare.ReceitaDetalhada LIMIT 10;
SELECT * FROM DataWare.ReceitaAgregada LIMIT 10;

-- Validate sample data in dimension tables
SELECT * FROM DataWare.Cliente LIMIT 10;
SELECT * FROM DataWare.EnderecoCliente LIMIT 10;
SELECT * FROM DataWare.Produto LIMIT 10;
SELECT * FROM DataWare.Fornecedor LIMIT 10;
SELECT * FROM DataWare.CategoriaProduto LIMIT 10;
SELECT * FROM DataWare.Calendario LIMIT 10;
