--1.Return information about the order with the maximum order ID.
SELECT
	o.orderid
   ,o.orderdate
   ,o.empid
   ,o.custid
FROM Sales.Orders AS o
WHERE o.orderid = (SELECT
		MAX(oo.orderid) AS maxorderid
	FROM Sales.Orders AS oo)

--2.Return order IDs of orders placed by employees with a last name starting with D. (?)
SELECT
	o.orderid
FROM Sales.Orders AS o
WHERE o.empid IN (SELECT
		e.empid
	FROM HR.Employees AS e
	WHERE e.lastname LIKE N'D%')

--3.Write a query that returns orders placed by customers from the United States.
SELECT
	o.custid
   ,o.orderid
   ,o.orderdate
   ,o.empid
FROM Sales.Orders AS o
WHERE o.custid IN (SELECT
		c.custid
	FROM Sales.Customers AS c
	WHERE c.country = N'USA')

--4.For each customer return order with the maximum order ID.
SELECT
	o.custid
   ,o.orderid
   ,o.orderdate
   ,o.empid
FROM Sales.Orders AS o
WHERE o.orderid = (SELECT
		MAX(oo.orderid) AS maxorderid
	FROM Sales.Orders AS oo
	WHERE oo.custid = o.custid)
ORDER BY o.custid

--5.Return customers from Spain who did not place orders
SELECT
	c.custid
   ,c.companyname
FROM Sales.Customers AS c
WHERE c.country = N'Spain'
AND NOT EXISTS (SELECT
		1
	FROM Sales.Orders AS o
	WHERE o.custid = c.custid)

--6.For each customer return orders information. Also show the previous order ID
SELECT
	o.orderid
   ,o.custid
   ,o.orderdate
   ,LAG(o.orderid, 1, 0) OVER (PARTITION BY o.custid ORDER BY o.custid, o.orderid) AS PrevOrderId
FROM Sales.Orders AS o

--7.Calculate the cumulative sum over the years using Sales.OrderTotalsByYear view. 
SELECT
	otby.orderyear
   ,otby.qty
   ,SUM(otby.qty) OVER (ORDER BY otby.orderyear ROWS UNBOUNDED PRECEDING) AS CumulativeTotal
FROM Sales.OrderTotalsByYear AS otby

--8.Write a query that returns employees who did not place orders on or after May 1, 2008.
SELECT
	e.empid
   ,e.firstname
   ,e.lastname
FROM HR.Employees AS e
WHERE NOT EXISTS (SELECT
		1
	FROM Sales.Orders AS o
	WHERE o.empid = e.empid
	AND o.orderdate >= '20080501')

--9.Write a query that returns the list of countries where there are customers exist but not employees
SELECT DISTINCT
	c.country
FROM Sales.Customers AS c
WHERE NOT EXISTS (SELECT
		1
	FROM HR.Employees AS e
	WHERE e.country = c.country)
ORDER BY c.country

--10.Write a query that returns customers who placed orders in 2007 but not in 2008.
SELECT
	c.custid
   ,c.companyname
FROM Sales.Customers AS c
WHERE NOT EXISTS (SELECT
		1
	FROM Sales.Orders AS o
	WHERE o.custid = c.custid
	AND DATEPART(YEAR, o.orderdate) = '2008')
AND EXISTS (SELECT
		1
	FROM Sales.Orders AS o
	WHERE o.custid = c.custid
	AND DATEPART(YEAR, o.orderdate) = '2007')