DROP SCHEMA IF EXISTS DataWare CASCADE;
CREATE SCHEMA DataWare;
SET search_path = DataWare;

CREATE TABLE Cliente
(
  IDCliente INT NOT NULL,
  NomeCompletoCli VARCHAR(255),
  CPF_Cli INT,
  PRIMARY KEY (IDCliente)
);

CREATE TABLE Produto
(
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  NomeProd VARCHAR(255),
  ValorProd FLOAT NOT NULL,
  PRIMARY KEY (IDProduto, NumLote)
);

CREATE TABLE EnderecoCliente
(
  LogradouroCli VARCHAR(255),
  BairroCli VARCHAR(255),
  EstadoCli VARCHAR(255),
  MunicipioCli VARCHAR(255),
  IDEnderecoCliente INT NOT NULL,
  PRIMARY KEY (IDEnderecoCliente)
);

CREATE TABLE Fornecedor
(
  CNPJ INT NOT NULL,
  NomeFor VARCHAR(255),
  PRIMARY KEY (CNPJ)
);

CREATE TABLE Calendario
(
  Data DATE NOT NULL,
  DiaSemana VARCHAR(20),
  Mes INT NOT NULL,
  Trimestre INT NOT NULL,
  Ano INT NOT NULL,
  PRIMARY KEY (Data)
);

CREATE TABLE CategoriaProduto
(
  IDCategoria INT NOT NULL,
  CategoriaProd VARCHAR(255),
  PRIMARY KEY (IDCategoria)
);

CREATE TABLE ReceitaDetalhada
(
  ValorCompra INT NOT NULL,
  QuantidadeProd INT NOT NULL,
  IDCliente INT NOT NULL,
  IDEnderecoCliente INT NOT NULL,
  CNPJ INT NOT NULL,
  Data DATE NOT NULL,
  IDCompra INT NOT NULL,
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  IDCategoria INT NOT NULL,
  Quantidade INT NOT NULL,
  PRIMARY KEY (IDCompra),
  FOREIGN KEY (IDCliente) REFERENCES Cliente(IDCliente),
  FOREIGN KEY (IDEnderecoCliente) REFERENCES EnderecoCliente(IDEnderecoCliente),
  FOREIGN KEY (CNPJ) REFERENCES Fornecedor(CNPJ),
  FOREIGN KEY (Data) REFERENCES Calendario(Data),
  FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote),
  FOREIGN KEY (IDCategoria) REFERENCES CategoriaProduto(IDCategoria)
);

CREATE TABLE ReceitaAgregada (
    IDCliente INT NOT NULL,
    IDEnderecoCliente INT NOT NULL,
    IDProduto INT NOT NULL,
    CNPJ INT NOT NULL,
    IDCategoria INT NOT NULL,
    Data DATE NOT NULL,
    ValorAgregado FLOAT,
    IDFato INT PRIMARY KEY
);
