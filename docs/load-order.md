# FK-safe load order (SQL Server)

The assignment `.sql` file creates some child tables **before** their parents. Use this order (or temporarily disable FKs, load, then `ALTER TABLE` add FKs).

## 1. Create parents first

1. `Geolocation_Staging` → bulk → CTE dedupe → `Geolocation` → drop staging  
2. `Product_Catery_Name_Translation` (keep the `catery` spelling)  
3. `Customers`  
4. `Sellers`  
5. `Products`  
6. `Orders`  
7. `Order_Payments`  
8. `Order_Items`  
9. `Order_Reviews`

## 2. Bulk insert tips

- Point every `FROM 'C:\...'` path at your local copies under `Assignment #02/Assignment_2_i222327/` or `Brazilian_Dataset/`.
- Prefer `CODEPAGE = '65001'` (UTF-8) on all CSV loads.
- SQL Server service account must be able to **read** the CSV path.
- After each load: `SELECT TOP 10 * FROM ...` instead of full `SELECT *` on large tables.

## 3. Then run Task 2

Run the four analysis blocks (Order / Customer / Product / Seller) and compare to the CSV/PNG packs and `docs/screenshots/`.
