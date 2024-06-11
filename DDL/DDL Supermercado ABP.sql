CREATE SCHEMA trabalho;
SET SEARCH_PATH = trabalho;

CREATE TABLE Produto
(
  IDProduto SERIAL NOT NULL,
  NumLote INT NOT NULL,
  NomeProd VARCHAR(255) NOT NULL,
  CategoriaProd VARCHAR(255) NOT NULL,
  DescricaoProd VARCHAR(800) NOT NULL,
  DFabProd DATE NOT NULL,
  DValProd DATE NOT NULL,
  ValorVenda REAL NOT NULL,
  PRIMARY KEY (IDProduto, NumLote)
);

CREATE TABLE Cliente
(
  IDCliente SERIAL NOT NULL,
  NomeCompletoCli VARCHAR(255) NOT NULL,
  LogradouroCli VARCHAR(255) NOT NULL,
  BairroCli VARCHAR(255) NOT NULL,
  MunicipioCli VARCHAR(255) NOT NULL,
  EstadoCli VARCHAR(255) NOT NULL,
  CPF_Cli NUMERIC(11,0) NOT NULL,
  NumCartao NUMERIC(16,0) NOT NULL,
  DataValCar DATE NOT NULL,
  CVC NUMERIC(3,0) NOT NULL,
  NomeCar VARCHAR(255) NOT NULL,
  PRIMARY KEY (IDCliente),
  UNIQUE (CPF_Cli)
);

CREATE TABLE Funcionario
(
  IDFuncionario SERIAL NOT NULL,
  NomeCompFunc VARCHAR(255) NOT NULL,
  CPFFunc NUMERIC(11,0) NOT NULL,
  SalarioFunc REAL NOT NULL,
  PRIMARY KEY (IDFuncionario),
  UNIQUE (CPFFunc)
);

CREATE TABLE Compra
(
  IDCompra SERIAL NOT NULL,
  Data TIMESTAMP NOT NULL,
  PRIMARY KEY (IDCompra)
);

CREATE TABLE Gerente
(
  IDFuncionario INT NOT NULL,
  PRIMARY KEY (IDFuncionario),
  FOREIGN KEY (IDFuncionario) REFERENCES Funcionario(IDFuncionario)
);

CREATE TABLE Administrador
(
  IDFuncionario INT NOT NULL,
  PRIMARY KEY (IDFuncionario),
  FOREIGN KEY (IDFuncionario) REFERENCES Funcionario(IDFuncionario)
);

CREATE TABLE Seguranca
(
  IDFuncionario INT NOT NULL,
  PRIMARY KEY (IDFuncionario),
  FOREIGN KEY (IDFuncionario) REFERENCES Funcionario(IDFuncionario)
);

CREATE TABLE Fornecedor
(
  CNPJ NUMERIC(14,0) NOT NULL,
  NomeFor VARCHAR(255) NOT NULL,
  PRIMARY KEY (CNPJ)
);

CREATE TABLE Atendente
(
  IDFuncionario INT NOT NULL,
  PRIMARY KEY (IDFuncionario),
  FOREIGN KEY (IDFuncionario) REFERENCES Funcionario(IDFuncionario)
);

CREATE TABLE Portal
(
  IDValidacao SERIAL NOT NULL,
  PRIMARY KEY (IDValidacao)
);

CREATE TABLE Possui
(
  QtdCompra INT NOT NULL,
  IDCompra INT NOT NULL,
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  PRIMARY KEY (IDCompra, IDProduto, NumLote),
  FOREIGN KEY (IDCompra) REFERENCES Compra(IDCompra),
  FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote)
);

CREATE TABLE Fornece
(
  QtdFornecida INT NOT NULL,
  ValorCompra REAL NOT NULL,
  CNPJ NUMERIC(14,0) NOT NULL,
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  PRIMARY KEY (CNPJ, IDProduto, NumLote),
  FOREIGN KEY (CNPJ) REFERENCES Fornecedor(CNPJ),
  FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote)
);

CREATE TABLE Contata
(
  IDFuncionario INT NOT NULL,
  CNPJ NUMERIC(14,0) NOT NULL,
  PRIMARY KEY (IDFuncionario, CNPJ),
  FOREIGN KEY (IDFuncionario) REFERENCES Administrador(IDFuncionario),
  FOREIGN KEY (CNPJ) REFERENCES Fornecedor(CNPJ)
);

CREATE TABLE Auxilia
(
  IDCompra INT NOT NULL,
  IDFuncionario INT NOT NULL,
  PRIMARY KEY (IDCompra, IDFuncionario),
  FOREIGN KEY (IDCompra) REFERENCES Compra(IDCompra),
  FOREIGN KEY (IDFuncionario) REFERENCES Atendente(IDFuncionario)
);

CREATE TABLE Reconhece
(
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  IDValidacao INT NOT NULL,
  PRIMARY KEY (IDProduto, NumLote, IDValidacao),
  FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote),
  FOREIGN KEY (IDValidacao) REFERENCES Portal(IDValidacao)
);

CREATE TABLE Valida
(
  IDValidacao INT NOT NULL,
  IDCompra INT NOT NULL,
  PRIMARY KEY (IDValidacao, IDCompra),
  FOREIGN KEY (IDValidacao) REFERENCES Portal(IDValidacao),
  FOREIGN KEY (IDCompra) REFERENCES Compra(IDCompra)
);

CREATE TABLE Realiza
(
  IDCompra INT NOT NULL,
  IDCliente INT NOT NULL,
  PRIMARY KEY (IDCompra, IDCliente),
  FOREIGN KEY (IDCompra) REFERENCES Compra(IDCompra),
  FOREIGN KEY (IDCliente) REFERENCES Cliente(IDCliente)
);

ALTER TABLE Produto
ADD COLUMN DemandaTendencia VARCHAR(255);
