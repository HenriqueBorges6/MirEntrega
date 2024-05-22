CREATE TABLE Cliente
(
  IDCliente INT NOT NULL,
  PRIMARY KEY (IDCliente)
);

CREATE TABLE Produto
(
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  NomeProd VARCHAR NOT NULL,
  ValorProd FLOAT NOT NULL,
  PRIMARY KEY (IDProduto, NumLote)
);

CREATE TABLE EndereçoCliente
(
  LogradouroCli VARCHAR NOT NULL,
  BairroCli VARCHAR NOT NULL,
  EstadoCli VARCHAR NOT NULL,
  MunicipioCli VARCHAR NOT NULL,
  IDEndereçoCliente INT NOT NULL,
  PRIMARY KEY (IDEndereçoCliente)
);

CREATE TABLE Fornecedor
(
  CNPJ INT NOT NULL,
  NomeFor VARCHAR NOT NULL,
  PRIMARY KEY (CNPJ)
);

CREATE TABLE Calendário
(
  Data DATE NOT NULL,
  DiaSemana INT NOT NULL,
  Mês INT NOT NULL,
  Trimestre INT NOT NULL,
  Ano INT NOT NULL,
  PRIMARY KEY (Data)
);

CREATE TABLE Compra
(
  IDCompra INT NOT NULL,
  PRIMARY KEY (IDCompra)
);

CREATE TABLE CategoriaProduto
(
  IDCategoria INT NOT NULL,
  CategoriaProd INT NOT NULL,
  PRIMARY KEY (IDCategoria)
);

CREATE TABLE Receita
(
  ValorCompra INT NOT NULL,
  QuantidadeProd INT NOT NULL,
  IDCliente INT NOT NULL,
  IDEndereçoCliente INT NOT NULL,
  CNPJ INT NOT NULL,
  Data DATE NOT NULL,
  IDCompra INT NOT NULL,
  IDProduto INT NOT NULL,
  NumLote INT NOT NULL,
  IDCategoria INT NOT NULL,
  PRIMARY KEY (IDCompra),
  FOREIGN KEY (IDCliente) REFERENCES Cliente(IDCliente),
  FOREIGN KEY (IDEndereçoCliente) REFERENCES EndereçoCliente(IDEndereçoCliente),
  FOREIGN KEY (CNPJ) REFERENCES Fornecedor(CNPJ),
  FOREIGN KEY (Data) REFERENCES Calendário(Data),
  FOREIGN KEY (IDCompra) REFERENCES Compra(IDCompra),
  FOREIGN KEY (IDProduto, NumLote) REFERENCES Produto(IDProduto, NumLote),
  FOREIGN KEY (IDCategoria) REFERENCES CategoriaProduto(IDCategoria)
);
