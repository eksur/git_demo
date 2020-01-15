USE TestSQL;
--1. Write a query that returns a row for each employee and day in the range June 12, 2009 – June 16 2009.
WITH eDates (eDay)
AS
(SELECT
		CAST('20090612' AS DATE) eDay
	UNION ALL
	SELECT
		DATEADD(DAY, 1, eDay) eDay
	FROM eDates AS ed
	WHERE eDay BETWEEN '20090612' AND '20090615')
SELECT
	e.empid
   ,e.lastname
   ,e.firstname
   ,d.eDay AS dt
FROM HR.Employees e
CROSS JOIN eDates AS d
ORDER BY e.empid, D.eDay

--2. Return customers and their orders including customers who placed no orders
SELECT
	c.custid
   ,c.companyname
   ,o.orderid
   ,o.orderdate
FROM Sales.Customers AS c
LEFT JOIN Sales.Orders o
	ON (o.custid = c.custid)

--3. Write a query to produce all possible combinations of pairs of employees.
SELECT
	e.empid
   ,e.lastname
   ,e.firstname
   ,em.empid
   ,em.lastname
   ,em.firstname
FROM HR.Employees AS e
CROSS JOIN HR.Employees AS em
ORDER BY em.empid, e.empid

--4. Write a query that produces a sequence of integers in the range 1 through 1,000
USE tempdb;

IF OBJECT_ID('dbo.Digits', 'U') IS NOT NULL 
	DROP TABLE dbo.Digits;
CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.Digits(digit)
SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9

SELECT
	ROW_NUMBER() OVER (ORDER BY d2.digit) AS digit
FROM Digits AS d
CROSS JOIN Digits AS d1
CROSS JOIN Digits AS d2

--5. Write a query to produce unique pairs of employees
USE TestSQL;

SELECT
	e.empid
   ,e.lastname
   ,e.firstname
   ,em.empid
   ,em.lastname
   ,em.firstname
FROM HR.Employees AS e
JOIN HR.Employees AS em ON e.empid < em.empid

--6. Write a query to match customers with their orders and orders with their order lines
SELECT
	c.custid
   ,c.companyname
   ,o.orderid
   ,o.orderdate
   ,od.productid
   ,od.qty
FROM Sales.Customers AS c
JOIN Sales.Orders o
	ON (o.custid = c.custid)
JOIN Sales.OrderDetails od
	ON (od.orderid = o.orderid)
ORDER BY c.custid, o.orderid

--7. Write a query to return customers who did not place any orders
SELECT
	c.custid
   ,c.companyname
FROM Sales.Customers AS c
LEFT JOIN Sales.Orders o
	ON (o.custid = c.custid)
WHERE o.orderid IS NULL

--8. Write a query that calculates a total quantity for each customer and month (monthly qty) and running total for monthly qty
SELECT
	c.custid
   ,c.companyname
   ,DATEPART(MONTH, o.orderdate) AS OrderMonth
   ,SUM(od.qty) AS MonyhQty
   ,SUM(SUM(od.qty)) OVER (PARTITION BY c.custid ORDER BY c.custid, DATEPART(MONTH, o.orderdate) ROWS UNBOUNDED PRECEDING) AS CumulativeMonthTotal
FROM Sales.Customers AS c
JOIN Sales.Orders o
	ON (o.custid = c.custid)
JOIN Sales.OrderDetails od
	ON (od.orderid = o.orderid)
GROUP BY c.custid
		,c.companyname
		,DATEPART(MONTH, o.orderdate)
ORDER BY c.custid, OrderMonth