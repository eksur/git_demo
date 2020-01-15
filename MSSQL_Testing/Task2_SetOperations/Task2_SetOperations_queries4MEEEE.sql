USE TestSQL;
--1. Return supplier locations (Country, region, city and postalcode) excluding locations that are both employee and customer locations
--better execution plan
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

--
SELECT 
	s.country
   ,s.region
   ,s.city
   ,s.postalcode
FROM Production.Suppliers AS s
LEFT JOIN HR.Employees e
	ON (e.country = s.country
			AND ISNULL(e.region, '') = ISNULL(s.region, '')
			AND e.city = s.city
			AND ISNULL(e.postalcode, '') = ISNULL(s.postalcode,''))
LEFT JOIN Sales.Customers c
	ON (c.country = s.country
			AND ISNULL(c.region, '') = ISNULL(s.region, '')
			AND c.city = s.city
			AND ISNULL(c.postalcode, '') = ISNULL(s.postalcode,''))
WHERE c.custid IS NULL
OR e.empid IS NULL

--2. Return locations that are both supplier locations and customer locations but not employee locations
--best execution plan 
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

--
SELECT
	s.country
   ,s.region
   ,s.city
   ,s.postalcode
FROM Production.Suppliers AS s
JOIN Sales.Customers c
	ON (c.country = s.country
			AND ISNULL(c.region, '') = ISNULL(s.region, '')
			AND c.city = s.city
			AND ISNULL(c.postalcode, '') = ISNULL(s.postalcode,''))
LEFT JOIN HR.Employees e
	ON (e.country = s.country
			AND ISNULL(c.region, '') = ISNULL(s.region, '')
			AND e.city = s.city
			AND ISNULL(e.postalcode, '') = ISNULL(s.postalcode,''))
WHERE e.empid IS NULL

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
SELECT TOP (4)
	o.empid
   ,o.orderid
   ,o.orderdate
FROM Sales.Orders AS o
WHERE o.empid IN (3, 5)
ORDER BY ROW_NUMBER() OVER (PARTITION BY o.empid ORDER BY o.empid, o.orderdate DESC)

--5. Write a query that generates an output of 10 numbers in the range 1 through 10 without using a looping construct

--6. Write a query that returns customer and employee pairs that had order activity in January 2008 but not in February 2008.
-- best execution plan 
SELECT o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= CAST('20080101' AS DATETIME)
AND o.orderdate < CAST('20080201' AS DATETIME)
EXCEPT
SELECT o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= CAST('20080201' AS DATETIME)
AND o.orderdate < CAST('20080301' AS DATETIME)
ORDER BY o.custid ,o.empid

--
SELECT
	o.custid
   ,o.empid
FROM Sales.Orders AS o
LEFT JOIN Sales.Orders oc
	ON (oc.custid = o.custid
			AND oc.empid = o.empid
			AND oc.orderdate >= '20080201'
			AND oc.orderdate < '20080301')
WHERE o.orderdate >= '20080101'
AND o.orderdate < '20080201'
AND oc.orderid IS NULL

--7. Write a query that returns customer and employee pairs that had order activity in both January 2008 and February 2008 but not in 2007 year
(SELECT o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= CAST('20080101' AS DATETIME)
AND o.orderdate < CAST('20080201' AS DATETIME)
INTERSECT
SELECT o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= CAST('20080201' AS DATETIME)
AND o.orderdate < CAST('20080301' AS DATETIME))
EXCEPT
SELECT o.custid
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderdate >= CAST('20070101' AS DATETIME)
AND o.orderdate < CAST('20080101' AS DATETIME)
