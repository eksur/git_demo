USE tempdb;

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
	DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers (
	custid INT NOT NULL PRIMARY KEY
   ,companyname NVARCHAR(40) NOT NULL
   ,country NVARCHAR(15) NOT NULL
   ,region NVARCHAR(15) NULL
   ,city NVARCHAR(15) NOT NULL
   ,postalcode NVARCHAR(10) NULL
   ,phone NVARCHAR(24) NOT NULL
);

--1. Add a new [ID] column into the Customers table. New column should have IDENTITY property with start value 100 and increment value 10. Create UNIQUE constraint for the ID column;

ALTER TABLE dbo.Customers
ADD id INT CONSTRAINT UNQ_Customers_id UNIQUE IDENTITY (100, 10)

--2. Add check constraint to the Customers table to allow only numbers for the [postalcode] field;

ALTER TABLE dbo.Customers
ADD CONSTRAINT CHK_Customers_postalcode CHECK (postalcode LIKE '%[0-9]%')

--3. Add default constraint to populate [country] column with ‘USA’;

ALTER TABLE dbo.Customers
ADD CONSTRAINT DEF_Customers_country DEFAULT N'USA' FOR country

--4. Alter Customers table to allow NULLs in the city column;

ALTER TABLE dbo.Customers
ALTER COLUMN city NVARCHAR(15) NULL

--5. Insert into the Customers table a row with: custid: 100 companyname: Company ABCDE country: USA region: WA city: Redmond postalcode:  12345 phone: 1-234567

INSERT INTO dbo.Customers (custid, companyname, region, city, postalcode, phone)
	VALUES (100, N'Company ABCDE', N'WA', N'Redmond', N'12345', N'1-234567')

--6. Insert into the tempdb Customers table all customers from TestSQL.Sales.Customers who placed orders;

INSERT INTO dbo.Customers
	SELECT
		c.custid
	   ,c.companyname
	   ,c.country
	   ,c.region
	   ,c.city
	   ,c.postalcode
	   ,c.phone
	FROM TestSQL.Sales.Customers AS c
	WHERE EXISTS (SELECT
			1
		FROM TestSQL.Sales.Orders AS o
		WHERE o.custid = c.custid)

--7. Update the Customers table and change all NULL region values to '<None>'. Use the OUTPUT clause to show the custid, old region, and new region;

UPDATE dbo.Customers
SET region = N'<None>'
OUTPUT INSERTED.custid, DELETED.region AS OldRegion, INSERTED.region AS NewRegion
WHERE region IS NULL

--8. Declare and populate an @Orders table variable with orders from the Sales.Orders table in the TestSQL that were placed from 2006 through 2008 year;

DECLARE @Orders TABLE (
	id INT IDENTITY (1, 1) NOT NULL
   ,orderid INT NOT NULL
   ,custid INT NULL
   ,empid INT NOT NULL
   ,orderdate DATETIME NOT NULL
   ,requireddate DATETIME NOT NULL
   ,shippeddate DATETIME NULL
   ,shipperid INT NOT NULL
   ,freight MONEY NOT NULL
   ,shipname NVARCHAR(40) NOT NULL
   ,shipaddress NVARCHAR(60) NOT NULL
   ,shipcity NVARCHAR(15) NOT NULL
   ,shipregion NVARCHAR(15) NULL
   ,shippostalcode NVARCHAR(10) NULL
   ,shipcountry NVARCHAR(15) NOT NULL
)

INSERT INTO @Orders
	SELECT
		o.orderid
	   ,o.custid
	   ,o.empid
	   ,o.orderdate
	   ,o.requireddate
	   ,o.shippeddate
	   ,o.shipperid
	   ,o.freight
	   ,o.shipname
	   ,o.shipaddress
	   ,o.shipcity
	   ,o.shipregion
	   ,o.shippostalcode
	   ,o.shipcountry
	FROM TestSQL.Sales.Orders AS o
	WHERE YEAR(o.orderdate) BETWEEN 2006 AND 2008

--9. Delete orders from @Orders that were placed before the August 2006. Use the OUTPUT clause to return the orderid and orderdate of the deleted orders;

DELETE FROM @Orders
OUTPUT DELETED.orderid deletedOrderId, DELETED.orderdate deletedOrderDate
WHERE orderdate < '20060801'

--10. Delete orders from @Orders placed by customers from Brazil;

DELETE @Orders
	FROM @Orders AS o
	JOIN TestSQL.Sales.Customers c
		ON (c.custid = o.custid)
