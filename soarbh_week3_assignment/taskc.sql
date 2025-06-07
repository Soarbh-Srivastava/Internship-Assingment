Use javalearn
go

-------------------------------------------------------------
----------------------task 1----------------------------------
--------------------------------------------------------------

-- Create Projects Table
Create Table Projects (
    Task_ID INTEGER PRIMARY KEY,
    Start_Date DATE NOT NULL,
    End_Date DATE NOT NULL
);

-- Insert sample data
Insert Into Projects VALUES 
(1, '2015-10-01', '2015-10-02'),
(2, '2015-10-02', '2015-10-03'),
(3, '2015-10-03', '2015-10-04'),
(4, '2015-10-13', '2015-10-14'),
(5, '2015-10-14', '2015-10-15'),
(6, '2015-10-28', '2015-10-29'),
(7, '2015-10-30', '2015-10-31');

-- Query to find project groupings based on consecutive dates
WITH Numbered AS (
Select Task_ID, Start_Date, End_Date, ROW_NUMBER() OVER (ORDER BY Start_Date) AS rn
From Projects
), WithGroups AS (
Select Task_ID, Start_Date, End_Date, DATEADD(DAY, -rn, Start_Date) AS grp
From Numbered
), ProjectRanges AS (
Select MIN(Start_Date) AS project_start, MAX(End_Date) AS project_end, DATEDIFF(DAY, MIN(Start_Date), MAX(End_Date)) AS duration
From WithGroups
GROUP BY grp
)
Select project_start, project_end
From ProjectRanges
ORDER BY duration, project_start;


-------------------------------------------------------------
----------------------task 2----------------------------------
--------------------------------------------------------------

-- Create Students Table
Create Table Students (
ID INTEGER PRIMARY KEY,
Name VARCHAR(50) NOT NULL
);

-- Create Friends Table
Create Table Friends (
ID INTEGER PRIMARY KEY,
Friend_ID INTEGER,
FOREIGN KEY (ID) References Students(ID),
FOREIGN KEY (Friend_ID) References Students(ID)
);

-- Create Packages Table
Create Table Packages (
    ID INTEGER PRIMARY KEY,
    Salary DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (ID) References Students(ID)
);

-- Insert sample data
Insert Into Students VALUES 
(1, 'Ashley'), (2, 'Samantha'), (3, 'Julia'), (4, 'Scarlet');

Insert Into Friends VALUES 
(1, 2), (2, 3), (3, 4), (4, 1);

Insert Into Packages VALUES 
(1, 15.20), (2, 10.06), (3, 11.55), (4, 12.12);

-- Query to find students whose friends earn more
Select s.Name
From Students s
join Friends f ON s.ID = f.ID
join Packages p1 ON s.ID = p1.ID
join Packages p2 ON f.Friend_ID = p2.ID
WHERE p2.Salary > p1.Salary
ORDER BY p2.Salary;

--------------------------------------------------------------
----------------------task 3----------------------------------
--------------------------------------------------------------


-- Create Functions Table
Create Table Functions (
    X INTEGER NOT NULL,
    Y INTEGER NOT NULL
);

-- Insert sample data
Insert Into Functions VALUES 
(20, 20), (20, 20), (20, 21), (23, 22), (22, 23), (21, 20);

-- Query to find symmetric pairs
Select DISTINCT f1.X, f1.Y
From Functions f1
join


 Functions f2 ON f1.X = f2.Y AND f1.Y = f2.X
WHERE f1.X <= f1.Y
ORDER BY f1.X;

--------------------------------------------------------------
----------------------task 4----------------------------------
--------------------------------------------------------------

-- Main contest Table
Create Table contests (
    contest_id int primary key,
    hacker_id int not null,
    name varchar(100) not null
);

-- Colleges participating in contests
Create Table colleges (
    college_id int primary key,
    contest_id int not null,
    foreign key (contest_id) References contests(contest_id)
);

-- Challenges within each college
Create Table challenges (
    challenge_id int primary key,
    college_id int not null,
    foreign key (college_id) References colleges(college_id)
);

-- Submission statistics for each challenge
Create Table submission_stats (
    challenge_id int not null,
    total_submissions int default 0,
    total_accepted_submissions int default 0,
    foreign key (challenge_id) References challenges(challenge_id)
);

