
-- ############################################
-- PRUEBAS FUNCIONALES Y DE VALIDACIÓN
-- ############################################

-- ==== Usuario base ====
INSERT IGNORE INTO usuario (cod_usuario, nombre_usuario, clave, correo)
VALUES (1, 'admin1', '123456', 'admin1@example.com');

-- ==== Producto base ====
INSERT IGNORE INTO producto (cod_prod, descripcion, precio_unit, stock_actual, ruta_imagen, cod_usuario)
VALUES ('P001', 'Mouse óptico', 50.00, 10, 'ruta/mouse.jpg', 1);

-- ==== Cliente base ====
INSERT IGNORE INTO cliente (cod_cli, nombre, apellido, dni, direccion_cli, telefono, correo, cod_usuario)
VALUES ('CLI001', 'Luis', 'Sánchez', '12345678', 'Av. Perú 456', '987654321', 'luis.sanchez@example.com', 1);

-- ==== Factura base ====
INSERT IGNORE INTO factura (cod_fact, cod_cli, subtotal, igv, total, fecha_emision, cod_usuario)
VALUES ('F001', 'CLI001', 100.00, 18.00, 118.00, NOW(), 1);

-- ==== 1. Validación de correo inválido ====
SAVEPOINT sp1;
INSERT INTO cliente (cod_cli, nombre, apellido, dni, direccion_cli, telefono, correo, cod_usuario)
VALUES ('CLI002', 'Ana', 'Ramos', '87654321', 'Av. Sol 123', '912345678', 'correo-invalido', 1);
ROLLBACK TO sp1;

-- ==== 2. DNI con 9 dígitos ====
SAVEPOINT sp2;
INSERT INTO cliente (cod_cli, nombre, apellido, dni, direccion_cli, telefono, correo, cod_usuario)
VALUES ('CLI003', 'Pedro', 'Torres', '123456789', 'Av. Mar 456', '912345678', 'pedro@example.com', 1);
ROLLBACK TO sp2;

-- ==== 3. Factura con cliente inexistente ====
SAVEPOINT sp3;
INSERT INTO factura (cod_fact, cod_cli, subtotal, igv, total, fecha_emision, cod_usuario)
VALUES ('F002', 'CLI999', 50.00, 9.00, 59.00, NOW(), 1);
ROLLBACK TO sp3;

-- ==== 4. Detalle con producto inexistente ====
SAVEPOINT sp4;
INSERT INTO detalle_factura (cod_fact, cod_prod, cantidad, cod_usuario)
VALUES ('F001', 'X999', 1, 1);
ROLLBACK TO sp4;

-- ==== 5. Ingreso manual de stock ====
INSERT INTO movimiento_stock (cod_prod, tipo, cantidad, motivo, referencia, cod_usuario)
VALUES ('P001', 'INGRESO', 5, 'LLEGADA', 'REF01', 1);

-- ==== 6. Salida sin stock suficiente ====
SAVEPOINT sp6;
INSERT INTO movimiento_stock (cod_prod, tipo, cantidad, motivo, referencia, cod_usuario)
VALUES ('P001', 'SALIDA', 9999, 'ERRORTEST', 'FERR', 1);
ROLLBACK TO sp6;

-- ==== 7. Insertar y actualizar detalle_factura ====
-- Insertar con cantidad 1
INSERT INTO detalle_factura (cod_fact, cod_prod, cantidad, cod_usuario)
VALUES ('F001', 'P001', 1, 1);

-- Actualizar a cantidad 3
UPDATE detalle_factura
SET cantidad = 3
WHERE cod_fact = 'F001' AND cod_prod = 'P002';

-- ==== 8. Movimiento con tipo inválido ====
SAVEPOINT sp8;
INSERT INTO movimiento_stock (cod_prod, tipo, cantidad, motivo, referencia, cod_usuario)
VALUES ('P001', 'TRANSFERENCIA', 5, 'TEST', 'TRF01', 1);
ROLLBACK TO sp8;

-- ==== 9. Movimiento con cantidad negativa ====
SAVEPOINT sp9;
INSERT INTO movimiento_stock (cod_prod, tipo, cantidad, motivo, referencia, cod_usuario)
VALUES ('P001', 'INGRESO', -10, 'TEST', 'NEG01', 1);
ROLLBACK TO sp9;

-- ==== 10. Verificación final de stock ====
SELECT cod_prod, stock_actual FROM producto WHERE cod_prod = 'P001';
