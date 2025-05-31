Use AdventureWorks2022
Go

-- Query 1

-- Firstly select Sales.SalesOrderDetail to see the table details and I used relationships to find the details about table

Select * From Sales.SalesOrderDetail

-- Now lets build a Store Procuder 

Select SalesOrderID, ProductID, UnitPrice, UnitPriceDiscount From Sales.SalesOrderDetail
Select SafetyStockLevel From Production.Product
Select * From Production.ProductInventory

Select * from Sales.SpecialOffer

-- Sales.SalesOrderDetail has SalesOrderId, ProductID, UnitPrice, UnitPriceDiscount
-- Production.Product has SafetyStockLevel


CREATE PROCEDURE sp_InsertOrderDetails
    @SalesOrderID INT,
    @ProductID INT,
    @Quantity INT,
    @Discount MONEY = 0.00 -- discount is optional, defaults to zero
AS
BEGIN
    SET NOCOUNT ON;  -- Avoid extra message outputs for cleaner execution

    -- Variables to hold important data we'll fetch and use
    DECLARE @UnitPrice MONEY;
    DECLARE @CurrentStock INT;
    DECLARE @ReorderLevel INT;
    DECLARE @OfferID INT;

    /*
    Find the most recent unit price for the product.
    We look at past sales details because they usually have the latest valid price.
    If no price found, we can't proceed with the order.
    */
    SELECT TOP 1 @UnitPrice = UnitPrice
    FROM Sales.SalesOrderDetail
    WHERE ProductID = @ProductID
    ORDER BY SalesOrderDetailID DESC;

    IF @UnitPrice IS NULL
    BEGIN
        PRINT 'Error: Could not find a price for this product.';
        RETURN;  -- Stop the procedure if no price found
    END

    /*
    Find a special offer ID for the product, if any.
    This links the product to any ongoing promotions.
    If none found, stop because we need this info for the order.
    */
    SELECT TOP 1 @OfferID = sop.SpecialOfferID
    FROM Sales.SpecialOfferProduct AS sop
    JOIN Sales.SpecialOffer AS so ON sop.SpecialOfferID = so.SpecialOfferID
    WHERE sop.ProductID = @ProductID
    ORDER BY sop.SpecialOfferID;

    IF @OfferID IS NULL
    BEGIN
        PRINT 'Error: No special offer found for this product.';
        RETURN;
    END

    /*
    Check current stock level of the product.
    We get the quantity available in inventory so we know if we can fulfill this order.
    */
    SELECT @CurrentStock = Quantity
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID;

    IF @CurrentStock IS NULL
    BEGIN
        PRINT 'Error: Product not found in inventory.';
        RETURN;
    END

    /*
    Make sure we have enough stock to cover the order quantity.
    If stock is insufficient, stop and notify.
    */
    IF @CurrentStock < @Quantity
    BEGIN
        PRINT 'Error: Insufficient stock to complete this order.';
        RETURN;
    END

    /*
    Insert the new order detail record.
    We include all info such as product, quantity, price, discount, and offer ID.
    */
    INSERT INTO Sales.SalesOrderDetail (
        SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount, SpecialOfferID
    )
    VALUES (
        @SalesOrderID, @ProductID, @Quantity, @UnitPrice, @Discount, @OfferID
    );

    /*
    Update the stock quantity by subtracting the ordered amount.
    This keeps inventory accurate.
    */
    UPDATE Production.ProductInventory
    SET Quantity = Quantity - @Quantity
    WHERE ProductID = @ProductID;

    /*
    Check if stock after this order falls below the safety (reorder) level.
    If yes, print a warning so the team knows to reorder stock soon.
    */
    SELECT @ReorderLevel = SafetyStockLevel
    FROM Production.Product
    WHERE ProductID = @ProductID;

    IF (@CurrentStock - @Quantity) < @ReorderLevel
    BEGIN
        PRINT 'Warning: Stock has dropped below the reorder level!';
    END

    PRINT 'Order recorded successfully and inventory updated.';
END;



--------------------------------------------------------------------
--------------Testing the Stored Procedure--------------------------
--------------------------------------------------------------------

-- Test the stored procedure with a sample SalesOrderID and ProductID
-- Before running the procedure, ensure you have a valid SalesOrderID and ProductID 

-- Get a sample SalesOrderID
SELECT TOP 5 SalesOrderID FROM Sales.SalesOrderHeader ORDER BY SalesOrderID DESC;

-- Check a valid ProductID that has a price and offer
SELECT TOP 5 ProductID FROM Sales.SalesOrderDetail ORDER BY SalesOrderDetailID DESC;

-- Check if there's a special offer for a product
SELECT TOP 5 * FROM Sales.SpecialOfferProduct;

-- Check inventory
SELECT TOP 5 * FROM Production.ProductInventory ORDER BY Quantity DESC;
EXEC sp_InsertOrderDetails
    @SalesOrderID = 43659,  -- Replace with your real SalesOrderID
    @ProductID = 776,
    @Quantity = 1;


