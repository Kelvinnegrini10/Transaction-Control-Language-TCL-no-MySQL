-- Estrutura expandida das tabelas
CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY,
    nome VARCHAR(100),
    saldo DECIMAL(10,2),
    limite_credito DECIMAL(10,2),
    status VARCHAR(20)
);

CREATE TABLE pedidos (
    id_pedido INT PRIMARY KEY,
    id_cliente INT,
    valor DECIMAL(10,2),
    status VARCHAR(20),
    data_pedido TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE itens_pedido (
    id_item INT PRIMARY KEY,
    id_pedido INT,
    id_produto INT,
    quantidade INT,
    valor_unitario DECIMAL(10,2),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

CREATE TABLE estoque (
    id_produto INT PRIMARY KEY,
    quantidade INT,
    reservado INT
);

-- Transação completa de pedido
DELIMITER $$
CREATE PROCEDURE criar_pedido(
    IN p_cliente_id INT,
    IN p_produto_id INT,
    IN p_quantidade INT
)
BEGIN
    DECLARE v_valor_total DECIMAL(10,2);
    DECLARE v_estoque_disponivel INT;
    
    START TRANSACTION;
    
    -- Verificar estoque
    SELECT quantidade - reservado INTO v_estoque_disponivel
    FROM estoque WHERE id_produto = p_produto_id FOR UPDATE;
    
    IF v_estoque_disponivel >= p_quantidade THEN
        -- Criar pedido
        INSERT INTO pedidos (id_cliente, valor, status, data_pedido)
        VALUES (p_cliente_id, v_valor_total, 'PENDENTE', NOW());
        
        SET @id_pedido = LAST_INSERT_ID();
        
        -- Reservar estoque
        UPDATE estoque 
        SET reservado = reservado + p_quantidade
        WHERE id_produto = p_produto_id;
        
        -- Inserir itens do pedido
        INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, valor_unitario)
        VALUES (@id_pedido, p_produto_id, p_quantidade, 
                (SELECT preco FROM produtos WHERE id_produto = p_produto_id));
        
        COMMIT;
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente';
    END IF;
END $$
DELIMITER ;