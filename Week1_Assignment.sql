Use AdventureWorks2017
Go
----Query 1 -> List of all the customers 

--Select * from Sales.Customer
--Select * from  Person.BusinessEntity
--Select * from Person.Person

----After inverstingation we find that we can use person id to fetch BussnessEntityId which 
----related to Person.Person Table containing info about customer name


Select 
pbe.BusinessEntityID ,
sc.CustomerID ,
pp.Title,
pp.FirstName ,
pp.MiddleName ,
pp.LastName,
pphno.PhoneNumber,
peid.EmailAddress,
pp.AdditionalContactInfo

From Sales.Customer sc
Inner Join Person.BusinessEntity pbe
On SC.PersonID = PBE.BusinessEntityID
Left Join Person.Person pp
On sc.PersonID = pp.BusinessEntityID
Left Join Person.PersonPhone pphno
On sc.PersonID = pphno.BusinessEntityID
Left Join Person.EmailAddress peid
On sc.PersonID =  peid.BusinessEntityID
Order By PersonID



-- Query 2 -> List all customer where company name end with N

--Select * From Person.Person
--Select * From Sales.Store
 
Select 
pp.BusinessEntityID,
pp.FirstName,
pp.Title,
pp.FirstName ,
pp.MiddleName ,
pp.LastName,
sst.Name
From Sales.Customer sc
Full Join Sales.Store sst
On sc.StoreID = sst.BusinessEntityID
Join Person.Person pp
on sc.PersonID = pp.BusinessEntityID
where sst.Name Like '%n'


--Query 3 -> List all customer how live in Berlin and London


--Select * From Sales.Customer
--Select * From Person.Person
--Select * From Person.BusinessEntityAddress
--Select * From Person.Address
--Select * From Person.EmailAddress


Select sc.CustomerID,
pp.FirstName,
pp.MiddleName,
pp.LastName,
pbea.AddressID,
pa.City

From Sales.Customer sc
Join Person.Person pp
On sc.PersonID = pp.BusinessEntityID

Join Person.BusinessEntityAddress pbea
On pp.BusinessEntityID = pbea.BusinessEntityID

join Person.Address pa
On pbea.AddressID = pa.AddressID
Where pa.City In ('London','Berlin')
Order By CustomerID


-- Query 4 -> List of all the customers Live in UK and USA which is United Kingdom and United Kingdom


Select sc.CustomerID,
pp.FirstName,
pp.MiddleName,
pp.LastName,
pcr.Name

From Sales.Customer sc
Join Person.Person pp
On sc.PersonID = pp.BusinessEntityID

Join Person.BusinessEntityAddress pbea
On pp.BusinessEntityID = pbea.BusinessEntityID

Join Person.Address pa
On pbea.AddressID = pa.AddressID

Join Person.StateProvince psp
On pa.StateProvinceID = psp.StateProvinceID

Join Person.CountryRegion pcr
On psp.CountryRegionCode = pcr.CountryRegionCode

Where pcr.Name In ('United States','United Kingdom')
Order by CustomerID


-- Query 5 -> List of all the Product sorted by Product name

Select
ProductID,
Name,
ProductNumber
From Production.Product pp
Order By pp.Name


-- Query 6 -> List of all the Product starting with A

Select
ProductID,
Name,
ProductNumber
From Production.Product pp
Where Name Like 'A%'

-- Query 7 -> List of all the Customer who have ever placed an order


Select Distinct
sc.PersonID,
soh.CustomerID,
pp.FirstName


From Person.Person pp
Join Sales.Customer sc
On pp.BusinessEntityID =sc.PersonID

Join Sales.SalesOrderHeader soh
On sc.CustomerID = soh.CustomerID


-- Query 8 -> List of all the Customer who live in london and have bought chai

-- IN Adventure work 2017 this no product called chai
Select 
sc.PersonID,
pp.FirstName,
pp.MiddleName,
pp.LastName,
pa.City,
ppr.Name


From Sales.Customer sc

Join Person.Person pp
On sc.PersonID = pp.BusinessEntityID
Join Person.BusinessEntityAddress pbea
On pp.BusinessEntityID = pbea.BusinessEntityID
Join Person.Address pa
On pbea.BusinessEntityID = pa.AddressID
Join Sales.SalesOrderHeader ssoh
On sc.CustomerID = ssoh.CustomerID
Join Sales.SalesOrderDetail ssod
On ssoh.SalesOrderID = ssod.SalesOrderDetailID
Join Production.Product ppr
On ssod.ProductID = ppr.ProductID

where pa.City = 'London'And ppr.Name = 'chai'



-- Query 9 -> List of customers who never place an order
-- we looking at people who are in person 

Select 
pp.BusinessEntityID,
pp.FirstName,
pp.MiddleName,
pp.LastName
From Person.Person pp
Left Join Sales.Customer sc
On pp.BusinessEntityID =sc.PersonID
Where sc.CustomerID IS NULL

--Query 10 -> list of customer who have order tofu

Select 
sc.PersonID,
pp.FirstName,
pp.MiddleName,
pp.LastName,
pa.City,
ppr.Name