SELECT Quantity FROM Production.ProductInventory
WHERE ProductID = 776;



--- Clean up: Drop the stored procedure after testing
DROP PROCEDURE sp_InsertOrderDetails;



---------------------------------------------------------------------
---------------------------query 2-----------------------------------
---------------------------------------------------------------------

CREATE PROCEDURE sp_UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT = NULL,
    @Discount MONEY = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Store original values for conditional update and inventory adjustment
    DECLARE @OldQuantity INT;

    -- Get the current quantity for this order detail
    SELECT @OldQuantity = OrderQty
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    -- Update the order detail, only changing values that are not NULL
    UPDATE Sales.SalesOrderDetail
    SET
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        OrderQty = ISNULL(@Quantity, OrderQty),
        UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    -- If quantity changed, update inventory accordingly
    IF @Quantity IS NOT NULL AND @OldQuantity IS NOT NULL
    BEGIN
        DECLARE @QuantityDiff INT = @OldQuantity - @Quantity;
        UPDATE Production.ProductInventory
        SET Quantity = Quantity + @QuantityDiff
        WHERE ProductID = @ProductID;
    END

    PRINT 'Order detail updated successfully.';
END;

---------------------------------------------------------------------
-- Testing the sp_UpdateOrderDetails stored procedure-------------------
---------------------------------------------------------------------


-- Pick an existing SalesOrderID and ProductID from your data
DECLARE @OrderID INT = (SELECT TOP 1 SalesOrderID FROM Sales.SalesOrderDetail);
DECLARE @ProductID INT = (SELECT TOP 1 ProductID FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID);

-- Show the current values BEFORE the update
SELECT 
    SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

-- Start a transaction so we can roll back the change after testing
BEGIN TRANSACTION;

-- Run the stored procedure to update the UnitPrice
EXEC sp_UpdateOrderDetails
    @OrderID = @OrderID,
    @ProductID = @ProductID,
    @UnitPrice = 99.99;  -- Set a test price

-- Show the new values AFTER the update
SELECT 
    SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

-- Undo the test change (so your data is not altered)
ROLLBACK TRANSACTION;


-- Clean up: Drop the stored procedure after testing
DROP PROCEDURE sp_UpdateOrderDetails;

---------------------------------------------------------------------
---------------------------query 3-----------------------------------
---------------------------------------------------------------------


CREATE PROCEDURE sp_GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Select all records for the given OrderID
    SELECT *
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID;

    -- If no records found, print message and return 1
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR(20)) + ' does not exits';
        RETURN 1;
    END
END;

----------------------------------------------------------------------
-- Testing the sp_GetOrderDetails stored procedure
----------------------------------------------------------------------
-- Test 1: Existing OrderID (should return rows)
DECLARE @ExistingOrderID INT = (SELECT TOP 1 SalesOrderID FROM Sales.SalesOrderDetail);

PRINT '--- Test 1: Existing OrderID ---';
EXEC sp_GetOrderDetails @OrderID = @ExistingOrderID;
PRINT '-------------------------------';

-- Test 2: Non-existing OrderID (should print message and return 1)
PRINT '--- Test 2: Non-existing OrderID ---';
EXEC sp_GetOrderDetails @OrderID = -99999;  -- Assumed not to exist
PRINT '------------------------------------';

-- Clean up: Drop the stored procedure after testing
DROP PROCEDURE sp_GetOrderDetails;


---------------------------------------------------------------------
---------------------------query 4-----------------------------------
---------------------------------------------------------------------

CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate that the OrderID and ProductID combination exists
    IF NOT EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
    )
    BEGIN
        PRINT 'Invalid parameters: Either the OrderID does not exist or the ProductID is not part of this order.';
        RETURN -1;
    END

    -- Delete the order detail row
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    PRINT 'Order detail deleted successfully.';
END;

----------------------------------------------------------------------
-- Testing the DeleteOrderDetails stored procedure
----------------------------------------------------------------------
-- Test 1: Valid OrderID and ProductID (should delete one row)
DECLARE @OrderID INT = (SELECT TOP 1 SalesOrderID FROM Sales.SalesOrderDetail);
DECLARE @ProductID INT = (SELECT TOP 1 ProductID FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID);

PRINT '--- Test 1: Valid parameters ---';
-- Show the row before deletion
SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

-- Execute the procedure (expect success)
EXEC DeleteOrderDetails @OrderID = @OrderID, @ProductID = @ProductID;

-- Show the row after deletion (should be gone)
SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
PRINT '-------------------------------';

-- Test 2: Invalid OrderID or ProductID (should print error and return -1)
PRINT '--- Test 2: Invalid parameters ---';
EXEC DeleteOrderDetails @OrderID = -1, @ProductID = -1;  -- Assumed invalid
PRINT '----------------------------------';
-- Clean up: Drop the stored procedure after testing
DROP PROCEDURE DeleteOrderDetails;
---------------------------------------------------------------------
---------------------------query 5-----------------------------------
---------------------------------------------------------------------