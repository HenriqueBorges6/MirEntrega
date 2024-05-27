-- Iniciando uma transação
BEGIN;

-- Inserindo produtos
INSERT INTO Produto (IDProduto, NumLote, NomeProd, CategoriaProd, DescricaoProd, DFabProd, DValProd, ValorVenda)
VALUES 
(1, 1, 'Produto A', 'Categoria X', 'Descrição do Produto A', '2023-01-01', '2024-01-01', 100.0),
(2, 2, 'Produto B', 'Categoria Y', 'Descrição do Produto B', '2023-02-01', '2024-02-01', 150.0),
(3, 3, 'Produto C', 'Categoria Z', 'Descrição do Produto C', '2023-03-01', '2024-03-01', 200.0),
(4, 4, 'Produto D', 'Categoria W', 'Descrição do Produto D', '2023-04-01', '2024-04-01', 250.0),
(5, 5, 'Produto E', 'Categoria X', 'Descrição do Produto E', '2023-05-01', '2024-05-01', 300.0),
(6, 6, 'Produto F', 'Categoria Y', 'Descrição do Produto F', '2023-06-01', '2024-06-01', 350.0),
(7, 7, 'Produto G', 'Categoria Z', 'Descrição do Produto G', '2023-07-01', '2024-07-01', 400.0),
(8, 8, 'Produto H', 'Categoria W', 'Descrição do Produto H', '2023-08-01', '2024-08-01', 450.0),
(9, 9, 'Produto I', 'Categoria X', 'Descrição do Produto I', '2023-09-01', '2024-09-01', 500.0),
(10, 10, 'Produto J', 'Categoria Y', 'Descrição do Produto J', '2023-10-01', '2024-10-01', 550.0);

-- Inserindo clientes
INSERT INTO Cliente (IDCliente, NomeCompletoCli, LogradouroCli, BairroCli, MunicipioCli, EstadoCli, CPF_Cli, NumCartao, DataValCar, CVC, NomeCar)
VALUES 
(1, 'João Silva', 'Rua A', 'Bairro B', 'Cidade C', 'Estado D', 12345678901, 1234567812345678, '2025-01-01', 123, 'João Silva'),
(2, 'Maria Souza', 'Rua B', 'Bairro C', 'Cidade D', 'Estado E', 23456789012, 2345678923456789, '2025-02-01', 456, 'Maria Souza'),
(3, 'Pedro Lima', 'Rua C', 'Bairro D', 'Cidade E', 'Estado F', 34567890123, 3456789034567890, '2025-03-01', 789, 'Pedro Lima'),
(4, 'Ana Paula', 'Rua D', 'Bairro E', 'Cidade F', 'Estado G', 45678901234, 4567890145678901, '2025-04-01', 321, 'Ana Paula'),
(5, 'Carlos Alberto', 'Rua E', 'Bairro F', 'Cidade G', 'Estado H', 56789012345, 5678901256789012, '2025-05-01', 654, 'Carlos Alberto'),
(6, 'Luiza Fernandes', 'Rua F', 'Bairro G', 'Cidade H', 'Estado I', 67890123456, 6789012367890123, '2025-06-01', 987, 'Luiza Fernandes'),
(7, 'Rafael Gomes', 'Rua G', 'Bairro H', 'Cidade I', 'Estado J', 78901234567, 7890123478901234, '2025-07-01', 213, 'Rafael Gomes'),
(8, 'Fernanda Costa', 'Rua H', 'Bairro I', 'Cidade J', 'Estado K', 89012345678, 8901234589012345, '2025-08-01', 546, 'Fernanda Costa'),
(9, 'Juliana Martins', 'Rua I', 'Bairro J', 'Cidade K', 'Estado L', 90123456789, 9012345690123456, '2025-09-01', 879, 'Juliana Martins'),
(10, 'Marcelo Ribeiro', 'Rua J', 'Bairro K', 'Cidade L', 'Estado M', 12345678012, 1234567812345678, '2025-10-01', 987, 'Marcelo Ribeiro');

-- Inserindo funcionários
INSERT INTO Funcionario (IDFuncionario, NomeCompFunc, CPFFunc, SalarioFunc)
VALUES 
(1, 'Carlos Lima', 45678901234, 3000.0),
(2, 'Ana Santos', 56789012345, 3500.0),
(3, 'Paulo Oliveira', 67890123456, 4000.0),
(4, 'Lucas Silva', 78901234567, 4500.0),
(5, 'Carla Mendes', 89012345678, 5000.0),
(6, 'Fernanda Araujo', 90123456789, 5500.0),
(7, 'Roberto Costa', 12345678901, 6000.0),
(8, 'Mariana Duarte', 23456789012, 6500.0),
(9, 'Gabriel Souza', 34567890123, 7000.0),
(10, 'Laura Barbosa', 12345678012, 7500.0);

