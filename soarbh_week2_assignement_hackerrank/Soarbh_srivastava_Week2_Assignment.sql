Use AdventureWorks2022
Go

-- Query 1

-- Firstly Select Sales.SalesOrderDetail to see the table details and I used relatiOnships to find the details about table

Select * From Sales.SalesOrderDetail

-- Now lets build a Store Procuder 

Select SalesOrderID, ProductID, UnitPrice, UnitPriceDiscount From Sales.SalesOrderDetail
Select SafetyStockLevel From ProductiOn.Product
Select * From ProductiOn.ProductInventory

Select * From Sales.SpecialOffer

-- Sales.SalesOrderDetail hAs SalesOrderId, ProductID, UnitPrice, UnitPriceDiscount
-- ProductiOn.Product hAs SafetyStockLevel


Create Procedure sp_InsertOrderDetails
    @SalesOrderID INT,
    @ProductID INT,
    @Quantity INT,
    @Discount money = 0.00 -- discount is optiOnal, defaults to zero
As
Begin
    Set NOCOUNT On;  -- Avoid extra message outputs for cleaner ExecutiOn

    -- Variables to hold important data we'll fetch and use
    Declare @UnitPrice money;
    Declare @CurrentStock INT;
    Declare @ReorderLevel INT;
    Declare @OfferID INT;

    /*
    Find the most recent unit price for the product.
    We look at pAst sales details because they usually have the latest valid price.
    If no price found, we can't proceed with the order.
    */
    Select Top 1 @UnitPrice = UnitPrice
    From Sales.SalesOrderDetail
    Where ProductID = @ProductID
    Order By SalesOrderDetailID DESC;

    IF @UnitPrice IS NULL
    Begin
        Print 'Error: Could not find a price for this product.';
        RETURN;  -- STop the Procedure if no price found
    End

    /*
    Find a special offer ID for the product, if any.
    This links the product to any Ongoing promotiOns.
    If nOne found, sTop because we need this info for the order.
    */
    Select Top 1 @OfferID = sop.SpecialOfferID
    From Sales.SpecialOfferProduct As sop
    Join Sales.SpecialOffer As so On sop.SpecialOfferID = so.SpecialOfferID
    Where sop.ProductID = @ProductID
    Order By sop.SpecialOfferID;

    IF @OfferID IS NULL
    Begin
        Print 'Error: No special offer found for this product.';
        RETURN;
    End

    /*
    Check current stock level of the product.
    We get the quantity available in inventory so we know if we can fulfill this order.
    */
    Select @CurrentStock = Quantity
    From ProductiOn.ProductInventory
    Where ProductID = @ProductID;

    IF @CurrentStock IS NULL
    Begin
        Print 'Error: Product not found in inventory.';
        RETURN;
    End

    /*
    Make sure we have enough stock to cover the order quantity.
    If stock is insufficient, sTop and notify.
    */
    IF @CurrentStock < @Quantity
    Begin
        Print 'Error: Insufficient stock to complete this order.';
        RETURN;
    End

    /*
    Insert the new order detail record.
    We include all info such As product, quantity, price, discount, and offer ID.
    */
    Insert Into Sales.SalesOrderDetail (
        SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount, SpecialOfferID
    )
    Values (
        @SalesOrderID, @ProductID, @Quantity, @UnitPrice, @Discount, @OfferID
    );

    /*
    Update the stock quantity by subtracting the ordered amount.
    This keeps inventory accurate.
    */
    Update ProductiOn.ProductInventory
    Set Quantity = Quantity - @Quantity
    Where ProductID = @ProductID;

    /*
    Check if stock after this order falls below the safety (reorder) level.
    If yes, Print a warning so the team knows to reorder stock soOn.
    */
    Select @ReorderLevel = SafetyStockLevel
    From ProductiOn.Product
    Where ProductID = @ProductID;

    IF (@CurrentStock - @Quantity) < @ReorderLevel
    Begin
        Print 'Warning: Stock hAs Dropped below the reorder level!';
    End

    Print 'Order recorded successfully and inventory Updated.';
End;



