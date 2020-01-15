--1. Create a new table Production.ProductsHistory that will be used to store the history of changes in Production.Products
USE TestSQL

IF OBJECT_ID('Production.ProductsHistory', 'U') IS NOT NULL
	DROP TABLE Production.ProductsHistory;

CREATE TABLE Production.ProductsHistory (
	[ID] [INT] IDENTITY (1, 1) NOT NULL
   ,[Action] [NVARCHAR](20) NOT NULL
   ,[ModifiedDate] [DATETIME] NOT NULL
   ,[Productid] [INT] NOT NULL
   ,[UserName] [NVARCHAR](255) NOT NULL
   ,CONSTRAINT PK_ProductsHistory PRIMARY KEY CLUSTERED (ID)
);

GO

--Create a trigger for the INSERT, UPDATE and DELETE operations for the Production.Products table to save history of changes to the Production.ProductsHistory table.

CREATE OR ALTER TRIGGER Production.iudProducts
ON Production.Products
AFTER INSERT, UPDATE, DELETE
AS

	DECLARE @Action NVARCHAR(50);
	SET @Action = N'INSERT'

	IF EXISTS (SELECT
				1
			FROM DELETED)
	BEGIN
		SET @Action =
		CASE
			WHEN EXISTS (SELECT
						1
					FROM INSERTED) THEN N'UPDATE'
			ELSE N'DELETE'
		END

		INSERT INTO Production.ProductsHistory
			SELECT
				@Action
			   ,GETDATE()
			   ,DELETED.Productid
			   ,current_user
			FROM DELETED
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT
					1
				FROM INSERTED)
			INSERT INTO Production.ProductsHistory
				SELECT
					@Action
				   ,GETDATE()
				   ,INSERTED.Productid
				   ,current_user
				FROM INSERTED
	END;

GO

--Try to insert, update or delete rows in the Production.Products.

DECLARE @NewProductId TABLE ( --to work only with new row
	Productid INT
); 

INSERT INTO Production.Products
OUTPUT INSERTED.Productid INTO @NewProductId
	SELECT
		p.productname
	   ,p.supplierid
	   ,p.categoryid
	   ,p.unitprice
	   ,p.discontinued
	FROM Production.Products p
	WHERE p.Productid = 55

UPDATE Production.Products
SET productname = N'NEWNAME0978'
WHERE Productid IN (SELECT
		Productid
	FROM @NewProductId)

DELETE FROM Production.Products
WHERE Productid IN (SELECT
			Productid
		FROM @NewProductId)

--Verify the Production.ProductsHistory was populated
SELECT
	ph.ID
   ,ph.Action
   ,ph.ModifiedDate
   ,ph.Productid
   ,ph.UserName
FROM Production.ProductsHistory ph
ORDER BY ph.ID DESC

--Try to affect several records in one operation
UPDATE Production.Products
SET productname = N'NEWNAME 098' + CAST(Productid AS NVARCHAR(10))
WHERE Productid BETWEEN 1 AND 5

--Verify the Production.ProductsHistory was populated
SELECT
	ph.ID
   ,ph.Action
   ,ph.ModifiedDate
   ,ph.Productid
   ,ph.UserName
FROM Production.ProductsHistory ph
ORDER BY ph.ID DESC
;

-- 2. Create a view to show all columns from Production.Products table. 
GO

CREATE VIEW Production.vProductsForView
WITH SCHEMABINDING
AS
SELECT
	p.Productid
   ,p.productname
   ,p.supplierid
   ,p.categoryid
   ,p.unitprice
   ,p.discontinued
FROM Production.Products p
GO

-- Try to insert, update or delete records from the view. 
UPDATE Production.Products
SET productname = N'NEWNAME 000'
WHERE Productid = 1

-- Verify applied changes were saved to the history table.
SELECT
	ph.ID
   ,ph.Action
   ,ph.ModifiedDate
   ,ph.Productid
   ,ph.UserName
FROM Production.ProductsHistory ph
ORDER BY ph.ID DESC
;

--3. Create a view to show data from Production.Categories, Production.Products and Production.Suppliers tables. 
--   Prevent other users to see the source code of the view.
GO

CREATE VIEW Production.vProductsFullInfo
WITH SCHEMABINDING, ENCRYPTION
AS

SELECT
	p.Productid
   ,p.productname
   ,p.supplierid
   ,s.companyname
   ,s.contactname
   ,s.contacttitle
   ,s.address
   ,s.city
   ,s.region
   ,s.postalcode
   ,s.country
   ,s.phone
   ,s.fax
   ,p.categoryid
   ,c.categoryname
   ,c.description
   ,p.unitprice
   ,p.discontinued
FROM Production.Products AS p
JOIN Production.Categories c
	ON (p.categoryid = c.categoryid)
JOIN Production.Suppliers s
	ON (p.supplierid = s.supplierid)

GO

--4. Try to insert, update or delete data from the view. Make it possible to perform these operations through the Instead of trigger.
CREATE VIEW Production.vProductCategories
WITH SCHEMABINDING
AS

SELECT
	p.productname
   ,c.categoryname
   ,c.description
   ,p.unitprice
   ,p.supplierid
FROM Production.Products AS p
JOIN Production.Categories c
	ON (c.categoryid = p.categoryid)

GO

CREATE TRIGGER Production.ivProductCategories
ON Production.vProductCategories
INSTEAD OF INSERT
AS
BEGIN

	--try to create category - if it is not exists we will insert new
	INSERT INTO Production.Categories
		SELECT
			i.categoryname
		   ,i.description
		FROM INSERTED AS i
		WHERE NOT EXISTS (SELECT
				1
			FROM Production.Categories AS c
			WHERE c.categoryname = i.categoryname
			AND c.description = i.description)

    --add new product with exists category
	INSERT INTO Production.Products (productname, supplierid, categoryid, unitprice)
		SELECT
			i.productname
		   ,i.supplierid
		   ,c.categoryid
		   ,i.unitprice
		FROM INSERTED AS i
		JOIN Production.Categories c
			ON (c.categoryname = i.categoryname
					AND c.description = i.description)

END;


INSERT INTO Production.vProductCategories
	VALUES (N'New Product', N'New Cat.', N'This is new category', 32, 1)