-- Inserindo compras
INSERT INTO Compra (IDCompra, Data)
VALUES 
(1, '2024-01-01 10:00:00'),
(2, '2024-01-02 11:00:00'),
(3, '2024-01-03 12:00:00'),
(4, '2024-01-04 13:00:00'),
(5, '2024-01-05 14:00:00'),
(6, '2024-01-06 15:00:00'),
(7, '2024-01-07 16:00:00'),
(8, '2024-01-08 17:00:00'),
(9, '2024-01-09 18:00:00'),
(10, '2024-01-10 19:00:00');

-- Inserindo fornecedores
INSERT INTO Fornecedor (CNPJ, NomeFor)
VALUES 
(12345678000101, 'Fornecedor A'),
(23456789000102, 'Fornecedor B'),
(34567890000103, 'Fornecedor C'),
(45678901234504, 'Fornecedor D'),
(56789012345605, 'Fornecedor E');

-- Inserindo entradas no portal de validação
INSERT INTO Portal (IDValidacao)
VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10);

COMMIT;

BEGIN;

-- Inserindo gerentes
INSERT INTO Gerente (IDFuncionario)
VALUES (1), (2), (3), (4), (5)
ON CONFLICT (IDFuncionario) DO NOTHING;

-- Inserindo administradores
INSERT INTO Administrador (IDFuncionario)
VALUES (6), (7), (8), (9), (10)
ON CONFLICT (IDFuncionario) DO NOTHING;

-- Inserindo segurança
INSERT INTO Seguranca (IDFuncionario)
VALUES (1), (2), (3), (4), (5)
ON CONFLICT (IDFuncionario) DO NOTHING;

-- Inserindo atendentes
INSERT INTO Atendente (IDFuncionario)
VALUES (6), (7), (8), (9), (10)
ON CONFLICT (IDFuncionario) DO NOTHING;

COMMIT;

BEGIN;

-- Associando produtos a compras (Possui)
INSERT INTO Possui (QtdCompra, IDCompra, IDProduto, NumLote)
VALUES 
(10, 1, 1, 1),
(5, 1, 2, 2),
(2, 2, 1, 1),
(7, 3, 3, 3),
(1, 4, 4, 4),
(15, 5, 5, 5),
(20, 6, 6, 6),
(25, 7, 7, 7),
(30, 8, 8, 8),
(35, 9, 9, 9),
(40, 10, 10, 10);

-- Associando produtos a fornecedores (Fornece)
INSERT INTO Fornece (QtdFornecida, ValorCompra, CNPJ, IDProduto, NumLote)
VALUES 
(100, 1000.0, 12345678000101, 1, 1),
(200, 1500.0, 23456789000102, 2, 2),
(300, 2000.0, 34567890000103, 3, 3),
(400, 2500.0, 45678901234504, 4, 4),
(500, 3000.0, 56789012345605, 5, 5),
(600, 3500.0, 12345678000101, 6, 6),
(700, 4000.0, 23456789000102, 7, 7),
(800, 4500.0, 34567890000103, 8, 8),
(900, 5000.0, 45678901234504, 9, 9),
(1000, 5500.0, 56789012345605, 10, 10);

-- Associando funcionários a fornecedores (Contata)
INSERT INTO Contata (IDFuncionario, CNPJ)
VALUES 
(6, 12345678000101),
(7, 23456789000102),
(8, 34567890000103),
(9, 45678901234504),
(10, 56789012345605);

-- Associando compras a funcionários (Auxilia)
INSERT INTO Auxilia (IDCompra, IDFuncionario)
VALUES 
(1, 6),
(2, 7),
(3, 8),
(4, 9),
(5, 10),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- Associando produtos a validações (Reconhece)
INSERT INTO Reconhece (IDProduto, NumLote, IDValidacao)
VALUES 
(1, 1, 1),
(2, 2, 2),
(3, 3, 3),
(4, 4, 4),
(5, 5, 5),
(6, 6, 6),
(7, 7, 7),
(8, 8, 8),
(9, 9, 9),
(10, 10, 10);

-- Associando validações a compras (Valida)
INSERT INTO Valida (IDValidacao, IDCompra)
VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- Associando compras a clientes (Realiza)
INSERT INTO Realiza (IDCompra, IDCliente)
VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

COMMIT;
