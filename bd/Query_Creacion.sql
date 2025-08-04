-- Creación de Base de Datos --
CREATE SCHEMA `BD_Proyecto_Final_G5`;
USE `BD_Proyecto_Final_G5`;

-- Creación de Tablas --
CREATE TABLE `usuario`
(
    `cod_usuario`    INT AUTO_INCREMENT NOT NULL UNIQUE,
    `nombre_usuario` VARCHAR(50)        NOT NULL UNIQUE,
    `clave`          VARCHAR(255)       NOT NULL,
    `correo`         VARCHAR(100)       NOT NULL UNIQUE,
    `fecha_crea`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fecha_modif`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`cod_usuario`)
);

CREATE TABLE `producto`
(
    `cod_prod`     VARCHAR(25)    NOT NULL UNIQUE,
    `descripcion`  VARCHAR(255)   NOT NULL,
    `precio_unit`  DECIMAL(10, 2) NOT NULL CHECK (precio_unit > 0),
    `stock_actual` INTEGER        NOT NULL CHECK (stock_actual >= 0),
    `ruta_imagen`  VARCHAR(255)   NOT NULL,
    `cod_usuario`  INT            NULL,
    `fecha_crea`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fecha_modif`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`cod_prod`)
);

CREATE TABLE `cliente`
(
    `cod_cli`       VARCHAR(25)  NOT NULL UNIQUE,
    `nombre`        VARCHAR(255) NOT NULL,
    `apellido`      VARCHAR(255) NOT NULL,
    `dni`           VARCHAR(10)  NOT NULL,
    `direccion_cli` VARCHAR(255) NOT NULL,
    `telefono`      VARCHAR(15)  NOT NULL,
    `correo`        VARCHAR(100) NOT NULL,
    `cod_usuario`   INT          NULL,
    `fecha_crea`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fecha_modif`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`cod_cli`)
);

CREATE TABLE `factura`
(
    `cod_fact`      VARCHAR(25)    NOT NULL UNIQUE,
    `cod_cli`       VARCHAR(25)    NOT NULL,
    `subtotal`      DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
    `igv`           DECIMAL(10, 2) NOT NULL CHECK (igv >= 0),
    `total`         DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    `fecha_emision` DATETIME       NOT NULL,
    `cod_usuario`   INT            NULL,
    PRIMARY KEY (`cod_fact`)
);

CREATE TABLE `detalle_factura`
(
    `cod_fact`    VARCHAR(25) NOT NULL,
    `cod_prod`    VARCHAR(25) NOT NULL,
    `cantidad`    INTEGER     NOT NULL CHECK (cantidad > 0),
    `cod_usuario` INT         NULL,
    `fecha_crea`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fecha_modif` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`cod_fact`, `cod_prod`)
);

