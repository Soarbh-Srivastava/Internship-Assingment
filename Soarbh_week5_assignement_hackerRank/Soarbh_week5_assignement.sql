-- Create SubjectAllotments table
CREATE TABLE SubjectAllotments (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    StudentId VARCHAR(50) NOT NULL,
    SubjectId VARCHAR(50) NOT NULL,
    Is_Valid BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Create SubjectRequest table  
CREATE TABLE SubjectRequest (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    StudentId VARCHAR(50) NOT NULL,
    SubjectId VARCHAR(50) NOT NULL,
    RequestDate DATETIME DEFAULT GETDATE()
);

-- Insert existing student records in SubjectAllotments
INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid) VALUES
('STU001', 'MATH101', 1),
('STU002', 'PHY101', 1),
('STU003', 'CHEM101', 1),
('STU004', 'BIO101', 0),  -- Previous invalid record
('STU004', 'MATH101', 1); -- Current valid record

-- Insert test requests in SubjectRequest table
INSERT INTO SubjectRequest (StudentId, SubjectId) VALUES
('STU001', 'PHY101'),     -- Existing student requesting change
('STU002', 'PHY101'),     -- Existing student requesting same subject
('STU003', 'MATH101'),    -- Existing student requesting change
('STU005', 'CHEM101'),    -- New student
('STU006', 'BIO101');     -- New student



CREATE PROCEDURE ProcessSubjectChangeRequest
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables for cursor
    DECLARE @StudentId VARCHAR(50);
    DECLARE @RequestedSubjectId VARCHAR(50);
    DECLARE @CurrentSubjectId VARCHAR(50);
    
    -- Cursor to process all pending requests
    DECLARE request_cursor CURSOR FOR
    SELECT StudentId, SubjectId 
    FROM SubjectRequest;
    
    OPEN request_cursor;
    
    FETCH NEXT FROM request_cursor INTO @StudentId, @RequestedSubjectId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if student exists in SubjectAllotments table
        SELECT @CurrentSubjectId = SubjectId 
        FROM SubjectAllotments 
        WHERE StudentId = @StudentId AND Is_Valid = 1;
        
        IF @CurrentSubjectId IS NOT NULL
        BEGIN
            -- Student exists, check if requested subject is different from current
            IF @CurrentSubjectId != @RequestedSubjectId
            BEGIN
                -- Update current valid record to invalid
                UPDATE SubjectAllotments 
                SET Is_Valid = 0 
                WHERE StudentId = @StudentId AND Is_Valid = 1;
                
                -- Insert new requested subject as valid
                INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
                VALUES (@StudentId, @RequestedSubjectId, 1);
            END
        END
        ELSE
        BEGIN
            -- Student doesn't exist, insert new record as valid
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
            VALUES (@StudentId, @RequestedSubjectId, 1);
        END
        
        -- Clear the variable for next iteration
        SET @CurrentSubjectId = NULL;
        
        FETCH NEXT FROM request_cursor INTO @StudentId, @RequestedSubjectId;
    END
    
    CLOSE request_cursor;
    DEALLOCATE request_cursor;
    
    -- Clear processed requests
    DELETE FROM SubjectRequest;
    
END
----------------------------------------------
--------------test---------------------------
---------------------------------------------  

-- Step 1: Check current subject assignments
SELECT StudentId, SubjectId, Is_Valid 
FROM SubjectAllotments 
WHERE Is_Valid = 1;

-- Step 2: Add subject change requests
INSERT INTO SubjectRequest (StudentId, SubjectId) VALUES
('STU001', 'MATH301'),  -- Student wants to change to MATH301
('STU005', 'PHY101');   -- New student requesting PHY101

-- Step 3: Verify requests were added
SELECT * FROM SubjectRequest;

-- Step 4: Process the requests using the stored procedure
EXEC ProcessSubjectChangeRequest;

-- Step 5: Verify the changes were applied
SELECT StudentId, SubjectId, Is_Valid, CreatedDate
FROM SubjectAllotments 
ORDER BY StudentId, CreatedDate;

-- Step 6: Confirm requests were processed (should be empty)
SELECT * FROM SubjectRequest;