--------------------------------------------------------------------
--------------Testing the Stored Procedure--------------------------
--------------------------------------------------------------------

-- Test the stored Procedure with a sample SalesOrderID and ProductID
-- Before running the Procedure, ensure you have a valid SalesOrderID and ProductID 

-- Get a sample SalesOrderID
Select Top 5 SalesOrderID From Sales.SalesOrderHeader Order By SalesOrderID DESC;

-- Check a valid ProductID that hAs a price and offer
Select Top 5 ProductID From Sales.SalesOrderDetail Order By SalesOrderDetailID DESC;

-- Check if there's a special offer for a product
Select Top 5 * From Sales.SpecialOfferProduct;

-- Check inventory
Select Top 5 * From ProductiOn.ProductInventory Order By Quantity DESC;
Exec sp_InsertOrderDetails
    @SalesOrderID = 43659,  -- Replace with your real SalesOrderID
    @ProductID = 776,
    @Quantity = 1;


Select Quantity From ProductiOn.ProductInventory
Where ProductID = 776;



--- Clean up: Drop the stored Procedure after testing
Drop Procedure sp_InsertOrderDetails;



---------------------------------------------------------------------
---------------------------query 2-----------------------------------
---------------------------------------------------------------------

Create Procedure sp_UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice money = NULL,
    @Quantity INT = NULL,
    @Discount money = NULL
As
Begin
    Set NOCOUNT On;

    -- Store original Values for cOnditiOnal Update and inventory adjustment
    Declare @OldQuantity int;

    -- Get the current quantity for this order detail
    Select @OldQuantity = OrderQty
    From Sales.SalesOrderDetail
    Where SalesOrderID = @OrderID AND ProductID = @ProductID;

    -- Update the order detail, Only changing Values that are not NULL
    Update Sales.SalesOrderDetail
    Set
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        OrderQty = ISNULL(@Quantity, OrderQty),
        UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
    Where SalesOrderID = @OrderID AND ProductID = @ProductID;

    -- If quantity changed, Update inventory accordingly
    IF @Quantity IS NOT NULL AND @OldQuantity IS NOT NULL
    Begin
        Declare @QuantityDiff int = @OldQuantity - @Quantity;
        Update ProductiOn.ProductInventory
        Set Quantity = Quantity + @QuantityDiff
        Where ProductID = @ProductID;
    End

    Print 'Order detail Updated successfully.';
End;

---------------------------------------------------------------------
-- Testing the sp_UpdateOrderDetails stored Procedure-------------------
---------------------------------------------------------------------


-- Pick an existing SalesOrderID and ProductID From your data
Declare @OrderID int = (Select Top 1 SalesOrderID From Sales.SalesOrderDetail);
Declare @ProductID int = (Select Top 1 ProductID From Sales.SalesOrderDetail Where SalesOrderID = @OrderID);

-- Show the current Values BEFORE the Update
Select 
    SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount
From Sales.SalesOrderDetail
Where SalesOrderID = @OrderID AND ProductID = @ProductID;

-- Start a transactiOn so we can roll back the change after testing
Begin TRANSACTIOn;

-- Run the stored Procedure to Update the UnitPrice
Exec sp_UpdateOrderDetails
    @OrderID = @OrderID,
    @ProductID = @ProductID,
    @UnitPrice = 99.99;  -- Set a test price

-- Show the new Values AFTER the Update
Select 
    SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount
From Sales.SalesOrderDetail
Where SalesOrderID = @OrderID AND ProductID = @ProductID;

-- Undo the test change (so your data is not altered)
ROLLBACK TRANSACTIOn;


-- Clean up: Drop the stored Procedure after testing
Drop Procedure sp_UpdateOrderDetails;

---------------------------------------------------------------------
---------------------------query 3-----------------------------------
---------------------------------------------------------------------


Create Procedure sp_GetOrderDetails
    @OrderID int
As
Begin
    Set NOCOUNT On;

    -- Select all records for the given OrderID
    Select *
    From Sales.SalesOrderDetail
    Where SalesOrderID = @OrderID;

    -- If no records found, Print message and return 1
    IF @@ROWCOUNT = 0
    Begin
        Print 'The OrderID ' + CAsT(@OrderID As VARCHAR(20)) + ' does not exits';
        RETURN 1;
    End
