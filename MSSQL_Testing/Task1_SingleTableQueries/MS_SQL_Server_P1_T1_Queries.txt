--1 Return orders placed in June 2007. 
select so.orderid, so.orderdate, so.custid, so.empid
from Sales.Orders so
where MONTH(so.orderdate) = 6
  and YEAR(so.orderdate) = 2007;

--2	Return employees with last name containing the letter 'a' twice or more
select he.empid, he.firstname, he.lastname
from HR.Employees he
where he.lastname LIKE '%a%a%';

--3 Return orders with total value(qty*unitprice) greater than 10000 sorted by total value
select sod.orderid, sum(sod.qty*sod.unitprice) as totalvalue
from sales.OrderDetails sod
group by sod.orderid
having sum(sod.qty*sod.unitprice) > 10000
order by totalvalue

--4 Return the three ship countries with the highest average freight in 2007
select TOP(3) so.shipcountry, avg(so.freight) as avgfreight
from Sales.Orders so
where YEAR(so.shippeddate) = 2007
group by so.shipcountry
order by avgfreight desc;

--5 Calculate row numbers per each customer based on order date ordering.
select so.custid, so.orderdate, row_number() over(partition by so.custid order by so.orderdate) as rownum
from Sales.Orders so;

--6 Figure out and return for each employee the gender based on the title of courtesy. Ms. and Mrs. are Female; Mr. is Male; Dr. is Unknown.
select he.empid, he.firstname, he.lastname, he.titleofcourtesy, 
CASE WHEN he.titleofcourtesy in ('Ms.','Mrs.') THEN 'Female'
WHEN he.titleofcourtesy = 'Mr.' THEN 'Male'
WHEN he.titleofcourtesy = 'Dr.' THEN 'Unknown'
ELSE he.titleofcourtesy END as gender
from HR.Employees he;

--7 Return customers and regions. Sort the rows in the output by region having NULLs sort last (after non-NULL values)
select sc.custid, sc.region
from Sales.Customers sc
order by CASE WHEN sc.region IS NULL THEN 1 ELSE 0 END;

--8	Return the list of employees sorted by their hire date. Show only 5 employees, skipping first two records
select he.empid, he.lastname, he.firstname, he.hiredate
from HR.Employees he
order by he.hiredate DESC
OFFSET 2 ROWS FETCH NEXT 5 ROWS ONLY; 

--9 Return customers that have more than 20 orders
select so.custid, count(so.orderid)
from Sales.Orders so
group by so.custid
having count(so.orderid) > 20;