-- View statistics for each challenge
Create Table view_stats (
    challenge_id int not null,
    total_views int default 0,
    total_unique_views int default 0,
    foreign key (challenge_id) References challenges(challenge_id)
);







-- Insert sample contests
Insert Into contests values 
(66406, 17973, 'world codesprint 5'),
(66556, 79153, 'university codesprint 3');

-- Insert sample colleges
Insert Into colleges values 
(11219, 66406),
(32473, 66556);

-- Insert sample challenges
Insert Into challenges values 
(18765, 11219),
(47127, 32473);

-- Insert sample submission stats
Insert Into submission_stats values 
(18765, 111, 39),
(47127, 24, 4);

-- Insert sample view stats
Insert Into view_stats values 
(18765, 200, 150),
(47127, 312, 10);


Select 
    con.contest_id, 
    con.hacker_id, 
    con.name,
    SUM(COALESCE(ss.total_submissions, 0)) As total_submissions,
    SUM(COALESCE(ss.total_accepted_submissions, 0)) As total_accepted_submissions,
    SUM(COALESCE(vs.total_views, 0)) As total_views,
    SUM(COALESCE(vs.total_unique_views, 0)) As total_unique_views
From Contests con
join

 Colleges col ON con.contest_id = col.contest_id
join

 Challenges cha ON col.college_id = cha.college_id
LEFT join

 (
    Select 
        challenge_id, 
        SUM(total_submissions) As total_submissions,
        SUM(total_accepted_submissions) As total_accepted_submissions
    From Submission_Stats 
    GROUP BY challenge_id
) ss ON cha.challenge_id = ss.challenge_id
LEFT join

 (
    Select 
        challenge_id,
        SUM(total_views) As total_views,
        SUM(total_unique_views) As total_unique_views
    From View_Stats 
    GROUP BY challenge_id
) vs ON cha.challenge_id = vs.challenge_id
GROUP BY con.contest_id, con.hacker_id, con.name
HAVING 
    SUM(COALESCE(ss.total_submissions, 0)) + 
    SUM(COALESCE(ss.total_accepted_submissions, 0)) + 
    SUM(COALESCE(vs.total_views, 0)) + 
    SUM(COALESCE(vs.total_unique_views, 0)) > 0
ORDER BY con.contest_id;

---------------------------------------------------------------
----------------------task 5----------------------------------
---------------------------------------------------------------

