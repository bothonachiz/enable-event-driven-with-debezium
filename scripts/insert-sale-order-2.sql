-- Change database
USE SaleDB;
GO

-- Insert example data #2
BEGIN TRANSACTION;
DECLARE @sale_order_id INT;

INSERT INTO sale_orders
    (sale_order_number, customer, total_price, total_items)
VALUES
    ('SO2503000212', 'Jane Marie', 300.00, 3);

SET @sale_order_id = SCOPE_IDENTITY();

INSERT INTO sale_order_items
    (sale_order_id, sale_order_item_number, sku, quantity, unit_price, total_price)
VALUES
    (@sale_order_id, 'SO2503000212-01', 'SKU-003', 2, 100.00, 200.00),
    (@sale_order_id, 'SO2503000212-02', 'SKU-004', 1, 100.00, 100.00);

-- Create nested JSON with items as array
INSERT INTO outbox
    (id, aggregatetype, aggregateid, type, payload)
SELECT
    NEWID(),
    'sale_order',
    CAST(@sale_order_id AS NVARCHAR(255)),
    'created',
    (
        SELECT
        so.id,
        so.sale_order_number,
        so.customer,
        so.total_price,
        so.total_items,
        so.is_cancelled,
        (
            SELECT
                soi.id,
                soi.sale_order_item_number,
                soi.sku,
                soi.quantity,
                soi.unit_price,
                soi.total_price
            FROM sale_order_items soi
            WHERE soi.sale_order_id = so.id
            FOR JSON PATH
        ) AS items
    FROM sale_orders so
    WHERE so.id = @sale_order_id
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

COMMIT TRANSACTION;
GO