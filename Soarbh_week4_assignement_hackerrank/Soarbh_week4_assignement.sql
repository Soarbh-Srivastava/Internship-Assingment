use openElective
go

create table studentdetails (                             -- table to store student details
    studentid int primary key,
    studentname nvarchar(100) not null,
    gpa decimal(3,2) not null,
    branch nvarchar(10) not null,
    section char(1) not null
);

create table subjectdetails (                             -- table to store subject details
    subjectid nvarchar(30) primary key,
    subjectname nvarchar(100) not null,
    maxseats int not null,
    remainingseats int not null
);

create table studentpreference (                          -- table to store student preferences for subjects
    studentid int not null,
    subjectid nvarchar(30) not null,
    preference int not null,
    primary key (studentid, preference),
    unique (studentid, subjectid),
    foreign key (studentid) references studentdetails(studentid),
    foreign key (subjectid) references subjectdetails(subjectid),
    check (preference between 1 and 5)
);

create table allotments (                                  -- table to store the allotments of subjects to students
    subjectid nvarchar(30) not null,
    studentid int not null,
    primary key (studentid),
    foreign key (studentid) references studentdetails(studentid),
    foreign key (subjectid) references subjectdetails(subjectid)
);

create table unallottedstudents (                         -- table to store students who were not allotted any subject
    studentid int primary key,
    foreign key (studentid) references studentdetails(studentid)
);
																													-- Insert sample data into the tables
insert into studentdetails values 
(159103036, 'mohit agarwal', 8.9, 'cse', 'a'),
(159103037, 'rohit agarwal', 5.2, 'cse', 'a'),
(159103038, 'shohit garg', 7.1, 'cse', 'b'),
(159103039, 'mrinal malhotra', 7.9, 'cse', 'a'),
(159103040, 'mehreet singh', 5.6, 'cse', 'a'),
(159103041, 'arjun tehlan', 9.2, 'cse', 'b');
insert into studentdetails values 
(159103036, 'mohit agarwal', 8.9, 'cce', 'a'),
(159103037, 'rohit agarwal', 5.2, 'cce', 'a'),
(159103038, 'shohit garg', 7.1, 'cce', 'b'),
(159103039, 'mrinal malhotra', 7.9, 'cce', 'a'),
(159103040, 'mehreet singh', 5.6, 'cce', 'a'),
(159103041, 'arjun tehlan', 9.2, 'cce', 'b');

insert into subjectdetails values 
('po1491', 'basics of political science', 60, 60),
('po1492', 'basics of accounting', 120, 120),
('po1493', 'basics of financial markets', 90, 90),
('po1494', 'eco philosophy', 60, 60),
('po1495', 'automotive trends', 60, 60);

insert into studentpreference values 
(159103036, 'po1491', 1),
(159103036, 'po1492', 2),
(159103036, 'po1493', 3),
(159103036, 'po1494', 4),
(159103036, 'po1495', 5);

create trigger tr_updateseats                            -- trigger to update remaining seats in subjectdetails table
on allotments
after insert
as
begin
    update sd
    set remainingseats = remainingseats - 1
    from subjectdetails sd
    inner join inserted i on sd.subjectid = i.subjectid
    where sd.remainingseats > 0;
end
go

create procedure sp_allocateelectives                 -- stored procedure to allocate subjects to students based on preferences
as
begin
    set nocount on;
    
    begin try
        begin transaction;
        
        delete from allotments;
        delete from unallottedstudents;
        update subjectdetails set remainingseats = maxseats;
        
        declare @studentid int;
        declare @currentpreference int;
        declare @subjectid nvarchar(30);
        declare @remainingseats int;
        declare @isallocated bit;
        
        declare student_cursor cursor for
        select studentid 
        from studentdetails 
        order by gpa desc;
        
        open student_cursor;
        fetch next from student_cursor into @studentid;
        
        while @@fetch_status = 0
        begin
            set @isallocated = 0;
            set @currentpreference = 1;
            
            while @currentpreference <= 5 and @isallocated = 0
            begin
                select @subjectid = subjectid
                from studentpreference
                where studentid = @studentid and preference = @currentpreference;
                
                if @subjectid is not null
                begin
                    select @remainingseats = remainingseats
                    from subjectdetails
                    where subjectid = @subjectid;
                    
                    if @remainingseats > 0
                    begin
                        insert into allotments (subjectid, studentid)
                        values (@subjectid, @studentid);
                        
                        update subjectdetails
                        set remainingseats = remainingseats - 1
                        where subjectid = @subjectid;
                        
                        set @isallocated = 1;
                    end
                end
                
                set @currentpreference = @currentpreference + 1;
                set @subjectid = null;
            end
            
            if @isallocated = 0
            begin
                insert into unallottedstudents (studentid)
                values (@studentid);
            end
            
            fetch next from student_cursor into @studentid;
        end
        
        close student_cursor;
        deallocate student_cursor;
        
        commit transaction;
        
        select subjectid, studentid
        from allotments
        order by studentid;
        
        select studentid
        from unallottedstudents
        order by studentid;
        
    end try
    begin catch
        if @@trancount > 0
            rollback transaction;
        throw;
    end catch
end
go

exec sp_allocateelectives;       -- Execute the stored procedure to allocate subjects to students based on preferences


=-- Cleanup script to drop all tables, constraints, triggers, and stored procedures
use openElective
go

-- drop all foreign key constraints first
alter table studentpreference drop constraint if exists fk_studentpreference_studentid;
alter table studentpreference drop constraint if exists fk_studentpreference_subjectid;
alter table allotments drop constraint if exists fk_allotments_studentid;
alter table allotments drop constraint if exists fk_allotments_subjectid;
alter table unallottedstudents drop constraint if exists fk_unallottedstudents_studentid;

-- drop trigger
drop trigger if exists tr_updateseats;

-- drop stored procedure
drop procedure if exists sp_allocateelectives;

-- drop tables
drop table if exists allotments;
drop table if exists unallottedstudents;
drop table if exists studentpreference;
drop table if exists subjectdetails;
drop table if exists studentdetails;

-- alternatively, you can drop the entire database
-- drop database if exists openElective;