End;

----------------------------------------------------------------------
-- Testing the sp_GetOrderDetails stored Procedure
----------------------------------------------------------------------
-- Test 1: Existing OrderID (should return rows)
Declare @ExistingOrderID int = (Select Top 1 SalesOrderID From Sales.SalesOrderDetail);

Print '--- Test 1: Existing OrderID ---';
Exec sp_GetOrderDetails @OrderID = @ExistingOrderID;
Print '-------------------------------';

-- Test 2: NOn-existing OrderID (should Print message and return 1)
Print '--- Test 2: NOn-existing OrderID ---';
Exec sp_GetOrderDetails @OrderID = -99999;  -- Assumed not to exist
Print '------------------------------------';

-- Clean up: Drop the stored Procedure after testing
Drop Procedure sp_GetOrderDetails;


---------------------------------------------------------------------
---------------------------query 4-----------------------------------
---------------------------------------------------------------------

Create Procedure DeleteOrderDetails
    @OrderID int,
    @ProductID int
As
Begin
    Set NOCOUNT On;

    -- Validate that the OrderID and ProductID combinatiOn exists
    IF NOT EXISTS (
        Select 1 
        From Sales.SalesOrderDetail
        Where SalesOrderID = @OrderID AND ProductID = @ProductID
    )
    Begin
        Print 'Invalid parameters: Either the OrderID does not exist or the ProductID is not part of this order.';
        RETURN -1;
    End

    -- Delete the order detail row
    DELETE From Sales.SalesOrderDetail
    Where SalesOrderID = @OrderID AND ProductID = @ProductID;

    Print 'Order detail Deleted successfully.';
End;

----------------------------------------------------------------------
-- Testing the DeleteOrderDetails stored Procedure
----------------------------------------------------------------------
-- Test 1: Valid OrderID and ProductID (should delete One row)
Declare @OrderID int = (Select Top 1 SalesOrderID From Sales.SalesOrderDetail);
Declare @ProductID int = (Select Top 1 ProductID From Sales.SalesOrderDetail Where SalesOrderID = @OrderID);

Print '--- Test 1: Valid parameters ---';
-- Show the row before deletiOn
Select * From Sales.SalesOrderDetail Where SalesOrderID = @OrderID AND ProductID = @ProductID;

-- Execute the Procedure (expect success)
Exec DeleteOrderDetails @OrderID = @OrderID, @ProductID = @ProductID;

-- Show the row after deletiOn (should be gOne)
Select * From Sales.SalesOrderDetail Where SalesOrderID = @OrderID AND ProductID = @ProductID;
Print '-------------------------------';

-- Test 2: Invalid OrderID or ProductID (should Print error and return -1)
Print '--- Test 2: Invalid parameters ---';
Exec DeleteOrderDetails @OrderID = -1, @ProductID = -1;  -- Assumed invalid
Print '----------------------------------';
-- Clean up: Drop the stored Procedure after testing
Drop Procedure DeleteOrderDetails;


---------------------------------------------------------------------
---------------------------query 5-----------------------------------
---------------------------------------------------------------------


/*
For this  we need to Create a table with date in following pattern 2006-11-21 23:34:05.920
output-> 11/21/2006 mm/dd/yyyy
we will use user defined functiOn for cOnversiOn of dates
*/



Create FunctiOn dbo.udf_dateCOnversiOn
(@inputDate datetime)
Returns nvarchar(10)
As
Begin

/*
Here replace is used , As i search documentatiOn and i am not able to find 
mm-dd-yyyy but i find mm/dd/yyy.
So i used replace method to remove '/' with '-'
*/
	Return Replace(COnvert(varchar(10),@inputDate,101),'/','-')
	
End

--i tested with given input
Select dbo.udf_dateCOnversiOn('2006-11-21 23:34:05.920') As FormatedDate



---------------------------------------------------------------------
---------------------------query 6-----------------------------------
---------------------------------------------------------------------



Create FunctiOn dbo.udf_datewithoutSep
(@inputDate datetime)
Returns nvarchar(10)
As
Begin