WHERE c.country = N'Brazil'

--11. Update all orders in @Orders placed by UK customers and set their shipcountry, shipregion, and shipcity values to the country, region, and city values of the corresponding customers;

UPDATE @Orders
SET shipcountry = c.country
   ,shipregion = c.region
   ,shipcity = c.city
FROM @Orders AS o
JOIN TestSQL.Sales.Customers c
	ON (c.custid = o.custid)
WHERE c.country = N'UK'

--12. Use a SELECT INTO statement to create and populate #Products temporary table. 
--    Add a new column row_id INT NULL into temporary table #Products. 
--    Write an UPDATE statement that would assign sequential values to row_id column;

SELECT
	p.productid
   ,p.productname
   ,p.supplierid
   ,p.categoryid
   ,p.unitprice
   ,p.discontinued INTO #Products
FROM TestSQL.Production.Products AS p

ALTER TABLE #Products
ADD row_id INT NULL

DECLARE @id INT
SET @id = 0

UPDATE #Products
SET @id = row_id = @id + 1

--13. Delete 5 the cheapest products from the #Products which are discontinued;
DELETE FROM #Products
WHERE productid IN (SELECT TOP (5)
			p.productid
		FROM #Products AS p
		WHERE p.discontinued = 1
		ORDER BY p.unitprice)

--14. Write an UPDATE statement that will change unitprice in the #Products: 
--    increase by 10 for categoryid = 1, increase by 20 for categoryid = 4, set to 0 for categoryid = 7, decrease by 5 for ctagoryid = 8. 

UPDATE #Products
SET unitprice = unitprice + (CASE
	WHEN categoryid = 1 THEN 10
	WHEN categoryid = 4 THEN 20
	WHEN categoryid = 7 THEN -unitprice
	WHEN categoryid = 8 THEN -5
	ELSE unitprice
END)
WHERE categoryid IN (1, 4, 7, 8)

--15. Create new table in the tempdb with the same structure as TestSQL.Sales.OrderDetails. 
--    Table should contain one additional computed column (computed column is a virtual column) 
--    to calculate a subtotal like multiplying the unitprice on qty and subtracting the discount;

USE tempdb

IF NOT EXISTS (SELECT 1
		FROM sys.schemas
		WHERE name = N'Sales')
	EXEC ('CREATE SCHEMA Sales');

IF OBJECT_ID('Sales.OrderDetails', 'U') IS NOT NULL
	DROP TABLE Sales.Customers;

CREATE TABLE Sales.OrderDetails (
	orderid INT NOT NULL
   ,productid INT NOT NULL
   ,unitprice MONEY NOT NULL
   ,qty SMALLINT NOT NULL
   ,discount NUMERIC(4, 3) NOT NULL
   ,subtotal AS unitprice * qty - discount
);

--16. Write a Merge statement to populate tempdb.Sales.OrderDetails from TestSQL.Sales.OrderDetails. 
--    Merge should insert records into tempdb.Sales.OrderDetails if they do not exist, update if they exist and values are different from values in TestSQL.Sales.OrderDetails, 
--    delete records that do not exist in TestSQL.Sales.OrderDetails. Include OUTPUT clause to the Merge statement to display the action and details.

MERGE tempdb.Sales.OrderDetails AS tod USING TestSQL.Sales.OrderDetails AS sod
ON (tod.orderid = sod.orderid
	AND tod.productid = sod.productid)
WHEN MATCHED
	AND (tod.unitprice <> sod.unitprice
	OR tod.qty <> sod.qty
	OR tod.discount <> sod.discount)
	THEN UPDATE
		SET tod.unitprice = sod.unitprice
		   ,tod.qty = sod.qty
		   ,tod.discount = sod.discount
WHEN NOT MATCHED BY TARGET
	THEN INSERT
			VALUES (sod.orderid, sod.productid, sod.unitprice, sod.qty, sod.discount)
WHEN NOT MATCHED BY SOURCE
	THEN DELETE
OUTPUT $ACTION AS result
	  ,INSERTED.orderid AS neworderid
	  ,INSERTED.productid AS newproductid
	  ,INSERTED.unitprice AS newunitprice
	  ,INSERTED.qty AS newqty
	  ,INSERTED.discount AS newdiscount
	  ,DELETED.orderid AS oldorederid
	  ,DELETED.productid AS oldproductid
	  ,DELETED.unitprice AS oldunitprice
	  ,DELETED.qty AS oldqty
	  ,DELETED.discount AS olddiscount;