USE Brz_Ecomerce;

IF OBJECT_ID(N'dbo.orders', N'U') IS NULL
   OR OBJECT_ID(N'dbo.customer', N'U') IS NULL
   OR OBJECT_ID(N'dbo.order_item', N'U') IS NULL
   OR OBJECT_ID(N'dbo.order_payments', N'U') IS NULL
   OR OBJECT_ID(N'dbo.order_reviews', N'U') IS NULL
   OR OBJECT_ID(N'dbo.products', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sellers', N'U') IS NULL
   OR OBJECT_ID(N'dbo.product_category_name_translation', N'U') IS NULL
   OR OBJECT_ID(N'dbo.geolocation', N'U') IS NULL
    THROW 50001, 'Import all nine marketplace tables into dbo before running setup_database.sql.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.orders') AND type = 'PK')
    ALTER TABLE dbo.orders ADD CONSTRAINT PK_orders PRIMARY KEY (order_id);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.customer') AND type = 'PK')
    ALTER TABLE dbo.customer ADD CONSTRAINT PK_customer PRIMARY KEY (customer_id);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.products') AND type = 'PK')
    ALTER TABLE dbo.products ADD CONSTRAINT PK_products PRIMARY KEY (product_id);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.sellers') AND type = 'PK')
    ALTER TABLE dbo.sellers ADD CONSTRAINT PK_sellers PRIMARY KEY (seller_id);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.product_category_name_translation') AND type = 'PK')
    ALTER TABLE dbo.product_category_name_translation ADD CONSTRAINT PK_category_translation PRIMARY KEY (product_category_name);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.order_item') AND type = 'PK')
    ALTER TABLE dbo.order_item ADD CONSTRAINT PK_order_item PRIMARY KEY (order_id, order_item_id);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.order_payments') AND type = 'PK')
    ALTER TABLE dbo.order_payments ADD CONSTRAINT PK_order_payments PRIMARY KEY (order_id, payment_sequential);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_orders_customer')
    ALTER TABLE dbo.orders ADD CONSTRAINT FK_orders_customer FOREIGN KEY (customer_id) REFERENCES dbo.customer(customer_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_items_orders')
    ALTER TABLE dbo.order_item ADD CONSTRAINT FK_items_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(order_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_items_products')
    ALTER TABLE dbo.order_item ADD CONSTRAINT FK_items_products FOREIGN KEY (product_id) REFERENCES dbo.products(product_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_items_sellers')
    ALTER TABLE dbo.order_item ADD CONSTRAINT FK_items_sellers FOREIGN KEY (seller_id) REFERENCES dbo.sellers(seller_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_payments_orders')
    ALTER TABLE dbo.order_payments ADD CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(order_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_reviews_orders')
    ALTER TABLE dbo.order_reviews ADD CONSTRAINT FK_reviews_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(order_id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_products_category')
    ALTER TABLE dbo.products ADD CONSTRAINT FK_products_category FOREIGN KEY (product_category_name)
        REFERENCES dbo.product_category_name_translation(product_category_name);

IF OBJECT_ID(N'dbo.Geolocation_ZipCode', N'U') IS NULL
    CREATE TABLE dbo.Geolocation_ZipCode (geolocation_zip_code_prefix NVARCHAR(100) NOT NULL PRIMARY KEY);

INSERT INTO dbo.Geolocation_ZipCode (geolocation_zip_code_prefix)
SELECT DISTINCT CONVERT(NVARCHAR(100), g.geolocation_zip_code_prefix)
FROM dbo.geolocation AS g
WHERE g.geolocation_zip_code_prefix IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dbo.Geolocation_ZipCode AS z
      WHERE z.geolocation_zip_code_prefix = CONVERT(NVARCHAR(100), g.geolocation_zip_code_prefix)
  );

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.orders') AND name = N'IX_orders_customer_date')
    CREATE INDEX IX_orders_customer_date ON dbo.orders(customer_id, order_purchase_timestamp);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.order_item') AND name = N'IX_items_product')
    CREATE INDEX IX_items_product ON dbo.order_item(product_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.order_item') AND name = N'IX_items_seller_order')
    CREATE INDEX IX_items_seller_order ON dbo.order_item(seller_id, order_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.order_reviews') AND name = N'IX_reviews_order')
    CREATE INDEX IX_reviews_order ON dbo.order_reviews(order_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.products') AND name = N'IX_products_category')
    CREATE INDEX IX_products_category ON dbo.products(product_category_name);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.customer') AND name = N'IX_customer_state_city')
    CREATE INDEX IX_customer_state_city ON dbo.customer(customer_state, customer_city);

SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM dbo.orders
UNION ALL SELECT 'customer', COUNT(*) FROM dbo.customer
UNION ALL SELECT 'order_item', COUNT(*) FROM dbo.order_item
UNION ALL SELECT 'order_payments', COUNT(*) FROM dbo.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM dbo.order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM dbo.products
UNION ALL SELECT 'sellers', COUNT(*) FROM dbo.sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM dbo.geolocation
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM dbo.product_category_name_translation;