/*
Here replace is used , As i search documentatiOn and i am not able to find 
mm-dd-yyyy but i find mm/dd/yyy.
So i used replace method to remove '/' with '-'
*/
	Return COnvert(varchar(10),@inputDate,112)
	
End

--i tested with given input
Select dbo.udf_datewithoutSep('2006-11-21 23:34:05.920') As FormatedDate


---------------------------------------------------------------------
---------------------------query 7-----------------------------------
---------------------------------------------------------------------

/*
	These are table which cOntain the column we  need 
*/
Select * From Sales.SalesOrderDetail
Select * From ProductiOn.ProductInventory 
Select * From Sales.Store

-- we have Created the vw and Join the tables 


Create View vWCustomerOrders As

Select
    ss.Name As CompanyName,
    soh.SalesOrderID As OrderID,
    soh.OrderDate,
    sod.ProductID,
    pp.Name As ProductName,
    sod.OrderQty As Quantity,
    sod.UnitPrice,
    (sod.OrderQty * sod.UnitPrice) As TotalPrice


From Sales.SalesOrderDetail sod
Join Sales.SalesOrderHeader soh
On sod.SalesOrderID = soh.SalesOrderID
Join ProductiOn.Product pp
On sod.ProductID = pp.ProductID
Join Sales.Customer sc
On soh.CustomerID = sc.CustomerID
Join Sales.Store ss
On sc.StoreID = ss.BusinessEntityID;

--testing the vwCustomerOrders

Select * From vWCustomerOrders



---------------------------------------------------------------------
---------------------------query 8-----------------------------------
---------------------------------------------------------------------

/*
	We Create a copy of view vWCustomerOrders
	As Adeventure work databAse is of 2022
	and we are in 2025
*/

Create View vWCustomerOrdersCopy As

Select
    ss.Name As CompanyName,
    soh.SalesOrderID As OrderID,
    soh.OrderDate,
    sod.ProductID,
    pp.Name As ProductName,
    sod.OrderQty As Quantity,
    sod.UnitPrice,
    (sod.OrderQty * sod.UnitPrice) As TotalPrice


From Sales.SalesOrderDetail sod
Join Sales.SalesOrderHeader soh
On sod.SalesOrderID = soh.SalesOrderID 
Join ProductiOn.Product pp
On sod.ProductID = pp.ProductID
Join Sales.Customer sc
On soh.CustomerID = sc.CustomerID
Join Sales.Store ss
On sc.StoreID = ss.BusinessEntityID;

-- CAsT(soh.OrderDate As DATE) = CAsT(DATEADD(DAY, -1, GETDATE()) As DATE);
-- As we can get data for yesterday i am checking it for any day 
Select* From vWCustomerOrdersCopy

Create VIEW vWCustomerOrdersYesterday As
Select 
    CompanyName,
    OrderID,
    CAsT(vWCustomerOrdersCopy.OrderDate As DATE) As vWDate,
    ProductID,
    ProductName,
    Quantity,
    UnitPrice,
    TotalPrice
From vWCustomerOrdersCopy
--Where vWCustomerOrdersCopy.OrderDate = '2011-05-31'
-- As adventure works2022 hAs not data of 2025 i tested it for a base case
Where vWCustomerOrdersCopy.OrderDate = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);

Select * From vWCustomerOrdersYesterday


---------------------------------------------------------------------
---------------------------query 9-----------------------------------
---------------------------------------------------------------------


Create View vMMyProduct As
Select
    ss.Name As CompanyName,
    sod.ProductID,
    pp.Name As ProductName,
    sod.OrderQty As Quantity,
    sod.UnitPrice
From Sales.SalesOrderDetail sod
Join Sales.SalesOrderHeader soh
    On sod.SalesOrderID = soh.SalesOrderID
Join ProductiOn.Product pp
    On sod.ProductID = pp.ProductID
Join Sales.Customer sc
    On soh.CustomerID = sc.CustomerID
Join Sales.Store ss
    On sc.StoreID = ss.BusinessEntityID
Where pp.SellEndDate IS NOT NULL;


Select * From vMMyProduct

