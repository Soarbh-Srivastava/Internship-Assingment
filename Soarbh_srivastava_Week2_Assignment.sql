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


DROP PROCEDURE sp_InsertOrderDetails;



