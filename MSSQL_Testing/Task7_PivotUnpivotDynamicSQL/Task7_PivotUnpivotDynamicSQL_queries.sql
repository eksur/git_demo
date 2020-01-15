--1. Write a query to pivot order data, returning the count of orders that were placed by customers. Show statistics for the 2006 and 2007 years
SELECT
	companyname
   ,[2006]
   ,[2007]
FROM (SELECT
		c.companyname
	   ,YEAR(o.orderdate) AS orderyear
	   ,o.orderid
	FROM Sales.Orders AS o
	JOIN Sales.Customers c
		ON (c.custid = o.custid)) AS m
PIVOT (
COUNT(m.orderid) FOR m.orderyear IN ([2006], [2007])
) AS pvt

--2. Create a Stored Procedure to pivot order data, returning the count of orders that were placed by customers for the specified years. 
--   The list of years should be sent to the procedure by the VARCHAR parameter.
GO
CREATE OR ALTER PROC dbo.PivotOrdersByYear @YearsList NVARCHAR(255)
AS
	DECLARE @sqlstring NVARCHAR(MAX);
	SET @sqlstring = N'SELECT *
FROM(
SELECT c.companyname, YEAR(o.orderdate) AS orderyear, o.orderid
FROM Sales.Orders AS o 
JOIN Sales.Customers c ON (c.custid = o.custid)) AS m
PIVOT(
COUNT(M.orderid) FOR M.orderyear IN ([' + REPLACE(@YearsList, ',', '],[') + '])
) AS pvt';

	EXEC sys.sp_executesql @sqlstring;

	EXEC dbo.PivotOrdersByYear @YearsList = '2006,2007,2008'

--3. “Unpivot” the order details to have the list of productid, unitprice and qty values in rows
	SELECT
		orderid
	   ,[field]
	   ,[value]
	FROM (SELECT
			od.orderid
		   ,CAST(od.productid AS NVARCHAR(MAX)) AS productid
		   ,CAST(od.unitprice AS NVARCHAR(MAX)) AS unitprice
		   ,CAST(od.qty AS NVARCHAR(MAX)) AS qty
		FROM Sales.OrderDetails AS od) AS m
	UNPIVOT
	([value] FOR [field] IN ([productid], [unitprice], [qty])
	) AS upvt

--4. Show the list of distinct customers who placed orders with each employee. 
--   Create two queries one for SQL Server 2017 version and another for older version of SQL Server

  --for 2017 server
	SELECT
		m.empid
	   ,STRING_AGG(m.companyname, ',') WITHIN GROUP (ORDER BY m.companyname) AS Customers
	FROM (SELECT DISTINCT
			o.empid
		   ,c.companyname
		FROM Sales.Orders AS o
		JOIN Sales.Customers c
			ON (c.custid = o.custid)) m
	GROUP BY m.empid

  --for versions earlier than 2017
	SELECT DISTINCT
		o.empid
	   ,STUFF((SELECT DISTINCT
				',' + c.companyname
			FROM Sales.Orders AS M
			JOIN Sales.Customers c
				ON (c.custid = M.custid)
			WHERE o.empid = M.empid
			FOR XML PATH (''))
		, 1, 1, '') AS Customers
	FROM Sales.Orders AS o