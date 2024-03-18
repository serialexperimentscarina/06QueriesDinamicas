CREATE DATABASE querydinamica
USE querydinamica

CREATE TABLE produto(
codigo				INT				NOT NULL,
nome				VARCHAR(255)	NOT NULL,
valor				DECIMAL(7, 2)	NOT NULL
PRIMARY KEY (codigo)
)

CREATE TABLE entrada(
codigo_transacao	INT				NOT NULL,
codigo_produto		INT				NOT NULL,
quantidade			INT				NOT NULL,
valor_total			DECIMAL(7, 2)	NOT NULL
PRIMARY KEY (codigo_transacao, codigo_produto),
FOREIGN KEY (codigo_produto) REFERENCES produto (codigo)
)

CREATE TABLE saida(
codigo_transacao	INT				NOT NULL,
codigo_produto		INT				NOT NULL,
quantidade			INT				NOT NULL,
valor_total			DECIMAL(7, 2)	NOT NULL
PRIMARY KEY (codigo_transacao, codigo_produto),
FOREIGN KEY (codigo_produto) REFERENCES produto (codigo)
)

/* Criar uma procedure que receba um código (‘e’ para ENTRADA e ‘s’ para 
SAIDA), criar uma exceção de erro para código inválido, receba o
codigo_transacao, codigo_produto e a quantidade e preencha a tabela correta, 
com o valor_total de cada transação de cada produto. */

CREATE PROCEDURE sp_inseretransacao (@codigo CHAR(1), @codigo_transacao INT,
				@codigo_produto INT, @quantidade INT,
				@saida VARCHAR(200) OUTPUT)
AS
	DECLARE @tabela VARCHAR(10)

	-- Decidir tabela de inserção
	IF (LOWER(@codigo) = 'e')
	BEGIN
		SET @tabela = 'entrada'
	END
	ELSE
	IF (LOWER(@codigo) = 's')
	BEGIN
		SET @tabela = 'saida'
	END
	ELSE
	BEGIN
		RAISERROR('Código inválido', 16, 1)
	END

	IF (@tabela IS NOT NULL)
	BEGIN
		-- Calcular valor_total
		DECLARE @valor_total DECIMAL(7, 2)
		DECLARE @query VARCHAR(200)

		SELECT @valor_total = valor FROM produto WHERE codigo = @codigo_produto
		IF (@valor_total IS NOT NULL AND @quantidade > 0)
		BEGIN
			SET @valor_total = @valor_total * @quantidade

			-- Inserir na tabela
			SET @query = 'INSERT INTO ' + @tabela + ' VALUES (' + 
				CAST(@codigo_transacao AS VARCHAR(5)) + ', ' +
				CAST(@codigo_produto AS varchar(5)) + ', ' +
				CAST(@quantidade AS VARCHAR(5)) + ', ' + 
				CAST(@valor_total AS VARCHAR(10)) + ')'
			BEGIN TRY
				EXEC (@query)
				SET @saida = 'Inserido na tabela ' + @tabela + ' com sucesso!'
			END TRY
			BEGIN CATCH
				DECLARE @erro VARCHAR(100)
				SET @erro = ERROR_MESSAGE()
				IF (@erro LIKE '%primary%')
				BEGIN
					SET @erro = 'Esta transação já possui este produto cadastrado'
				END
				ELSE
				BEGIN
					SET @erro = 'Ocorreu um erro ao inserir esta transação no BD'
				END
				RAISERROR(@erro, 16, 1)
			END CATCH
		END
		ELSE
		BEGIN
			RAISERROR('Produto ou quantidade inválidas', 16, 1)
		END
	END