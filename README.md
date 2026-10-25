<div align="center">

# 🛒 E-Commerce SQL

SQL Server analysis of orders, customers, sellers, products, payments, deliveries, and reviews in a Brazilian marketplace.

![SQL Server](https://img.shields.io/badge/Database-SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/Language-T--SQL-0078D4?style=for-the-badge)
![Views](https://img.shields.io/badge/Views-6-7c3aed?style=for-the-badge)

<p><b>Relational keys · Import checks · Six SQL views · Business queries</b></p>

</div>

---

## 📌 Project Overview

This SQL Server project prepares imported e-commerce tables with keys and indexes, defines six analytical views, and answers business questions about customers, products, sellers, deliveries, payments, and reviews. The supplied project documentation identifies the Brazilian E-Commerce Public Dataset by Olist as the intended source, covering 2016 to 2018.

**The source CSVs and import mapping are not included.** The SQL requires the nine base tables to be imported separately before setup. No SQL Server execution results or measured query plans are included.

## 🎯 Objectives

- Check imported rows, column types, duplicates, and missing references.
- Add primary and foreign keys to the imported relational tables.
- Keep item, payment, and review counts at their correct grains.
- Provide six reusable reporting views and readable business queries.
- Use CTEs, `LAG`, `ROW_NUMBER`, and `DENSE_RANK` where they answer the question.

## 🧱 Database Model

The scripts expect these imported `dbo` tables: `orders`, `customer`, `order_item`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`, and `product_category_name_translation`. The setup also creates `Geolocation_ZipCode` as a distinct-prefix lookup. It does not add foreign keys from customer or seller ZIP columns to that lookup because the imported column types have not been verified.

Imported key columns must be non-null and compatible before constraints can be added. The setup creates missing constraints and indexes; it does not replace imported tables or repair their data.

## ✨ SQL Views

| View | Row meaning | Important measure detail |
| --- | --- | --- |
| `dbo.vw_orders_detail` | Order item; an order without items can also appear | `valor_pago` is an order total repeated across its items and must not be summed from this view |
| `dbo.vw_info_clientes` | Customer ID | Payments, item counts, freight, and reviews are first summarized by order |
| `dbo.vw_info_vendedores` | Seller | Sales sum that seller's item prices, not the entire order payment |
| `dbo.vw_info_producto` | Product and customer city/state | Sales sum item prices for that product and area |
| `dbo.vw_info_pagos` | Payment type and customer city/state | Each payment record is counted once without joining to order items |
| `dbo.vw_info_zonas` | Customer city/state and ZIP for delivered orders | Order payments, items, and reviews are aggregated separately |

The views use `CREATE OR ALTER VIEW` inside separate `EXEC` batches. The SQL files do not require `GO` separators.

## 📊 Business Questions

- Customer distribution by state and city; monthly first purchases using `LAG`.
- Leading and trailing product categories, customer spending per item, product sales less freight, and top-category share.
- Seller order rankings, sales concentration, and delivery time.
- Delivery time by customer state and category, on-time delivery, and late-delivery rates.
- Payment methods, average amount by order and method, and orders with one or multiple payment records.
- Review scores by order status, product category, and delivery-time range.

The first-purchase query groups by the available `customer_id`. The supplied scripts do not establish a person-level identifier. Multiple payment records do **not** prove an installment plan. Negative reviews do **not** prove product returns because no returns table is supplied.

## 📁 Project Structure

```text
E-Commerce-SQL/
├── create_database.sql         # Create the database if needed
├── verify_import.sql           # Review imported rows, types, keys, and references
├── setup_database.sql          # Add constraints, ZIP lookup, indexes, and row counts
├── create_analytics_views.sql  # Create six reporting views
├── business_analysis.sql       # Business questions and analytical SQL
├── README.md
├── LICENSE
└── .gitignore
```

## ⚙️ Run in SQL Server

1. Run `create_database.sql`.
2. Import the nine authorized source tables into `Brz_Ecomerce.dbo` using SQL Server Management Studio. The CSVs are not in this project. Match the expected names and types.
3. Run `verify_import.sql`. Check nullability and types, duplicate counts, and orphan counts; correct import problems before setup.
4. Run `setup_database.sql`. If a key or foreign key fails, review the imported data and column definitions.
5. Run `create_analytics_views.sql`, followed by `business_analysis.sql`.

These instructions require the separately obtained data. **The scripts have not been executed in this review environment**, so row counts, view results, and performance remain unverified.

## 🔎 Checks Before Presenting Results

- Match SQL Server table counts against the separately obtained source files.
- Compare `SUM(payment_value)` from `order_payments` with the payment view; do not sum order totals from `vw_orders_detail`.
- Compare item-price totals from `order_item` with product and seller views, accounting for missing category translations or sellers.
- Confirm the actual meaning of customer identifiers, payment rows, and imported timestamps.
- Review execution plans before claiming that an index made a query faster.

## 🧑‍💻 Author and Data Credit

**Muhammad Ali Nawaz**  
SQL Developer / Database Developer

The supplied project files identify this developer; the files alone do not independently establish sole authorship. The dataset is credited to **Olist**, separately from code authorship.

## 📄 License

The project code and documentation carry the supplied [MIT License](LICENSE). Any separately obtained dataset has its own terms.
