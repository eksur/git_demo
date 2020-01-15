--1. Return supplier locations (Country, region, city and postalcode) excluding locations that are both employee and customer locations

SELECT
	s.country
   ,s.region
   ,s.city
   ,s.postalcode
FROM Production.Suppliers AS s
EXCEPT
(SELECT
	e.country
   ,e.region
   ,e.city
   ,e.postalcode
FROM HR.Employees AS e
INTERSECT
SELECT
	c.country
   ,c.region
   ,c.city
   ,c.postalcode
FROM Sales.Customers AS c)

--2. Return locations that are both supplier locations and customer locations but not employee locations

(SELECT
	s.country
   ,s.region
   ,s.city
   ,s.postalcode
FROM Production.Suppliers AS s
INTERSECT
SELECT
	c.country
   ,c.region
   ,c.city
   ,c.postalcode
FROM Sales.Customers AS c)
EXCEPT
SELECT
	e.country
   ,e.region
   ,e.city
   ,e.postalcode
FROM HR.Employees AS e

--3. Calculate the number of distinct locations that are either employee or customer locations in each country

SELECT
	u.country
   ,COUNT(1) AS DistinctLocationsCount
FROM (SELECT
		e.country
	   ,e.region
	   ,e.city
	   ,e.postalcode
	FROM HR.Employees AS e
	UNION
	SELECT
		c.country
	   ,c.region
	   ,c.city
	   ,c.postalcode
	FROM Sales.Customers AS c) AS u
GROUP BY u.country
ORDER BY u.country

--4. Return two the most recent orders for employees with employee ID of 3 or 5

SELECT
	uo.empid
   ,uo.orderid
   ,uo.orderdate
FROM (SELECT TOP (2)
		o.empid
	   ,o.orderid
	   ,o.orderdate
	FROM Sales.Orders AS o
	WHERE o.empid = 3
	ORDER BY o.orderdate DESC) AS uo
UNION
SELECT
	u.empid
   ,u.orderid
   ,u.orderdate
FROM (SELECT TOP (2)
		o.empid
	   ,o.orderid
	   ,o.orderdate
	FROM Sales.Orders AS o
	WHERE o.empid = 5
	ORDER BY o.orderdate DESC) AS u;

--5. Write a query that generates an output of 10 numbers in the range 1 through 10 without using a looping construct

WITH addNum (N)
AS
(SELECT
		1 AS N
	UNION ALL
	SELECT
		N + 1
	FROM addNum
	WHERE N < 10)
SELECT
	N
FROM addNum

--6. Write a query that returns customer and employee pairs that had order activity in January 2008 but not in February 2008.

SELECT
	o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= '20080101'
AND o.orderdate < '20080201'
EXCEPT
SELECT
	o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= '20080201'
AND o.orderdate < '20080301'


--7. Write a query that returns customer and employee pairs that had order activity in both January 2008 and February 2008 but not in 2007 year

(SELECT
	o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= '20080101'
AND o.orderdate < '20080201'
INTERSECT
SELECT
	o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= '20080201'
AND o.orderdate < '20080301')
EXCEPT
SELECT
	o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= '20070101'
AND o.orderdate < '20080101'