From Sales.Customer sc

Join Person.Person pp
On sc.PersonID = pp.BusinessEntityID
Join Person.BusinessEntityAddress pbea
On pp.BusinessEntityID = pbea.BusinessEntityID
Join Person.Address pa
On pbea.BusinessEntityID = pa.AddressID
Join Sales.SalesOrderHeader ssoh
On sc.CustomerID = ssoh.CustomerID
Join Sales.SalesOrderDetail ssod
On ssoh.SalesOrderID = ssod.SalesOrderDetailID
Join Production.Product ppr
On ssod.ProductID = ppr.ProductID

where pa.City = 'London'
And
ppr.Name = 'Tofu'

-- Query 11 details of first order in system
Select Top 1 
soh.SalesOrderId ,
soh.OrderDate,
soh.CustomerID,
sod.ProductID,
sod.OrderQty,
sod.UnitPrice,
Sod.LineTotal
From Sales.SalesOrderHeader As soh
Join Sales.SalesOrderDetail As sod
On Soh.SalesOrderID = soh.SalesOrderID
Order By soh.OrderDate ASC

-- Query 12 Details of most expensive order
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    p.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
WHERE soh.SalesOrderID = (
    SELECT TOP 1 soh.SalesOrderID
    FROM Sales.SalesOrderHeader AS soh
    JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY soh.SalesOrderID
    ORDER BY SUM(sod.LineTotal) DESC
);

-- Query 13 for each order get orderid and avg quantity of item per order
SELECT 
    SalesOrderID AS OrderID,
    AVG(CAST(OrderQty AS FLOAT)) AS AverageQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

-- Query 14 for each order id get min and max quntity for that order

SELECT 
    SalesOrderID AS OrderID,
    MIN(OrderQty) AS MinQuantity,
    MAX(OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

-- 15. List all managers and total number of employees who report to them

WITH CurrentEmployeeDepartments AS (
    SELECT 
        edh.BusinessEntityID,
        edh.DepartmentID
    FROM HumanResources.EmployeeDepartmentHistory edh
    WHERE edh.EndDate IS NULL
),
Managers AS (
    SELECT 
        e.BusinessEntityID,
        p.FirstName,
        p.LastName,
        e.JobTitle,
        ced.DepartmentID
    FROM HumanResources.Employee e
    JOIN Person.Person p 
        ON e.BusinessEntityID = p.BusinessEntityID
    JOIN CurrentEmployeeDepartments ced 
        ON e.BusinessEntityID = ced.BusinessEntityID
    WHERE e.JobTitle LIKE '%Manager%'
)

SELECT 
    m.BusinessEntityID AS ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    m.JobTitle,
    COUNT(e.BusinessEntityID) AS TotalEmployeesReporting
FROM Managers m
LEFT JOIN CurrentEmployeeDepartments e 
    ON m.DepartmentID = e.DepartmentID
    AND m.BusinessEntityID <> e.BusinessEntityID -- exclude the manager themselves
GROUP BY 
    m.BusinessEntityID, m.FirstName, m.LastName, m.JobTitle
ORDER BY 
    TotalEmployeesReporting DESC;

-- Query 16 Get the OrderID and the total quantity for each order that has a total quantity of greater than 300
SELECT 
SalesOrderID,
SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

--Query 17 List of all orders placed on or after 1996/12/31

SELECT *
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31';

--Query 18. List of all orders shipped to Canada

SELECT soh.*
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'Canada';


--Query 19. List of all orders with order total > 200

SELECT SalesOrderID, TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 200;


-- 20. List of countries and sales made in each country

SELECT 
    cr.Name AS Country,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.BillToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;


-- 21. List of Customer ContactName and number of orders they placed

SELECT 
    p.FirstName + ' ' + p.LastName AS ContactName,
    COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName;

--22. List of customer contact names who have placed more than 3 orders

SELECT 
    p.FirstName + ' ' + p.LastName AS ContactName,
    COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) > 3;


-- 23. List of discontinued products ordered between 1/1/1997 and 1/1/1998
SELECT DISTINCT 
    p.Name, 
    p.ProductID,
    p.DiscontinuedDate
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE p.DiscontinuedDate IS NOT NULL
  AND soh.OrderDate BETWEEN '01-01-1997' and '01-01-1998'



-- 24. List of employee firstname, lastname, supervisor Firstname, Lastname


WITH CurrentDepartments AS (
    SELECT BusinessEntityID, DepartmentID
    FROM HumanResources.EmployeeDepartmentHistory
    WHERE EndDate IS NULL
),
Managers AS (
    SELECT 
        e.BusinessEntityID AS ManagerID,
        d.DepartmentID,
        p.FirstName AS ManagerFirstName,
        p.LastName AS ManagerLastName
    FROM HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    JOIN CurrentDepartments d ON e.BusinessEntityID = d.BusinessEntityID
    WHERE e.JobTitle LIKE '%Manager%'
)

SELECT 
    e.BusinessEntityID AS EmployeeID,
    pe.FirstName AS EmployeeFirstName,
    pe.LastName AS EmployeeLastName,
    m.ManagerFirstName,
    m.ManagerLastName
