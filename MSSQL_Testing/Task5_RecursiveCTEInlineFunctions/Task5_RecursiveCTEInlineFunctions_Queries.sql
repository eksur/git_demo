--1. Write a query against the Sales.Orders table and return the number of distinct customers handled in each order year

--solution without CTE(shorter)
SELECT
	DATEPART(YEAR, O.orderdate) OrderYear
   ,COUNT(DISTINCT O.custid) CustomersNumber
FROM Sales.Orders AS O
GROUP BY DATEPART(YEAR, O.orderdate)
ORDER BY OrderYear

--solution with CTE (easier to understand)
--no difference with solution above according to execution plan
;
WITH CTEdist
AS
(SELECT DISTINCT
		DATEPART(YEAR, O.orderdate) OrderYear
	   ,O.custid CustomersNumber
	FROM Sales.Orders AS O)
SELECT
	c.OrderYear
   ,COUNT(c.CustomersNumber) CustomersNumber
FROM CTEdist AS c
GROUP BY c.OrderYear
ORDER BY OrderYear

--2. Return order years and the number of customers handled in each year only for years in which more than 70 customers were handled
--solution without CTE(shorter)
SELECT
	DATEPART(YEAR, O.orderdate) OrderYear
   ,COUNT(DISTINCT O.custid) CustomersNumber
FROM Sales.Orders AS O
GROUP BY DATEPART(YEAR, O.orderdate)
HAVING COUNT(DISTINCT O.custid) > 70
ORDER BY OrderYear

--solution with CTE (easier to understand)
--no difference with solution above according to execution plan
;
WITH CTEdist
AS
(SELECT DISTINCT
		DATEPART(YEAR, O.orderdate) OrderYear
	   ,O.custid CustomersNumber
	FROM Sales.Orders AS O)
SELECT
	c.OrderYear
   ,COUNT(c.CustomersNumber) CustomersNumber
FROM CTEdist AS c
GROUP BY c.OrderYear
HAVING COUNT(c.CustomersNumber) > 70
ORDER BY OrderYear

--3. Calculate the difference between the number of customers handled in the current and previous years.
--Solution without CTE - shorter and more faster according to execution plan 
SELECT
	M.OrderYear
   ,M.CustomersNumber
   ,M.PreviousCustomersNumber
   ,M.CustomersNumber - M.PreviousCustomersNumber Growth
FROM (SELECT
		DATEPART(YEAR, O.orderdate) OrderYear
	   ,COUNT(DISTINCT O.custid) CustomersNumber
	   ,LAG(COUNT(DISTINCT O.custid), 1, 0) OVER (ORDER BY DATEPART(YEAR, O.orderdate)) PreviousCustomersNumber
	FROM Sales.Orders AS O
	GROUP BY DATEPART(YEAR, O.orderdate)) AS M

--solution with CTE
;
WITH CTEprev
AS
(SELECT
		DATEPART(YEAR, O.orderdate) OrderYear
	   ,COUNT(DISTINCT O.custid) CustomersNumber
	FROM Sales.Orders AS O
	GROUP BY DATEPART(YEAR, O.orderdate))
SELECT
	c.OrderYear
   ,c.CustomersNumber
   ,ISNULL(cp.CustomersNumber, 0) PreviousCustomersNumber
   ,ISNULL((c.CustomersNumber - cp.CustomersNumber), c.CustomersNumber) Growth
FROM CTEprev AS c
LEFT JOIN CTEprev cp
	ON (cp.OrderYear = (c.OrderYear - 1))

--4. Return information about an employee (Don Funk, employee ID 2) and all of the employee's subordinates in all levels (direct or indirect)

;
WITH EmployeeHierarchy
AS
(SELECT
		e.empid
	   ,e.firstname
	   ,e.lastname
	   ,e.mgrid
	FROM HR.Employees AS e
	WHERE e.empid = 2
	UNION ALL
	SELECT
		eh.empid
	   ,eh.firstname
	   ,eh.lastname
	   ,eh.mgrid
	FROM HR.Employees AS eh
	JOIN EmployeeHierarchy AS emph
		ON (emph.empid = eh.mgrid))