CREATE TABLE `movimiento_stock`
(
    `cod_mov`     INT         NOT NULL AUTO_INCREMENT UNIQUE,
    `cod_prod`    VARCHAR(25) NOT NULL,
    `tipo`        VARCHAR(20) NOT NULL CHECK (tipo IN ('INGRESO', 'SALIDA')),
    `cantidad`    INT         NOT NULL CHECK (cantidad > 0),
    `motivo`      VARCHAR(20) NOT NULL CHECK (motivo IN ('DEVOLUCION', 'VENTA', 'COMPRA')),
    `referencia`  VARCHAR(25) NOT NULL,
    `cod_usuario` INT         NULL,
    `fecha_crea`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fecha_modif` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`cod_mov`)
);

-- Creación de Relaciones --

-- Factura (N) -> Cliente (1)
ALTER TABLE `factura`
    ADD CONSTRAINT fk_factura__cliente_cod_cli
        FOREIGN KEY (cod_cli) REFERENCES cliente (cod_cli)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;

-- Detalle_factura (N) -> Factura (1)
ALTER TABLE `detalle_factura`
    ADD CONSTRAINT fk_detalle_factura__factura_cod_fact
        FOREIGN KEY (cod_fact) REFERENCES factura (cod_fact)
            ON UPDATE CASCADE
            ON DELETE CASCADE;

-- Detalle_factura (N) -> Producto (1)
ALTER TABLE `detalle_factura`
    ADD CONSTRAINT fk_detalle_factura__producto_cod_prod
        FOREIGN KEY (cod_prod) REFERENCES producto (cod_prod)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;

-- Movimiento_stock (N) -> Producto (1)
ALTER TABLE `movimiento_stock`
    ADD CONSTRAINT fk_movimiento_stock__producto
        FOREIGN KEY (cod_prod) REFERENCES producto (cod_prod)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;

-- Usuario (1) -> Factura (N)
ALTER TABLE `factura`
    ADD CONSTRAINT fk_factura_usuario
        FOREIGN KEY (cod_usuario) REFERENCES usuario (cod_usuario)
            ON UPDATE CASCADE
            ON DELETE SET NULL;

-- Usuario (1) -> Cliente (N)
ALTER TABLE `cliente`
    ADD CONSTRAINT fk_cliente_usuario
        FOREIGN KEY (cod_usuario) REFERENCES usuario (cod_usuario)
            ON UPDATE CASCADE
            ON DELETE SET NULL;

-- Usuario (1) -> Producto (N)
ALTER TABLE `producto`
    ADD CONSTRAINT fk_producto_usuario
        FOREIGN KEY (cod_usuario) REFERENCES usuario (cod_usuario)
            ON UPDATE CASCADE
            ON DELETE SET NULL;

-- Usuario (1) -> Movimiento (N)
ALTER TABLE `movimiento_stock`
    ADD CONSTRAINT fk_movimiento_usuario
        FOREIGN KEY (cod_usuario) REFERENCES usuario (cod_usuario)
            ON UPDATE CASCADE
            ON DELETE SET NULL;

-- Creación de Índices --
-- Índices para búsqueda en producto --
CREATE INDEX `idx_producto_desc`
    ON `producto` (`descripcion`);
CREATE INDEX `idx_producto_fechacrea`
    ON `producto` (`fecha_crea`);
CREATE INDEX `idx_producto_fechamod`
    ON `producto` (`fecha_modif`);

-- Índices para búsqueda en cliente --
CREATE INDEX `idx_cliente_dni`
    ON `cliente` (`dni`);
CREATE INDEX `idx_cliente_nombre_apellido`
    ON `cliente` (`nombre`, `apellido`);

-- Índices para búsqueda en factura --
CREATE INDEX `idx_factura_codcli`
    ON `factura` (`cod_cli`);

-- Índices para búsqueda en detalle_fact --
CREATE INDEX `idx_detalle_factura_codfact`
    ON `detalle_factura` (`cod_fact`);
CREATE INDEX `idx_detalle_factura_codprod`
    ON `detalle_factura` (`cod_prod`);

-- Creación de Triggers --

-- Validar datos de cliente a la creación--
DELIMITER $$

CREATE TRIGGER validar_datos_al_crear_cliente
    BEFORE INSERT
    ON cliente
    FOR EACH ROW
BEGIN
    IF NEW.dni IS NOT NULL AND NOT NEW.dni REGEXP '^[0-9]{8}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DNI inválido';
    END IF;

    IF NEW.telefono IS NOT NULL AND NOT NEW.telefono REGEXP '^[0-9]{9}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Teléfono inválido';
    END IF;

    IF NEW.correo IS NOT NULL AND NOT NEW.correo REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Correo no válido';
    END IF;
END$$

DELIMITER ;

-- Validar datos de cliente a la modificación--
DELIMITER $$

CREATE TRIGGER validar_datos_al_modificar_cliente
    BEFORE UPDATE
    ON cliente
    FOR EACH ROW
BEGIN
    IF NEW.dni IS NOT NULL AND NOT NEW.dni REGEXP '^[0-9]{8}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DNI inválido';
    END IF;

    IF NEW.telefono IS NOT NULL AND NOT NEW.telefono REGEXP '^[0-9]{9}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Teléfono inválido';
    END IF;

    IF NEW.correo IS NOT NULL AND NOT NEW.correo REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Correo no válido';
    END IF;
END$$

DELIMITER ;

-- Validar datos de factura al registro--
DELIMITER $$

CREATE TRIGGER validar_campos_al_insertar_factura
    BEFORE INSERT
    ON factura
    FOR EACH ROW
BEGIN
    DECLARE igv_calculado DECIMAL(10, 2);

    SET igv_calculado = ROUND(NEW.subtotal * 0.18, 2);

    IF ROUND(NEW.igv, 2) <> igv_calculado THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El IGV debe ser el 18% del subtotal';
    END IF;

    IF ROUND(NEW.subtotal + NEW.igv, 2) <> ROUND(NEW.total, 2) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El total debe ser igual a subtotal + IGV';
    END IF;

END$$

DELIMITER ;

-- Validar datos de factura al modificar--
DELIMITER $$

CREATE TRIGGER validar_campos_al_actualizar_factura
    BEFORE UPDATE
    ON factura
    FOR EACH ROW
BEGIN
    DECLARE igv_calculado DECIMAL(10, 2);

    SET igv_calculado = ROUND(NEW.subtotal * 0.18, 2);

    IF ROUND(NEW.igv, 2) <> igv_calculado THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El IGV debe ser el 18% del subtotal';
    END IF;

    IF ROUND(NEW.subtotal + NEW.igv, 2) <> ROUND(NEW.total, 2) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El total debe ser igual a subtotal + IGV';
    END IF;

END$$

DELIMITER ;

-- Registro de movimiento al crear un detalle de factura --
DELIMITER $$

CREATE TRIGGER registrar_movimiento_al_registrar_detalle
    AFTER INSERT
    ON detalle_factura
    FOR EACH ROW
BEGIN
    INSERT INTO movimiento_stock (cod_prod, tipo, cantidad, motivo, referencia, cod_usuario)
    VALUES (NEW.cod_prod, 'SALIDA', NEW.cantidad, 'VENTA', NEW.cod_fact, NEW.cod_usuario);

END$$

DELIMITER ;

-- Actualizar movimiento por actualización de detalle de factura --
DELIMITER $$

CREATE TRIGGER actualizar_movimiento_al_modificar_detalle
AFTER UPDATE
ON detalle_factura
FOR EACH ROW
BEGIN
    UPDATE movimiento_stock
    SET cantidad    = NEW.cantidad,
        fecha_crea  = CURRENT_TIMESTAMP,
        cod_usuario = NEW.cod_usuario
    WHERE cod_prod = NEW.cod_prod
      AND referencia = NEW.cod_fact
      AND motivo = 'VENTA'
      AND tipo = 'SALIDA'
    LIMIT 1;
END$$

DELIMITER ;

-- Eliminar movimiento al eliminar un detalle de factura --
DELIMITER $$

CREATE TRIGGER anular_movimiento_al_eliminar_detalle
    AFTER DELETE
    ON detalle_factura
    FOR EACH ROW
BEGIN
    DELETE
    FROM movimiento_stock
    WHERE referencia = OLD.cod_fact
      AND cod_prod = OLD.cod_prod
      AND tipo = 'SALIDA'
      AND motivo = 'VENTA';

    UPDATE producto
    SET stock_actual = stock_actual + OLD.cantidad
    WHERE cod_prod = OLD.cod_prod;
END$$

DELIMITER ;

-- Validar motivo y tipo de movimiento al registrar movimiento--
DELIMITER $$

CREATE TRIGGER validar_motivo_al_registrar_movimiento
    BEFORE INSERT
    ON movimiento_stock
    FOR EACH ROW
BEGIN
    IF NEW.tipo = 'INGRESO' AND NEW.motivo NOT IN ('COMPRA', 'DEVOLUCION') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo inválido para ingreso';
    END IF;

    IF NEW.tipo = 'SALIDA' AND NEW.motivo NOT IN ('VENTA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo inválido para salida';
    END IF;
END$$

DELIMITER ;

-- Validar motivo y tipo de movimiento al actualizar movimiento--
DELIMITER $$

CREATE TRIGGER validar_motivo_al_actualizar_movimiento
    BEFORE UPDATE
    ON movimiento_stock
    FOR EACH ROW
BEGIN
    IF NEW.tipo = 'INGRESO' AND NEW.motivo NOT IN ('COMPRA', 'DEVOLUCION') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo inválido para ingreso';
    END IF;

    IF NEW.tipo = 'SALIDA' AND NEW.motivo NOT IN ('VENTA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo inválido para salida';
    END IF;
END$$

DELIMITER ;

-- Actualizar stock por registro de movimiento --
DELIMITER $$

CREATE TRIGGER actualizar_stock_al_registrar_movimiento
    AFTER INSERT
    ON movimiento_stock
    FOR EACH ROW
BEGIN
    IF NEW.tipo = 'INGRESO' THEN
        UPDATE producto
        SET stock_actual = stock_actual + NEW.cantidad
        WHERE cod_prod = NEW.cod_prod;
    ELSEIF NEW.tipo = 'SALIDA' THEN
        IF (SELECT stock_actual FROM producto WHERE cod_prod = NEW.cod_prod) < NEW.cantidad THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'No hay stock suficiente';
        END IF;

        UPDATE producto
        SET stock_actual = stock_actual - NEW.cantidad
        WHERE cod_prod = NEW.cod_prod;
    END IF;
END$$

DELIMITER ;

-- Modificar stock para cambios en el movimiento --
DELIMITER $$

CREATE TRIGGER actualizar_stock_al_modificar_movimiento
    BEFORE UPDATE
    ON movimiento_stock
    FOR EACH ROW
BEGIN
    IF OLD.tipo = 'INGRESO' THEN
        UPDATE producto
        SET stock_actual = stock_actual - OLD.cantidad
        WHERE cod_prod = OLD.cod_prod;
    ELSEIF OLD.tipo = 'SALIDA' THEN
        UPDATE producto
        SET stock_actual = stock_actual + OLD.cantidad
        WHERE cod_prod = OLD.cod_prod;
    END IF;

    IF NEW.tipo = 'INGRESO' THEN
        UPDATE producto
        SET stock_actual = stock_actual + NEW.cantidad
        WHERE cod_prod = NEW.cod_prod;
    ELSEIF NEW.tipo = 'SALIDA' THEN
        IF (SELECT stock_actual FROM producto WHERE cod_prod = NEW.cod_prod) < NEW.cantidad THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Stock insuficiente para actualizar el movimiento';
        END IF;

        UPDATE producto
        SET stock_actual = stock_actual - NEW.cantidad
        WHERE cod_prod = NEW.cod_prod;
    END IF;
END$$

DELIMITER ;

-- Revertir stock por eliminación de movimiento --
DELIMITER $$

CREATE TRIGGER actualizar_stock_al_eliminar_movimiento
    BEFORE DELETE
    ON movimiento_stock
    FOR EACH ROW
BEGIN
    IF OLD.tipo = 'INGRESO' THEN
        UPDATE producto
        SET stock_actual = stock_actual - OLD.cantidad
        WHERE cod_prod = OLD.cod_prod;
    ELSEIF OLD.tipo = 'SALIDA' THEN
        UPDATE producto
        SET stock_actual = stock_actual + OLD.cantidad
        WHERE cod_prod = OLD.cod_prod;
    END IF;
END$$

DELIMITER ;