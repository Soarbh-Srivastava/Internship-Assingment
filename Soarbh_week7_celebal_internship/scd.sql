-- SCD Type 0: Retain Original (No updates allowed)
CREATE PROCEDURE InsertCustomer_SCD0
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address)
        VALUES (@CustomerID, @CustomerName, @Address)
    END
END
GO

-- SCD Type 1: Overwrite (No History)
CREATE PROCEDURE UpsertCustomer_SCD1
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        UPDATE dbo.DimCustomer
        SET CustomerName = @CustomerName,
            Address = @Address
        WHERE CustomerID = @CustomerID
    END
    ELSE
    BEGIN
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address)
        VALUES (@CustomerID, @CustomerName, @Address)
    END
END
GO

-- SCD Type 2: Full History Versioning
CREATE PROCEDURE UpsertCustomer_SCD2
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    DECLARE @CurrentDate DATE = GETDATE();

    IF EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerID = @CustomerID AND IsCurrent = 1)
    BEGIN
        DECLARE @CurrentCustomerKey INT
        SELECT @CurrentCustomerKey = CustomerKey FROM dbo.DimCustomer WHERE CustomerID = @CustomerID AND IsCurrent = 1

        -- Close current record
        UPDATE dbo.DimCustomer
        SET EndDate = @CurrentDate, IsCurrent = 0
        WHERE CustomerKey = @CurrentCustomerKey

        -- Insert new record
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerID, @CustomerName, @Address, @CurrentDate, NULL, 1)
    END
    ELSE
    BEGIN
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerID, @CustomerName, @Address, @CurrentDate, NULL, 1)
    END
END
GO

-- SCD Type 3: Limited History (e.g., previous address)
CREATE PROCEDURE UpsertCustomer_SCD3
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        UPDATE dbo.DimCustomer
        SET PreviousAddress = Address,
            Address = @Address,
            CustomerName = @CustomerName
        WHERE CustomerID = @CustomerID
    END
    ELSE
    BEGIN
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address, PreviousAddress)
        VALUES (@CustomerID, @CustomerName, @Address, NULL)
    END
END
GO

-- SCD Type 4: History Table
-- Main table: current values, History table: all changes
CREATE PROCEDURE UpsertCustomer_SCD4
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        -- Insert old record into history table
        INSERT INTO dbo.DimCustomerHistory (CustomerID, CustomerName, Address, ChangeDate)
        SELECT CustomerID, CustomerName, Address, GETDATE()
        FROM dbo.DimCustomer
        WHERE CustomerID = @CustomerID

        -- Update main table
        UPDATE dbo.DimCustomer
        SET CustomerName = @CustomerName,
            Address = @Address
        WHERE CustomerID = @CustomerID
    END
    ELSE
    BEGIN
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address)
        VALUES (@CustomerID, @CustomerName, @Address)
    END
END
GO

-- SCD Type 6: Hybrid (Types 1 + 2 + 3)
CREATE PROCEDURE UpsertCustomer_SCD6
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    DECLARE @CurrentDate DATE = GETDATE();

    IF EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerID = @CustomerID AND IsCurrent = 1)
    BEGIN
        DECLARE @CurrentCustomerKey INT
        SELECT @CurrentCustomerKey = CustomerKey FROM dbo.DimCustomer WHERE CustomerID = @CustomerID AND IsCurrent = 1

        -- Close current record
        UPDATE dbo.DimCustomer
        SET EndDate = @CurrentDate, IsCurrent = 0
        WHERE CustomerKey = @CurrentCustomerKey

        -- Insert new record with previous address
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address, PreviousAddress, StartDate, EndDate, IsCurrent)
        SELECT @CustomerID, @CustomerName, @Address, Address, @CurrentDate, NULL, 1
        FROM dbo.DimCustomer
        WHERE CustomerKey = @CurrentCustomerKey
    END
    ELSE
    BEGIN
        INSERT INTO dbo.DimCustomer (CustomerID, CustomerName, Address, PreviousAddress, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerID, @CustomerName, @Address, NULL, @CurrentDate, NULL, 1)
    END
END
GO
