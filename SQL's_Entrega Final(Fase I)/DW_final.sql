DROP SCHEMA IF EXISTS DataWare CASCADE;
CREATE SCHEMA DataWare;
SET search_path = DataWare;

-- Cliente Table
CREATE TABLE Cliente
(
  IDCliente INT NOT NULL,
  NomeCompletoCli VARCHAR(255),
  CPF_Cli NUMERIC(11,0),
  IDEnderecoCliente INT NOT NULL,
  PRIMARY KEY (IDCliente)
);

-- Produto Table
CREATE TABLE Produto
(
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  NomeProd VARCHAR(255),
  ValorProd REAL NOT NULL,
  IDCategoria INT NOT NULL,
  PRIMARY KEY (IDProduto, NumLote)
);

-- EnderecoCliente Table
CREATE TABLE EnderecoCliente
(
  IDEnderecoCliente SERIAL NOT NULL,
  LogradouroCli VARCHAR(255),
  BairroCli VARCHAR(255),
  MunicipioCli VARCHAR(255),
  EstadoCli VARCHAR(255),
  PRIMARY KEY (IDEnderecoCliente)
);

-- Fornecedor Table
CREATE TABLE Fornecedor
(
  CNPJ NUMERIC(14,0) NOT NULL,
  NomeFor VARCHAR(255),
  PRIMARY KEY (CNPJ)
);

-- Calendario Table
CREATE TABLE Calendario
(
  Data DATE NOT NULL,
  DiaSemana VARCHAR(20),
  Mes INT NOT NULL,
  Trimestre INT NOT NULL,
  Ano INT NOT NULL,
  PRIMARY KEY (Data)
);

-- CategoriaProduto Table
CREATE TABLE CategoriaProduto
(
  IDCategoria SERIAL NOT NULL,
  CategoriaProd VARCHAR(255),
  PRIMARY KEY (IDCategoria)
);

-- ReceitaDetalhada Fact Table
CREATE TABLE ReceitaDetalhada
(
  IDCompra INT NOT NULL,
  IDCliente INT NOT NULL,
  IDEnderecoCliente INT NOT NULL,
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  CNPJ NUMERIC(14,0) NOT NULL,
  IDCategoria INT NOT NULL,
  Data DATE NOT NULL,
  QuantidadeProd INT NOT NULL,
  ValorCompra REAL NOT NULL,
  PRIMARY KEY (IDCompra),
  FOREIGN KEY (IDCliente) REFERENCES Cliente(IDCliente),
  FOREIGN KEY (IDEnderecoCliente) REFERENCES EnderecoCliente(IDEnderecoCliente),
  FOREIGN KEY (CNPJ) REFERENCES Fornecedor(CNPJ),
  FOREIGN KEY (Data) REFERENCES Calendario(Data),
  FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote),
  FOREIGN KEY (IDCategoria) REFERENCES CategoriaProduto(IDCategoria)
);

-- ReceitaAgregada Fact Table
CREATE TABLE ReceitaAgregada (
    IDCliente INT NOT NULL,
    IDEnderecoCliente INT NOT NULL,
    IDProduto INT NOT NULL,
    NumLote INT NOT NULL,
    CNPJ NUMERIC(14,0) NOT NULL,
    IDCategoria INT NOT NULL,
    Data DATE NOT NULL,
    ValorAgregado REAL,
    IDFato SERIAL PRIMARY KEY,
    FOREIGN KEY (IDCliente) REFERENCES Cliente(IDCliente),
    FOREIGN KEY (IDEnderecoCliente) REFERENCES EnderecoCliente(IDEnderecoCliente),
    FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote),
    FOREIGN KEY (CNPJ) REFERENCES Fornecedor(CNPJ),
    FOREIGN KEY (IDCategoria) REFERENCES CategoriaProduto(IDCategoria),
    FOREIGN KEY (Data) REFERENCES Calendario(Data)
);
