CREATE DATABASE InsightTrip;
USE InsightTrip;

-- create user 'API'@'localhost' identified by 'webDataViz0API'; --
-- grant insert, select, update on InsightTrip.* to 'API'@'localhost'; --
show grants for 'API'@'localhost';

CREATE TABLE Funcionario (
    idFuncionario INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(45),
    CPF CHAR(14),
    Email VARCHAR(256),
    Senha VARCHAR(45),
    Telefone VARCHAR(14),
    Setor VARCHAR(45),
    fkAdministrador INT,
    CONSTRAINT fkFuncionario FOREIGN KEY (fkAdministrador) 
        REFERENCES Funcionario(idFuncionario)
);

CREATE TABLE Agencia (
    idAgencia INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(45),
    CNPJ CHAR(14), 
    Endereco VARCHAR(45),
    CEP VARCHAR(8), 
    fkAdministrador INT,
    CONSTRAINT fkAdministradorAgencia FOREIGN KEY (fkAdministrador) 
        REFERENCES Funcionario(idFuncionario)
);

CREATE TABLE Pais (
    idPais INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(45),
    Continente VARCHAR(45)
);

CREATE TABLE UF ( 
    CodigoIBGE INT PRIMARY KEY,
    Nome VARCHAR(45),
    Regiao VARCHAR(45)
);

CREATE TABLE Crime (
    idCrime INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(45),
    qtdOcorrencia INT,
    Data DATE,
    fkEstado INT,
    CONSTRAINT fkEstadoCriminalidade FOREIGN KEY (fkEstado) 
        REFERENCES UF(CodigoIBGE) 
);

CREATE TABLE Evento (
    idEvento INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(45),
    DataInicio DATE,
    DataFim DATE
);

CREATE TABLE EstadoHasEvento (
    idEventoEstado INT PRIMARY KEY AUTO_INCREMENT,
    fkEstado INT,
    CONSTRAINT fkEstadoEventos FOREIGN KEY (fkEstado) 
        REFERENCES UF(CodigoIBGE),
    fkEvento INT,
    CONSTRAINT fkEventosEstado FOREIGN KEY (fkEvento) 
        REFERENCES Evento(idEvento)
);

CREATE TABLE Aeroporto (
    idAeroporto INT PRIMARY KEY AUTO_INCREMENT,
    NomeAeroporto VARCHAR(75),
    fkEstado INT,
    fkPais INT,
    CONSTRAINT fkEstadoAeroportos FOREIGN KEY (fkEstado) 
        REFERENCES UF(CodigoIBGE),
	CONSTRAINT fkPaisAeroportos FOREIGN KEY (fkPais) 
        REFERENCES Pais(idPais)
);

CREATE TABLE Viagem (
    idPassagem INT PRIMARY KEY AUTO_INCREMENT,
    dtViagem DATE,
    fkAeroportoOrigem INT, 
    fkAeroportoDestino INT,
    QtdPassageirosPagos INT,
    QtdPassageirosGratis INT,
    CONSTRAINT fkAeroportoOrigem FOREIGN KEY (fkAeroportoOrigem) 
        REFERENCES Aeroporto(idAeroporto),
    CONSTRAINT fkAeroportoDestino FOREIGN KEY (fkAeroportoDestino) 
        REFERENCES Aeroporto(idAeroporto)
);

SELECT idAeroporto, nomeAeroporto, UF.Nome AS NomeUF, Pais.Nome AS NomePais
FROM aeroporto
JOIN Pais ON idPais = fkPais
LEFT JOIN UF ON CodigoIBGE = fkEstado
ORDER BY Pais.Nome;

SELECT idPassagem, dtViagem AS 'Data', 
AeroportoOrigem.NomeAeroporto AS 'Aeroporto Origem', PaisOrigem.Nome AS 'País Origem', UFOrigem.Nome AS 'Estado Origem', 
AeroportoDestino.NomeAeroporto AS 'Aeroporto Destino', PaisDestino.Nome AS 'País Destino', UFDestino.Nome AS 'Estado Destino', 
QtdPassageirosPagos AS 'Passageiros Pagos', QtdPassageirosGratis AS 'Passageiros Grátis' FROM Viagem
JOIN Aeroporto AS AeroportoOrigem ON fkAeroportoOrigem = AeroportoOrigem.idAeroporto
JOIN Aeroporto AS AeroportoDestino ON fkAeroportoDestino = AeroportoDestino.idAeroporto
JOIN Pais AS PaisOrigem ON AeroportoOrigem.fkPais = PaisOrigem.IdPais
JOIN Pais AS PaisDestino ON AeroportoDestino.fkPais = PaisDestino.IdPais
LEFT JOIN UF AS UFOrigem ON AeroportoOrigem.fkEstado = UFOrigem.CodigoIBGE
JOIN UF AS UFDestino ON AeroportoDestino.fkEstado = UFDestino.CodigoIBGE
ORDER BY dtViagem LIMIT 100000;

SELECT UF.Nome as 'Estado', Evento.Nome as 'Evento', DataInicio as 'Data início', DataFim as 'Data fim'FROM EstadoHasEvento
JOIN UF ON CodigoIBGE = fkEstado
JOIN Evento ON idEvento = fkEvento
ORDER BY UF.Nome LIMIT 1000000;

SELECT UF.Nome, Crime.Nome, qtdOcorrencia, data FROM Crime
JOIN UF ON fkEstado = CodigoIBGE
ORDER BY UF.Nome LIMIT 1000000;


SELECT
    UF.Nome AS NomeUF,
    Evento.Nome AS NomeEvento,

    -- Calcula a porcentagem de crimes durante o evento em relação ao total de crimes no UF, arredondando para duas casas decimais
    ROUND(
        COALESCE(
            (SELECT SUM(C.qtdOcorrencia)
             FROM Crime C
             WHERE C.fkEstado = UF.CodigoIBGE
               AND C.Data BETWEEN Evento.DataInicio AND Evento.DataFim
            ), 0
        ) * 1.0 / 
        COALESCE(
            (SELECT SUM(C2.qtdOcorrencia)
             FROM Crime C2
             WHERE C2.fkEstado = UF.CodigoIBGE
            ), 1
        ) * 100, 
    2) AS PorcentagemCrimes,

    -- Conta o total de viagens com destino ao UF durante o evento
    COALESCE(
        (SELECT COUNT(V.idPassagem)
         FROM Viagem V
         JOIN Aeroporto A ON V.fkAeroportoDestino = A.idAeroporto
         WHERE A.fkEstado = UF.CodigoIBGE
           AND V.dtViagem BETWEEN Evento.DataInicio AND Evento.DataFim
        ), 0
    ) AS TotalViagensDestino

FROM
    UF
JOIN
    EstadoHasEvento EHE ON UF.CodigoIBGE = EHE.fkEstado
JOIN
    Evento ON EHE.fkEvento = Evento.idEvento
WHERE 
    Evento.Nome = 'Carnaval'
ORDER BY
    UF.Nome,
    Evento.Nome;
    
-- DROP USER 'API'@'localhost'; --
-- DROP DATABASE InsightTrip--