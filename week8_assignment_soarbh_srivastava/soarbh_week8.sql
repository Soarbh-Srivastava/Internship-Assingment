CREATE TABLE DateDimension (
    [Date] DATE PRIMARY KEY,
    CalendarDay INT,
    CalendarMonth INT,
    CalendarQuarter INT,
    CalendarYear INT,
    DayNameLong VARCHAR(20),
    DayNameShort VARCHAR(10),
    DayNumberOfWeek INT,
    DayNumberOfYear INT,
    FiscalWeek INT,
    FiscalPeriod INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalYearPeriod INT
);
INSERT INTO DateDimension (
    [Date],
    CalendarDay,
    CalendarMonth,
    CalendarQuarter,
    CalendarYear,
    DayNameLong,
    DayNameShort,
    DayNumberOfWeek,
    DayNumberOfYear,
    FiscalWeek,
    FiscalPeriod,
    FiscalQuarter,
    FiscalYear,
    FiscalYearPeriod
) VALUES
('2020-01-01', 1, 1, 1, 2020, 'Wednesday', 'Wed', 4, 1, 1, 1, 1, 2020, 202001),
('2020-01-02', 2, 1, 1, 2020, 'Thursday', 'Thu', 5, 2, 1, 1, 1, 2020, 202001),
('2020-01-03', 3, 1, 1, 2020, 'Friday', 'Fri', 6, 3, 1, 1, 1, 2020, 202001),
('2020-01-04', 4, 1, 1, 2020, 'Saturday', 'Sat', 7, 4, 1, 1, 1, 2020, 202001),
('2020-01-05', 5, 1, 1, 2020, 'Sunday', 'Sun', 1, 5, 1, 1, 1, 2020, 202001),
('2020-01-06', 6, 1, 1, 2020, 'Monday', 'Mon', 2, 6, 2, 1, 1, 2020, 202001),
('2020-01-07', 7, 1, 1, 2020, 'Tuesday', 'Tue', 3, 7, 2, 1, 1, 2020, 202001),
('2020-01-08', 8, 1, 1, 2020, 'Wednesday', 'Wed', 4, 8, 2, 1, 1, 2020, 202001),
('2020-01-09', 9, 1, 1, 2020, 'Thursday', 'Thu', 5, 9, 2, 1, 1, 2020, 202001),
('2020-01-10', 10, 1, 1, 2020, 'Friday', 'Fri', 6, 10, 2, 1, 1, 2020, 202001);

CREATE PROCEDURE PopulateDateDimensionForYear
    @InputDate DATE
AS
BEGIN
    -- Calculate start and end of the year
    DECLARE @YearStart DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @YearEnd DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    -- Insert all dates for the year with computed attributes
    INSERT INTO DateDimension (
        [Date],
        CalendarDay,
        CalendarMonth,
        CalendarQuarter,
        CalendarYear,
        DayNameLong,
        DayNameShort,
        DayNumberOfWeek,
        DayNumberOfYear,
        FiscalWeek,
        FiscalPeriod,
        FiscalQuarter,
        FiscalYear,
        FiscalYearPeriod
    )
    SELECT
        D,
        DAY(D) AS CalendarDay,
        MONTH(D) AS CalendarMonth,
        DATEPART(QUARTER, D) AS CalendarQuarter,
        YEAR(D) AS CalendarYear,
        DATENAME(WEEKDAY, D) AS DayNameLong,
        LEFT(DATENAME(WEEKDAY, D), 3) AS DayNameShort,
        DATEPART(WEEKDAY, D) AS DayNumberOfWeek,
        DATEPART(DAYOFYEAR, D) AS DayNumberOfYear,
        DATEPART(WEEK, D) AS FiscalWeek,
        MONTH(D) AS FiscalPeriod,
        DATEPART(QUARTER, D) AS FiscalQuarter,
        YEAR(D) AS FiscalYear,
        CAST(YEAR(D) AS VARCHAR(4)) + RIGHT('0' + CAST(MONTH(D) AS VARCHAR(2)), 2) AS FiscalYearPeriod
    FROM (
        SELECT DATEADD(DAY, number, @YearStart) AS D
        FROM master..spt_values
        WHERE type = 'P'
          AND DATEADD(DAY, number, @YearStart) <= @YearEnd
    ) AS Dates
END