SELECT
	hre.empid
   ,hre.firstname
   ,hre.lastname
   ,hre.mgrid
   ,e.firstname AS managerfirstname
   ,e.lastname AS managerlastname
FROM EmployeeHierarchy AS hre
JOIN HR.Employees e
	ON (e.empid = hre.mgrid)

--5. Write a solution using a recursive CTE that returns the management chain leading to Zoya Dolgopyatova (employee ID 9)

;
WITH EmployeeRoot (empid, firstname, lastname, mgrid)
AS
(SELECT
		e.empid
	   ,e.firstname
	   ,e.lastname
	   ,e.mgrid
	FROM HR.Employees AS e
	WHERE e.empid = 9
	UNION ALL
	SELECT
		em.empid
	   ,em.firstname
	   ,em.lastname
	   ,em.mgrid
	FROM HR.Employees AS em
	JOIN EmployeeRoot ee
		ON (ee.mgrid = em.empid)
	WHERE em.empid IS NOT NULL)
SELECT
	er.empid
   ,er.firstname
   ,er.lastname
   ,er.mgrid
FROM EmployeeRoot er


--6. Write a query that returns orders with the maximum order date for each employee.
--solution without function - shorter and more faster according to execution plan 
SELECT
	o.orderid
   ,o.custid
   ,o.empid
   ,o.orderdate
   ,MAX(o.orderdate) OVER (PARTITION BY o.empid ORDER BY o.empid) AS MaxOrderDateForEmployee
FROM Sales.Orders AS o

--solution with function
USE TestSQL

GO

CREATE FUNCTION Sales.fn_GetMaxDate (@EmpId AS INT)
RETURNS DATETIME WITH SCHEMABINDING
AS
BEGIN

	DECLARE @MaxDate AS DATETIME;

	SELECT
		@MaxDate = MAX(o.orderdate)
	FROM Sales.Orders AS o
	WHERE o.empid = @EmpId

	RETURN (@MaxDate);
END;

GO

SELECT
	o.orderid
   ,o.custid
   ,o.empid
   ,o.orderdate
   ,Sales.fn_GetMaxDate(o.empid) AS MaxOrderDateForEmployee
FROM Sales.Orders AS o

--to keep DB clean
DROP FUNCTION Sales.fn_GetMaxDate

--7. Return two most expensive products per each supplier

;
WITH cteMAX
AS
(SELECT
		p.supplierid
	   ,p.productid
	   ,p.productname
	   ,p.unitprice
	   ,ROW_NUMBER() OVER (PARTITION BY p.supplierid ORDER BY p.unitprice DESC) rn
	FROM Production.Products AS p
	JOIN Production.Suppliers s
		ON (s.supplierid = p.supplierid))
SELECT
	cp.supplierid
   ,cp.productid
   ,cp.productname
   ,cp.unitprice
FROM cteMAX AS cp
WHERE rn <= 2


--8. Create an inline table-valued function. Input should be a supplier ID (@supid AS INT) and a requested number of products (@n AS INT).
--The function should return @n products with the highest unit price that are supplied by the given supplier ID

USE TestSQL

GO

CREATE FUNCTION Production.fn_TopProducts (@supid AS INT,
@n AS INT)
RETURNS TABLE WITH SCHEMABINDING
AS
	RETURN (SELECT TOP (@n)
			p.productid
		   ,p.productname
		   ,p.unitprice
		FROM Production.Products AS p
		WHERE p.supplierid = @supid
		ORDER BY p.unitprice DESC)

GO

SELECT
	*
FROM Production.fn_TopProducts(5, 2)


--9. Using the function you have created in previous exercise, return two most expensive products per each supplier

SELECT
	s.supplierid
   ,p.productid
   ,p.productname
   ,p.unitprice
FROM Production.Suppliers s
CROSS APPLY Production.fn_TopProducts(s.supplierid, 2) AS p
ORDER BY s.supplierid

--to keep DB clean
DROP FUNCTION Production.fn_TopProducts

GO