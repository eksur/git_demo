--1 Return orders placed in June 2007. 
SELECT
	so.orderid
   ,so.orderdate
   ,so.custid
   ,so.empid
FROM Sales.Orders AS so
WHERE so.orderdate >= '20070601' 
AND so.orderdate < '20070701'

--2	Return employees with last name containing the letter 'a' twice or more
SELECT
	he.empid
   ,he.firstname
   ,he.lastname
FROM HR.Employees AS he
WHERE he.lastname LIKE '%a%a%';

--3 Return orders with total value(qty*unitprice) greater than 10000 sorted by total value
SELECT
	sod.orderid
   ,(sod.qty * sod.unitprice) AS totalvalue
FROM Sales.OrderDetails AS sod
WHERE (sod.qty * sod.unitprice) > 10000
ORDER BY totalvalue

--4 Return the three ship countries with the highest average freight in 2007
SELECT TOP (3)
	so.shipcountry
   ,AVG(so.freight) AS avgfreight
FROM Sales.Orders AS so
WHERE YEAR(so.shippeddate) = 2007
GROUP BY so.shipcountry
ORDER BY avgfreight DESC;

--5 Calculate row numbers per each customer based on order date ordering.
SELECT
	so.custid
   ,so.orderdate
   ,ROW_NUMBER() OVER (PARTITION BY so.custid ORDER BY so.orderdate) AS rownum
FROM Sales.Orders AS so;

--6 Figure out and return for each employee the gender based on the title of courtesy. Ms. and Mrs. are Female; Mr. is Male; Dr. is Unknown.
SELECT
	he.empid
   ,he.firstname
   ,he.lastname
   ,he.titleofcourtesy
   ,CASE
		WHEN he.titleofcourtesy IN ('Ms.', 'Mrs.') THEN 'Female'
		WHEN he.titleofcourtesy = 'Mr.' THEN 'Male'
		WHEN he.titleofcourtesy = 'Dr.' THEN 'Unknown'
		ELSE he.titleofcourtesy
	END AS gender
FROM HR.Employees AS he;

--7 Return customers and regions. Sort the rows in the output by region having NULLs sort last (after non-NULL values)
SELECT
	sc.custid
   ,sc.region
FROM Sales.Customers AS sc
ORDER BY CASE
	WHEN sc.region IS NULL THEN 1
	ELSE 0
END;

--8	Return the list of employees sorted by their hire date. Show only 5 employees, skipping first two records
SELECT
	he.empid
   ,he.lastname
   ,he.firstname
   ,he.hiredate
FROM HR.Employees AS he
ORDER BY he.hiredate DESC
OFFSET 2 ROWS FETCH NEXT 5 ROWS ONLY;

--9 Return customers that have more than 20 orders
SELECT
	so.custid
   ,COUNT(so.orderid) AS OrderCounts
FROM Sales.Orders AS so
GROUP BY so.custid
HAVING COUNT(so.orderid) > 20;