FROM HumanResources.Employee e
JOIN Person.Person pe ON e.BusinessEntityID = pe.BusinessEntityID
JOIN CurrentDepartments cd ON e.BusinessEntityID = cd.BusinessEntityID
LEFT JOIN Managers m ON cd.DepartmentID = m.DepartmentID
WHERE e.JobTitle NOT LIKE '%Manager%';


--25 List of Employee IDs and total sale conducted by employee
SELECT 
    SalesPersonID AS EmployeeID,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID;
-- 26  26. List of employees whose FirstName contains character 'a'
SELECT 
    p.FirstName,
    p.LastName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE p.FirstName LIKE '%a%';


-- 27. List of managers who have more than four people reporting to them


WITH CurrentDept AS (
    SELECT BusinessEntityID, DepartmentID
    FROM HumanResources.EmployeeDepartmentHistory
    WHERE EndDate IS NULL
),
Managers AS (
    SELECT e.BusinessEntityID, d.DepartmentID
    FROM HumanResources.Employee e
    JOIN CurrentDept d ON e.BusinessEntityID = d.BusinessEntityID
    WHERE e.JobTitle LIKE '%Manager%'
)
SELECT 
    m.BusinessEntityID AS ManagerID,
    COUNT(e.BusinessEntityID) AS EmployeeCount
FROM Managers m
JOIN CurrentDept e ON m.DepartmentID = e.DepartmentID
WHERE m.BusinessEntityID <> e.BusinessEntityID
GROUP BY m.BusinessEntityID
HAVING COUNT(e.BusinessEntityID) > 4;


--28. List of Orders and Product Names

SELECT 
    soh.SalesOrderID,
    p.Name AS ProductName
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID;

-- 29. List of orders placed by the best customer (highest total purchase)

WITH CustomerTotals AS (
    SELECT CustomerID, SUM(TotalDue) AS TotalSpent
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT soh.*
FROM Sales.SalesOrderHeader soh
JOIN CustomerTotals ct ON soh.CustomerID = ct.CustomerID
WHERE ct.TotalSpent = (
    SELECT MAX(TotalSpent) FROM CustomerTotals
);
-- 30. List of orders placed by customers who do not have a Fax number
SELECT *
FROM Person.PhoneNumberType;

SELECT DISTINCT soh.*
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Person.PersonPhone pp 
    ON p.BusinessEntityID = pp.BusinessEntityID
LEFT JOIN Person.PhoneNumberType pnt 
    ON pp.PhoneNumberTypeID = pnt.PhoneNumberTypeID 
WHERE pnt.Name NOT LIKE 'Fax%' OR pnt.Name IS NULL;



-- 31. List of postal codes where the product Tofu was shipped
SELECT DISTINCT a.PostalCode
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader soh ON soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
WHERE p.Name = 'Tofu';

--  32. List of product names that were shipped to France

SELECT DISTINCT p.Name AS ProductName
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader soh ON soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'France';

--33. List of product names and categories for the supplier 'Specialty Biscuits, Ltd.'
SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
WHERE v.Name = 'Specialty Biscuits, Ltd.';

-- 34. List of products that were never ordered

SELECT p.Name
FROM Production.Product p
LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE sod.ProductID IS NULL;


--  35. List of products where units in stock < 10 and units on order = 0

SELECT pi.ProductID, p.Name
FROM Production.ProductInventory pi
JOIN Production.Product p ON pi.ProductID = p.ProductID
WHERE pi.Quantity < 10
  AND (
    SELECT COALESCE(SUM(sod.OrderQty), 0)
    FROM Sales.SalesOrderDetail sod
    WHERE sod.ProductID = pi.ProductID
  ) = 0;


-- 36. List of top 10 countries by sales

SELECT TOP 10 
    cr.Name AS Country,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.BillToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;
--  37. Number of orders each employee has taken for customers with CustomerIDs between A and AO

SELECT 
    SalesPersonID,
    COUNT(SalesOrderID) AS OrderCount
FROM Sales.SalesOrderHeader
WHERE CustomerID BETWEEN 'A' AND 'AO'
GROUP BY SalesPersonID;

-- 38. Order date of the most expensive order
SELECT TOP 1 OrderDate
FROM Sales.SalesOrderHeader
ORDER BY TotalDue DESC;
--  39. Product name and total revenue from that product
SELECT 
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY Revenue DESC;

--  40. Supplier ID and number of products offered
SELECT 
    v.BusinessEntityID AS SupplierID,
    v.Name AS SupplierName,
    COUNT(DISTINCT pv.ProductID) AS ProductCount
FROM Purchasing.Vendor v
JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
GROUP BY v.BusinessEntityID, v.Name
ORDER BY SupplierName;


--41. Top ten customers based on their business
SELECT TOP 10 
    c.CustomerID,
    SUM(soh.TotalDue) AS TotalSpent
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalSpent DESC;


--  42. What is the total revenue of the company?

SELECT SUM(TotalDue) AS CompanyTotalRevenue
FROM Sales.SalesOrderHeader;