---------------------------------------------------------------------
---------------------------query 10-----------------------------------
---------------------------------------------------------------------

Create TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerName NVARCHAR(100),
    OrderDate DATE
);


Create TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    UnitsInStock INT
);

Drop TABLE IF EXISTS OrderDetails;

Create TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,  -- ✅ This links to Orders
    ProductID INT,
    Quantity INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

Insert Into Orders (OrderID, CustomerName, OrderDate) Values
(1, 'Alice', '2025-05-01'),
(2, 'Bob', '2025-05-02'),
(3, 'Charlie', '2025-05-03'),
(4, 'David', '2025-05-04'),
(5, 'Eva', '2025-05-05'),
(6, 'Frank', '2025-05-06'),
(7, 'Grace', '2025-05-07'),
(8, 'Henry', '2025-05-08'),
(9, 'Ivy', '2025-05-09'),
(10, 'Jack', '2025-05-10');

Insert Into Products (ProductID, ProductName, UnitsInStock) Values
(101, 'Pen', 100),
(102, 'Notebook', 80),
(103, 'ErAser', 60),
(104, 'Pencil', 90),
(105, 'Marker', 50),
(106, 'Ruler', 70),
(107, 'Sharpener', 55),
(108, 'Glue Stick', 40),
(109, 'Scissors', 30),
(110, 'Highlighter', 45);

Insert Into OrderDetails (OrderDetailID, ProductID, Quantity) Values
(1001, 101, 10),
(1002, 102, 5),    
(1003, 103, 8),    
(1004, 104, 15),  
(1005, 105, 7), 
(1006, 106, 12),  
(1007, 107, 6),    
(1008, 108, 4),    
(1009, 109, 3),    
(1010, 110, 9);   




Create TRIGGER trg_InsteadOfDelete_Orders
On Orders
INSTEAD OF DELETE
As
Begin
    DELETE From OrderDetails
    Where OrderID IN (Select OrderID From Deleted);

    DELETE From Orders
    Where OrderID IN (Select OrderID From Deleted);

End;

DELETE From Orders Where OrderID = 5;

Select * From Orders Where OrderID = 5;
Select * From OrderDetails Where OrderID = 5;


----------------------------------------------------------------------
-- Clean up: Drop the tables and trigger after testing
Drop Trigger trg_InsteadOfDelete_Orders;
Drop Table If Exists OrderDetails;
Drop Table If Exists Orders;
Drop Table If Exists Products;
---------------------------------------------------------------------
---------------------------query 11-----------------------------------
---------------------------------------------------------------------
Create TRIGGER trg_CheckStock_BeforeInsert
On OrderDetails
INSTEAD OF Insert
AS
Begin
    Declare @ProductID INT, @Quantity INT, @Stock INT;

    Select @ProductID = ProductID, @Quantity = Quantity
    FROM InsertED;

    -- Get current stock
    Select @Stock = UnitsInStock
    FROM Products
    Where ProductID = @ProductID;

    IF @Stock >= @Quantity
    Begin
        -- Enough stock, proceed with Insert
        Insert Into OrderDetails (OrderDetailID, OrderID, ProductID, Quantity)
        Select OrderDetailID, OrderID, ProductID, Quantity
        FROM InsertED;

        -- Deduct stock
        Update Products
        Set UnitsInStock = UnitsInStock - @Quantity
        Where ProductID = @ProductID;
    End
    Else
    Begin
        -- Insufficient stock
        Throw 50000, 'Order cannot be placed. Insufficient stock.', 1;
    End
End;

----------------------------------------------------------------------
-- Testing the trg_CheckStock_BeforeInsert trigger
----------------------------------------------------------------------

-- Try Inserting an order that can be fulfilled
Insert Into OrderDetails (OrderDetailID, OrderID, ProductID, Quantity)
Values (2001, 1, 101, 5);  -- Assuming ProductID 101 has at least 5 in stock

-- Try Inserting an order with too much quantity
Insert Into OrderDetails (OrderDetailID, OrderID, ProductID, Quantity)
Values (2002, 1, 101, 500);  -- Assuming stock < 500 → will trigger error