-- Create Hackers Table
Create Table Hackers (
    hacker_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Create Submissions Table
Create Table Submissions (
    submission_date DATE,
    submission_id INT PRIMARY KEY,
    hacker_id INT,
    score INT,
    FOREIGN KEY (hacker_id) References Hackers(hacker_id)
);


-- Insert sample hackers
Insert Into Hackers (hacker_id, name) VALUES
(15758, 'Rose'),
(20703, 'Angela'),
(36396, 'Frank'),
(38289, 'Patrick'),
(44065, 'Lisa'),
(53473, 'Kimberly'),
(62529, 'Bonnie'),
(79722, 'Michael');

-- Insert sample submissions (6-day sample data)
Insert Into Submissions (submission_date, submission_id, hacker_id, score) VALUES
('2016-03-01', 8494, 20703, 0),
('2016-03-01', 22403, 53473, 15),
('2016-03-01', 23965, 79722, 60),
('2016-03-01', 30173, 36396, 70),
('2016-03-02', 34928, 20703, 0),
('2016-03-02', 38740, 15758, 60),
('2016-03-02', 42769, 79722, 25),
('2016-03-02', 44364, 79722, 60),
('2016-03-03', 45440, 20703, 0),
('2016-03-03', 49050, 36396, 70),
('2016-03-03', 50273, 79722, 5),
('2016-03-04', 50344, 20703, 0),
('2016-03-04', 51360, 44065, 90),
('2016-03-04', 54404, 53473, 65),
('2016-03-04', 61533, 79722, 15),
('2016-03-05', 72852, 20703, 0),
('2016-03-05', 74546, 38289, 0),
('2016-03-05', 76487, 62529, 0),
('2016-03-05', 82439, 36396, 10),
('2016-03-05', 90006, 36396, 40),
('2016-03-06', 90404, 20703, 0);


Select 
    submission_date,
    (Select COUNT(DISTINCT hacker_id) 
     From Submissions s2 
     WHERE s2.submission_date <= s1.submission_date
     AND s2.hacker_id IN (
         Select hacker_id 
         From Submissions s3 
         WHERE s3.submission_date <= s1.submission_date
         GROUP BY hacker_id 
         HAVING COUNT(DISTINCT submission_date) = DATEDIFF(day, '2016-03-01', s1.submission_date) + 1
     )) As consistent_hackers,
    (Select hacker_id 
     From Submissions s4 
     WHERE s4.submission_date = s1.submission_date
     GROUP BY hacker_id 
     ORDER BY COUNT(submission_id) DESC, hacker_id AsC 
     OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) As top_hacker_id,
    (Select h.name 
     From Hackers h 
     WHERE h.hacker_id = (
         Select hacker_id 
         From Submissions s5 
         WHERE s5.submission_date = s1.submission_date
         GROUP BY hacker_id 
         ORDER BY COUNT(submission_id) DESC, hacker_id AsC 
         OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
     )) As top_hacker_name
From (Select DISTINCT submission_date From Submissions 
      WHERE submission_date BETWEEN '2016-03-01' AND '2016-03-15') s1
ORDER BY submission_date;

--------------------------------------------------------------
----------------------task 6----------------------------------
--------------------------------------------------------------


-- Create STATION Table
Create Table STATION (
    ID INT PRIMARY KEY,
    CITY VARCHAR(21) NOT NULL,
    STATE VARCHAR(2) NOT NULL,
    LAT_N DECIMAL(10,4) NOT NULL,
    LONG_W DECIMAL(10,4) NOT NULL
);

-- Insert sample data
Insert Into STATION (ID, CITY, STATE, LAT_N, LONG_W) VALUES
(1, 'CityA', 'CA', 20.0000, 30.0000),
(2, 'CityB', 'NY', 25.0000, 35.0000),
(3, 'CityC', 'TX', 15.0000, 25.0000),
(4, 'CityD', 'FL', 30.0000, 40.0000),
(5, 'CityE', 'WA', 18.5000, 28.7500),
(6, 'CityF', 'NV', 22.3000, 33.2000);






-- TAsk 6 Solution: Manhattan Distance
Select 
    CAsT(
        ABS(MAX(LAT_N) - MIN(LAT_N)) + ABS(MAX(LONG_W) - MIN(LONG_W))
        As DECIMAL(10,4)
    ) As manhattan_distance
From STATION;


--`--------------------------------------------------------------
----------------------task 7----------------------------------
--------------------------------------------------------------

-- TAsk 7 Solution: Prime Numbers up to 1000
WITH Numbers As (
    Select 2 As Number
    UNION ALL
    Select Number + 1
    From Numbers
    WHERE Number < 1000
),
Primes As (
    Select Number
    From Numbers
    WHERE NOT EXISTS (
        Select 1
        From Numbers n
        WHERE n.Number > 1 
        AND n.Number < Numbers.Number 
        AND Numbers.Number % n.Number = 0
    )
)
Select STRING_AGG(CAsT(Number As VARCHAR), '&') As PrimeNumbers
From Primes
OPTION (MAXRECURSION 1000);



----------------------------------------------------------------
----------------------task 8----------------------------------
----------------------------------------------------------------

-- Create OCCUPATIONS Table
Create Table OCCUPATIONS (
    Name VARCHAR(50) NOT NULL,
    Occupation VARCHAR(20) NOT NULL
);

-- Insert sample data
Insert Into OCCUPATIONS (Name, Occupation) VALUES
('Samantha', 'Doctor'),
('Julia', 'Actor'),
('Maria', 'Actor'),
('Meera', 'Singer'),
('Ashley', 'Professor'),
('Ketty', 'Professor'),
('Christeen', 'Professor'),
('Jane', 'Actor'),
('Jenny', 'Doctor'),
('Priya', 'Singer');




-- TAsk 8 Solution: Occupation Pivot
WITH ranked_occupations As (
    Select 
        Name, 
        Occupation,
        ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) As row_num
    From OCCUPATIONS
)
Select 
    MAX(CAsE WHEN Occupation = 'Doctor' THEN Name END) As Doctor,
    MAX(CAsE WHEN Occupation = 'Professor' THEN Name END) As Professor,
    MAX(CAsE WHEN Occupation = 'Singer' THEN Name END) As Singer,
    MAX(CAsE WHEN Occupation = 'Actor' THEN Name END) As Actor
From ranked_occupations
GROUP BY row_num
ORDER BY row_num;




---------------------------------------------------------------
----------------------task 9----------------------------------
---------------------------------------------------------------




-- Create BST Table
Create Table BST (
    N INT NOT NULL,
    P INT NULL
);

-- Insert sample data
Insert Into BST (N, P) VALUES
(1, 2),
(3, 2),
(6, 8),
(9, 8),
(2, 5),
(8, 5),
(5, NULL);




-- TAsk 9 Solution: Binary Tree Node ClAssification
Select 
    N,
    CAsE 
        WHEN P IS NULL THEN 'Root'
        WHEN N IN (Select DISTINCT P From BST WHERE P IS NOT NULL) THEN 'Inner'
        ELSE 'Leaf'
    END As node_type
From BST
ORDER BY N;


----------------------------------------------------------------
----------------------task 10----------------------------------
----------------------------------------------------------------


-- Create Company Hierarchy Tables
Create Table Company (
    company_code VARCHAR(10) PRIMARY KEY,
    founder VARCHAR(50) NOT NULL
);

Create Table Lead_Manager (
    lead_manager_code VARCHAR(10) PRIMARY KEY,
    company_code VARCHAR(10) NOT NULL,
    FOREIGN KEY (company_code) References Company(company_code)
);

Create Table Senior_Manager (
    senior_manager_code VARCHAR(10) PRIMARY KEY,
    lead_manager_code VARCHAR(10) NOT NULL,
    company_code VARCHAR(10) NOT NULL,
    FOREIGN KEY (company_code) References Company(company_code)
);

Create Table Manager (
    manager_code VARCHAR(10) PRIMARY KEY,
    senior_manager_code VARCHAR(10) NOT NULL,
    lead_manager_code VARCHAR(10) NOT NULL,
    company_code VARCHAR(10) NOT NULL,
    FOREIGN KEY (company_code) References Company(company_code)
);

Create Table Employee (
    employee_code VARCHAR(10) PRIMARY KEY,
    manager_code VARCHAR(10) NOT NULL,
    senior_manager_code VARCHAR(10) NOT NULL,
    lead_manager_code VARCHAR(10) NOT NULL,
    company_code VARCHAR(10) NOT NULL,
    FOREIGN KEY (company_code) References Company(company_code)
);

-- Insert sample data
Insert Into Company VALUES ('C1', 'Monika'), ('C2', 'Samantha');

Insert Into Lead_Manager VALUES ('LM1', 'C1'), ('LM2', 'C2');

Insert Into Senior_Manager VALUES 
('SM1', 'LM1', 'C1'), 
('SM2', 'LM1', 'C1'), 
('SM3', 'LM2', 'C2');

Insert Into Manager VALUES 
('M1', 'SM1', 'LM1', 'C1'), 
('M2', 'SM3', 'LM2', 'C2'), 
('M3', 'SM3', 'LM2', 'C2');

Insert Into Employee VALUES 
('E1', 'M1', 'SM1', 'LM1', 'C1'), 
('E2', 'M1', 'SM1', 'LM1', 'C1'), 
('E3', 'M2', 'SM3', 'LM2', 'C2'), 
('E4', 'M3', 'SM3', 'LM2', 'C2');


-- More efficient solution using only Employee Table
Select 
    c.company_code,
    c.founder,
    COUNT(DISTINCT e.lead_manager_code) As lead_managers,
    COUNT(DISTINCT e.senior_manager_code) As senior_managers,
    COUNT(DISTINCT e.manager_code) As managers,
    COUNT(DISTINCT e.employee_code) As employees
From Company c
join

 Employee e ON c.company_code = e.company_code
GROUP BY c.company_code, c.founder
ORDER BY c.company_code;

---------------------------------------------------------------
----------------------task 11----------------------------------
---------------------------------------------------------------


-- Create Students Table
Create Table Students (
    ID INT PRIMARY KEY,
    Name VARCHAR(50) NOT NULL
);

-- Create Friends Table
Create Table Friends (
    ID INT PRIMARY KEY,
    Friend_ID INT NOT NULL,
    FOREIGN KEY (ID) References Students(ID)
);

-- Create Packages Table
Create Table Packages (
    ID INT PRIMARY KEY,
    Salary FLOAT NOT NULL,
    FOREIGN KEY (ID) References Students(ID)
);

-- Insert sample data
Insert Into Students (ID, Name) VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

Insert Into Friends (ID, Friend_ID) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

Insert Into Packages (ID, Salary) VALUES
(1, 15.20),
(2, 10.06),
(3, 11.55),
(4, 12.12);


-- TAsk 11 Solution: Students with Higher-Earning Friends
Select s.Name
From Students s
join

 Friends f ON s.ID = f.ID
join

 Packages p1 ON s.ID = p1.ID
join

 Packages p2 ON f.Friend_ID = p2.ID
WHERE p2.Salary > p1.Salary
ORDER BY p2.Salary;

----------------------------------------------------------------
----------------------task 12----------------------------------
----------------------------------------------------------------

-- Create Job Family Cost Table
Create Table JobFamilyCost (
    job_family VARCHAR(50) NOT NULL,
    location VARCHAR(20) NOT NULL,
    cost DECIMAL(15,2) NOT NULL,
    employee_count INT NOT NULL
);

-- Insert sample simulation data
Insert Into JobFamilyCost (job_family, location, cost, employee_count) VALUES
('Software Engineer', 'India', 2500000.00, 150),
('Software Engineer', 'International', 8500000.00, 100),
('Data Analyst', 'India', 1800000.00, 80),
('Data Analyst', 'International', 6200000.00, 60),
('Project Manager', 'India', 3200000.00, 40),
('Project Manager', 'International', 9800000.00, 35),
('DevOps Engineer', 'India', 2800000.00, 25),
('DevOps Engineer', 'International', 7500000.00, 20),
('QA Engineer', 'India', 2000000.00, 45),
('QA Engineer', 'International', 5800000.00, 30);



-- TAsk 12 Solution: Job Family Cost Ratio by Location
WITH job_family_totals As (
    Select 
        job_family,
        location,
        SUM(cost) As total_cost
    From JobFamilyCost
    GROUP BY job_family, location
),
job_family_grand_totals AS (
    Select 
        job_family,
        SUM(total_cost) as grand_total_cost
    From job_family_totals
    GROUP BY job_family
)
Select 
    jft.job_family,
    jft.location,
    jft.total_cost,
    ROUND(
        (jft.total_cost * 100.0) / jfgt.grand_total_cost, 2
    ) as cost_percentage
From job_family_totals jft
join


 job_family_grand_totals jfgt ON jft.job_family = jfgt.job_family
ORDER BY jft.job_family, jft.location;



----------------------------------------------------------------
----------------------task 13----------------------------------
----------------------------------------------------------------


-- Create Business Unit Financial Data Table
Create Table BU_Financial_Data (
    bu_id VARCHAR(10) NOT NULL,
    bu_name VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(10) NOT NULL, -- 'COST' or 'REVENUE'
    amount DECIMAL(15,2) NOT NULL
);

-- Insert sample data for multiple BUs across different months
Insert Into BU_Financial_Data (bu_id, bu_name, transaction_date, transaction_type, amount) VALUES
-- BU1 Data
('BU001', 'Technology', '2024-01-15', 'REVENUE', 500000.00),
('BU001', 'Technology', '2024-01-20', 'COST', 300000.00),
('BU001', 'Technology', '2024-02-10', 'REVENUE', 550000.00),
('BU001', 'Technology', '2024-02-25', 'COST', 320000.00),
('BU001', 'Technology', '2024-03-05', 'REVENUE', 600000.00),
('BU001', 'Technology', '2024-03-18', 'COST', 350000.00),
-- BU2 Data
('BU002', 'Marketing', '2024-01-12', 'REVENUE', 200000.00),
('BU002', 'Marketing', '2024-01-28', 'COST', 150000.00),
('BU002', 'Marketing', '2024-02-14', 'REVENUE', 220000.00),
('BU002', 'Marketing', '2024-02-22', 'COST', 160000.00),
('BU002', 'Marketing', '2024-03-08', 'REVENUE', 250000.00),
('BU002', 'Marketing', '2024-03-20', 'COST', 180000.00);


-- Task 13 Solution: Month-on-Month Cost and Revenue Ratio
WITH monthly_financials AS (
    Select 
        bu_id,
        bu_name,
        FORMAT(transaction_date, 'yyyy-MM') AS year_month,
        SUM(CASE WHEN transaction_type = 'REVENUE' THEN amount ELSE 0 END) AS total_revenue,
        SUM(CASE WHEN transaction_type = 'COST' THEN amount ELSE 0 END) AS total_cost
    From BU_Financial_Data
    GROUP BY bu_id, bu_name, FORMAT(transaction_date, 'yyyy-MM')
),
monthly_ratios AS (
    Select 
        bu_id,
        bu_name,
        year_month,
        total_revenue,
        total_cost,
        CASE 
            WHEN total_revenue > 0 THEN ROUND((total_cost * 100.0) / total_revenue, 2)
            ELSE NULL 
        END AS cost_revenue_ratio
    From monthly_financials
),
mom_comparison AS (
    Select 
        bu_id,
        bu_name,
        year_month,
        total_revenue,
        total_cost,
        cost_revenue_ratio,
        LAG(cost_revenue_ratio) OVER (PARTITION BY bu_id ORDER BY year_month) AS prev_month_ratio,
        LAG(total_revenue) OVER (PARTITION BY bu_id ORDER BY year_month) AS prev_month_revenue,
        LAG(total_cost) OVER (PARTITION BY bu_id ORDER BY year_month) AS prev_month_cost
    From monthly_ratios
)
Select 
    bu_id,
    bu_name,
    year_month,
    total_revenue,
    total_cost,
    cost_revenue_ratio AS current_cost_revenue_ratio,
    prev_month_ratio AS previous_cost_revenue_ratio,
    CASE 
        WHEN prev_month_ratio IS NOT NULL THEN 
            ROUND(cost_revenue_ratio - prev_month_ratio, 2)
        ELSE NULL 
    END AS ratio_change_points,
    CASE 
        WHEN prev_month_ratio IS NOT NULL AND prev_month_ratio > 0 THEN 
            ROUND(((cost_revenue_ratio - prev_month_ratio) * 100.0) / prev_month_ratio, 2)
        ELSE NULL 
    END AS ratio_change_percentage
From mom_comparison
ORDER BY bu_id, year_month;


--  ----------------------------------------------------------------
----------------------task 14----------------------------------
----------------------------------------------------------------

-- Create Employee Sub Band Table
Create Table Employee_SubBand (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    sub_band VARCHAR(20) NOT NULL,
    department VARCHAR(30) NOT NULL,
    hire_date DATE NOT NULL
);

-- Insert sample data
Insert Into Employee_SubBand (employee_id, employee_name, sub_band, department, hire_date) VALUES
(1, 'John Smith', 'A1', 'Technology', '2023-01-15'),
(2, 'Jane Doe', 'A2', 'Technology', '2023-02-20'),
(3, 'Mike Johnson', 'A1', 'Marketing', '2023-03-10'),
(4, 'Sarah Wilson', 'B1', 'Technology', '2023-04-05'),
(5, 'David Brown', 'A2', 'Finance', '2023-05-12'),
(6, 'Lisa Davis', 'A1', 'Technology', '2023-06-18'),
(7, 'Tom Anderson', 'B2', 'Marketing', '2023-07-22'),
(8, 'Emily Taylor', 'A2', 'Technology', '2023-08-14'),
(9, 'Chris Miller', 'B1', 'Finance', '2023-09-08'),
(10, 'Amy Garcia', 'A1', 'Marketing', '2023-10-25'),
(11, 'Robert Lee', 'B2', 'Technology', '2023-11-30'),
(12, 'Jennifer White', 'A2', 'Finance', '2023-12-15');


-- Task 14 Solution: Sub Band Headcount and Percentage
Select 
    sub_band,
    COUNT(*) AS headcount,
    ROUND(
        (COUNT(*) * 100.0) / (Select COUNT(*) From Employee_SubBand), 2
    ) AS percentage_of_total
From Employee_SubBand
GROUP BY sub_band
ORDER BY sub_band;



----------------------------------------------------------------
----------------------task 15----------------------------------
----------------------------------------------------------------


-- Create Employee Table
Create Table Employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    department VARCHAR(30) NOT NULL,
    hire_date DATE NOT NULL
);

-- Insert sample data
Insert Into Employee (employee_id, employee_name, salary, department, hire_date) VALUES
(1, 'John Smith', 95000.00, 'Technology', '2023-01-15'),
(2, 'Jane Doe', 87000.00, 'Technology', '2023-02-20'),
(3, 'Mike Johnson', 92000.00, 'Marketing', '2023-03-10'),
(4, 'Sarah Wilson', 105000.00, 'Technology', '2023-04-05'),
(5, 'David Brown', 78000.00, 'Finance', '2023-05-12'),
(6, 'Lisa Davis', 110000.00, 'Technology', '2023-06-18'),
(7, 'Tom Anderson', 85000.00, 'Marketing', '2023-07-22'),
(8, 'Emily Taylor', 98000.00, 'Technology', '2023-08-14'),
(9, 'Chris Miller', 102000.00, 'Finance', '2023-09-08'),
(10, 'Amy Garcia', 89000.00, 'Marketing', '2023-10-25'),
(11, 'Robert Lee', 115000.00, 'Technology', '2023-11-30'),
(12, 'Jennifer White', 93000.00, 'Finance', '2023-12-15');


Select 
    employee_id,
    employee_name,
    salary,
    department
From Employee e1
WHERE (
    Select COUNT(DISTINCT salary)
    From Employee e2
    WHERE e2.salary > e1.salary
) < 5;


-------------------------------------------------------------------
----------------------task 16----------------------------------
-------------------------------------------------------------------

-- Create Employee Table with columns to swap
Create Table Employee_Swap (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(30) NOT NULL
);

-- Insert sample data
Insert Into Employee_Swap (employee_id, first_name, last_name, department) VALUES
(1, 'John', 'Smith', 'Technology'),
(2, 'Jane', 'Doe', 'Marketing'),
(3, 'Mike', 'Johnson', 'Finance'),
(4, 'Sarah', 'Wilson', 'Technology'),
(5, 'David', 'Brown', 'Marketing');

-- Display original data
Select * From Employee_Swap;



-- Task 16 Solution: Swap first_name and last_name columns
UPDATE Employee_Swap 
SET first_name = last_name, 
    last_name = first_name;

-- Verify the swap
Select * From Employee_Swap;

---------------------------------------------------------------------
----------------------task 17----------------------------------
---------------------------------------------------------------------



-- Complete Task 17 Solution
-- Step 1: Create Login at Server Level
Create LOGIN TestUser 
WITH PASSWORD = 'SecurePassword123!',
     DEFAULT_DATABASE = master,
     CHECK_EXPIRATION = OFF,
     CHECK_POLICY = OFF;

-- Step 2: Create User in specific database and grant permissions
USE learn; -- Replace with your actual database name

-- Create database user
Create USER TestUser FOR LOGIN TestUser;

-- Grant db_owner permissions
ALTER ROLE db_owner ADD MEMBER TestUser;

-- Verify the user creation and permissions
Select 
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    r.name AS role_name
From sys.database_principals dp
LEFT join


 sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT join


 sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name = 'TestUser';


----------------------------------------------------------------------
----------------------task 18----------------------------------
----------------------------------------------------------------------

-- Create Employee Cost Table for BU analysis
Create Table BU_Employee_Cost (
    employee_id INT NOT NULL,
    employee_name VARCHAR(50) NOT NULL,
    bu_id VARCHAR(10) NOT NULL,
    bu_name VARCHAR(50) NOT NULL,
    cost_date DATE NOT NULL,
    monthly_cost DECIMAL(10,2) NOT NULL,
    weight_factor DECIMAL(5,2) NOT NULL -- Based on role, experience, or utilization
);

-- Insert sample data across multiple months
Insert Into BU_Employee_Cost (employee_id, employee_name, bu_id, bu_name, cost_date, monthly_cost, weight_factor) VALUES
-- January 2024 data
(1, 'John Smith', 'BU001', 'Technology', '2024-01-31', 8000.00, 1.0),
(2, 'Jane Doe', 'BU001', 'Technology', '2024-01-31', 9500.00, 1.2),
(3, 'Mike Johnson', 'BU001', 'Technology', '2024-01-31', 7500.00, 0.8),
(4, 'Sarah Wilson', 'BU002', 'Marketing', '2024-01-31', 6500.00, 1.0),
(5, 'David Brown', 'BU002', 'Marketing', '2024-01-31', 7200.00, 1.1),
-- February 2024 data
(1, 'John Smith', 'BU001', 'Technology', '2024-02-29', 8200.00, 1.0),
(2, 'Jane Doe', 'BU001', 'Technology', '2024-02-29', 9800.00, 1.2),
(3, 'Mike Johnson', 'BU001', 'Technology', '2024-02-29', 7700.00, 0.8),
(4, 'Sarah Wilson', 'BU002', 'Marketing', '2024-02-29', 6700.00, 1.0),
(5, 'David Brown', 'BU002', 'Marketing', '2024-02-29', 7400.00, 1.1),
-- March 2024 data
(1, 'John Smith', 'BU001', 'Technology', '2024-03-31', 8500.00, 1.0),
(2, 'Jane Doe', 'BU001', 'Technology', '2024-03-31', 10000.00, 1.2),
(3, 'Mike Johnson', 'BU001', 'Technology', '2024-03-31', 7900.00, 0.8),
(4, 'Sarah Wilson', 'BU002', 'Marketing', '2024-03-31', 6900.00, 1.0),
(5, 'David Brown', 'BU002', 'Marketing', '2024-03-31', 7600.00, 1.1);



-- More concise approach using window functions
Select 
    bu_id,
    bu_name,
    FORMAT(cost_date, 'yyyy-MM') AS year_month,
    ROUND(
        SUM(monthly_cost * weight_factor) / SUM(weight_factor), 2
    ) AS weighted_avg_cost,
    LAG(
        ROUND(SUM(monthly_cost * weight_factor) / SUM(weight_factor), 2)
    ) OVER (
        PARTITION BY bu_id 
        ORDER BY YEAR(cost_date), MONTH(cost_date)
    ) AS prev_month_weighted_avg,
    ROUND(
        ROUND(SUM(monthly_cost * weight_factor) / SUM(weight_factor), 2) -
        LAG(ROUND(SUM(monthly_cost * weight_factor) / SUM(weight_factor), 2)) 
        OVER (PARTITION BY bu_id ORDER BY YEAR(cost_date), MONTH(cost_date)), 2
    ) AS mom_change
From BU_Employee_Cost
GROUP BY bu_id, bu_name, cost_date
ORDER BY bu_id, cost_date;



----------------------------------------------------------------
----------------------task 19----------------------------------
----------------------------------------------------------------



-- Create EMPLOYEES Table
Create Table EMPLOYEES (
    employee_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL
);

-- Insert sample data with various salaries including zeros
Insert Into EMPLOYEES (employee_id, name, salary) VALUES
(1, 'John', 1000.00),
(2, 'Jane', 2050.00),
(3, 'Bob', 3000.00),
(4, 'Alice', 1500.00),
(5, 'Charlie', 2000.00),
(6, 'David', 1020.00),
(7, 'Emma', 2080.00),
(8, 'Frank', 3050.00),
(9, 'Grace', 1080.00),
(10, 'Henry', 2070.00);








-- Task 19 Solution: Salary Calculation Error
Select 
    CEILING(
        AVG(CAST(salary AS FLOAT)) - 
        AVG(CAST(REPLACE(CAST(salary AS VARCHAR), '0', '') AS FLOAT))
    ) AS salary_error
From EMPLOYEES;

---------------------------------------------------------------
----------------------task 20----------------------------------
---------------------------------------------------------------

-- Create source Table (contains both old and new data)
Create Table Source_Employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    department VARCHAR(30) NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    hire_date DATE NOT NULL
);

-- Create destination Table (contains only old data initially)
Create Table Destination_Employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    department VARCHAR(30) NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    hire_date DATE NOT NULL
);

-- Insert old data Into both Tables
Insert Into Source_Employee VALUES 
(1, 'John Smith', 'Technology', 75000.00, '2023-01-15'),
(2, 'Jane Doe', 'Marketing', 68000.00, '2023-02-20'),
(3, 'Mike Johnson', 'Finance', 72000.00, '2023-03-10');

Insert Into Destination_Employee VALUES 
(1, 'John Smith', 'Technology', 75000.00, '2023-01-15'),
(2, 'Jane Doe', 'Marketing', 68000.00, '2023-02-20'),
(3, 'Mike Johnson', 'Finance', 72000.00, '2023-03-10');

-- Add new data to source Table only
Insert Into Source_Employee VALUES 
(4, 'Sarah Wilson', 'Technology', 80000.00, '2024-01-05'),
(5, 'David Brown', 'Marketing', 71000.00, '2024-02-12'),
(6, 'Lisa Davis', 'Finance', 77000.00, '2024-03-18');




Insert Into Destination_Employee (employee_id, employee_name, department, salary, hire_date)
Select 
    s.employee_id,
    s.employee_name,
    s.department,
    s.salary,
    s.hire_date
From Source_Employee s
LEFT join


 Destination_Employee d ON s.employee_id = d.employee_id
WHERE d.employee_id IS NULL;
