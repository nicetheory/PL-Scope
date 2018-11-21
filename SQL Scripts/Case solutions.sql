-- Added some extra objects to the HR schema for demo:
CREATE TABLE EMPLOYEES_HISTORY (ID NUMBER);
CREATE TABLE EMPLOYEESHISTORY (ID NUMBER);
CREATE VIEW Employees_Departments AS
SELECT e.Employee_Id, First_Name, Last_Name, Department_Name
FROM Employees e
JOIN Departments d on e.Department_Id = d.Department_Id;


SELECT TABLE_NAME FROM User_Tables;

-- Basic code base information

-- How many objects of type
select object_type, count(*)
from user_objects
group by object_type;

-- How many lines of code (user_source)
select count(*)
from user_source;

select *
from user_source;

select count(*)
from user_source
where text is not null;

select count(*)
from user_source
where trim(text) is not null;

select count(*)
from user_source
where regexp_replace(text, '[[:space:]]') is not null;

select count(*)
from user_source
where upper(text) like '%SELECT%';

select *
from user_source
where upper(text) like '%SELECT%';

-- So - we realize that using all-/user_source has its limitations
-- We quicly end up in a lot of regular expressions.

-- There are other ways to get summary info about your code:

-- User_Procedures 
select object_type, count(*)
from user_procedures
group by object_type;

SELECT *
FROM user_procedures
ORDER BY object_name, procedure_name;


-- The arguments for these (public) interfaces are available
-- through all-/user_arguments:

SELECT *
FROM   user_arguments
ORDER BY
    object_name,
    package_name,
    overload,
    position;

-- You can use user_arguments to generate append parameter statements for logger
SELECT q'[logger.append_param(loParams, ']' || argument_name || ''', ''' || argument_name || ''');', overload
FROM   user_arguments a
WHERE  package_name = upper('p_employees')
AND    object_name = upper('AssignEmployeeToJob')
AND    position > 0
ORDER  BY overload nulls first, position;

-- But - let's have a look at PL/Scopes structures
-- First: Use the PLScope_compile-script to compile your objects


select * 
from user_identifiers
order by object_name, object_type, line, usage_id;

select * 
from user_statements
order by object_name, object_type, line, usage_id;

-- To get the complete picture, you will need to put
-- these two views together:
select 'I' source, signature, object_name, object_type, usage_id, line, col, usage_context_id 
from user_identifiers
union all
select 'S' source, signature, object_name, object_type, usage_id, line, col, usage_context_id 
from user_statements
order by object_name, object_type, line, usage_id;






-- How many lines of code do we have?
-- We see that every line may appear several times,
-- but blank lines do not appear in PL/Scope
select object_name, object_type, line
from user_identifiers
union all
select object_name, object_type, line
from user_statements
order by object_type, object_name, line;

-- So to get a number on the total lines of code:
select count(*)
from (
    select object_name, object_type, line
    from user_identifiers
    union
    select object_name, object_type, line
    from user_statements
    order by object_type, object_name, line
);
-- 240.000 LOC

-- Can count from multiple schemas
select count(*)
from (
    select owner, object_name, object_type, line
    from all_identifiers
    where owner in (user, 'HR')
    union
    select owner, object_name, object_type, line
    from all_statements
    where owner in (user, 'HR')
    order by object_type, object_name, line
);


-- So - now we can easily re-explore all statements:
-- Mind you - dead code is not detected and removed here

SELECT TYPE, COUNT(*) 
FROM user_statements
GROUP BY TYPE
ORDER BY 1;

SELECT TYPE, TEXT, OBJECT_NAME, OBJECT_TYPE, LINE
FROM USER_STATEMENTS
WHERE TYPE IN ('OPEN', 'EXECUTE IMMEDIATE');

/*
CLOSE	            244
COMMIT	            2790
DELETE	            327
EXECUTE IMMEDIATE	165
FETCH	            168
INSERT	            1394
MERGE	            63
OPEN	            5483
ROLLBACK	        441
SAVEPOINT	        3
SELECT	            11587
UPDATE	            2188
*/
;

-- Explore all_identifiers
SELECT USAGE, COUNT(*) 
FROM user_identifiers
GROUP BY USAGE
ORDER BY 1;

/*
ASSIGNMENT	40069
CALL	    49219
DECLARATION	80876
DEFINITION	8489
REFERENCE	372236
*/
;

-- Combine them


-- Case solutions:
-- Where is the table Employees manipulated?


SELECT TYPE, OBJECT_NAME, OBJECT_TYPE, LINE, SQL_ID, FULL_TEXT
FROM user_statements
WHERE full_text LIKE '%EMPLOYEES%';

-- Improve with regular expressions (\W = any non-word character):

SELECT TYPE, Object_Name, Object_Type, Line, Sql_Id, Full_Text
FROM User_Statements
WHERE regexp_like(full_text, '.*\WEMPLOYEES\W.*')
ORDER BY TYPE, LINE;

-- From where is this procedure called?
SELECT *
FROM User_Identifiers I
WHERE Usage = 'DECLARATION'
AND Object_Name = 'P_EMPLOYEES'
AND Name = 'MANAGERFORDEPARTMENT';

WITH MySignature AS (
    SELECT I.Signature
    FROM User_Identifiers I
    WHERE Usage = 'DECLARATION'
    AND Object_Name = 'P_EMPLOYEES'
    AND Name = 'MANAGERFORDEPARTMENT'
)
SELECT Name, Type, Object_Name, Object_Type, Line, Usage
FROM User_Identifiers I
JOIN MySignature S ON I.SIGNATURE = S.SIGNATURE
WHERE I.Usage = 'CALL';

-- Improved with links for SQL Developer:
-- If you add the columns sdev_link_owner, sdev_link_type, sdev_link_name 
-- and (optionally) sdev_link_line, you can right-click on the result and
-- jump straight to that place in the code! Smooth!
WITH MySignature AS (
    SELECT I.SIGNATURE
    FROM ALL_IDENTIFIERS I
    WHERE USAGE = 'DECLARATION'
    AND OBJECT_NAME = 'P_EMPLOYEES'
    AND NAME = 'MANAGERFORDEPARTMENT'
)
SELECT Name
    , Type
    , Object_Name
    , Object_Type
    , Line
    , User sdev_link_owner
    , Object_Type sdev_link_type
    , Object_Name sdev_link_name
    , Line sdev_link_line
FROM User_Identifiers I
JOIN MySignature S ON I.SIGNATURE = S.SIGNATURE
WHERE I.USAGE = 'CALL';


-- Where was that procedure again?
SELECT NAME, TYPE, OBJECT_NAME, OBJECT_TYPE, LINE
FROM USER_IDENTIFIERS
WHERE NAME = 'MANAGERFORDEPARTMENT'
AND USAGE = 'DEFINITION';

--
-- Find dead code

-- All declarations of functions or procedures, packaged or standalone
SELECT Object_Type, Object_Name, Type, Name, Signature, Line
FROM ALL_IDENTIFIERS
WHERE Owner IN (USER)
AND Usage = 'DECLARATION'
AND Type IN ('FUNCTION', 'PROCEDURE')
ORDER BY Object_Type, Object_Name, Name, Line;

-- All calls
SELECT Owner, Object_Type, Object_Name, Type, Name, Signature, Line
FROM ALL_IDENTIFIERS
WHERE Owner IN (USER)
AND Usage = 'CALL';

-- Finding out what's declared, but not called is thereby easy:

-- Functions and procedures declared inside a body, but not called
-- from anywhere is for sure dead code
SELECT Object_Type, Object_Name, Type, Name, Signature, Usage, Line
FROM ALL_IDENTIFIERS
WHERE Owner IN (USER)
AND Usage = 'DECLARATION'
AND TYPE IN ('FUNCTION', 'PROCEDURE')
AND Object_Type LIKE '% BODY'
AND Signature NOT IN (
    -- These are called functions and procedures
    SELECT Signature
    FROM ALL_IDENTIFIERS
    WHERE Usage = 'CALL'
)
ORDER BY Object_Name, Object_Type, Name;


-- Find potentially dead code:
-- Functions and procedures that are declared, but not called
-- from anywhere is potentially dead code.
SELECT Object_Type, Object_Name, Type, Name, Signature, Usage, Line
FROM ALL_IDENTIFIERS
WHERE Owner IN ('HR')
AND Usage = 'DECLARATION'
AND Type IN ('FUNCTION', 'PROCEDURE')
AND Signature NOT IN (
 SELECT Signature
 FROM ALL_IDENTIFIERS
 WHERE Usage = 'CALL'
)
ORDER BY Object_Name, Object_Type, Name;



-- In our ETL package we refer columns - have any tables gotten added columns since it was written?
SELECT Name, Signature, Type, Object_Name, Usage_Id
FROM User_Identifiers
WHERE Object_Type = 'TABLE'
AND Type = 'COLUMN'
AND Object_Name IN ('DEPARTMENTS', 'EMPLOYEES')
ORDER BY Object_Name, Usage_Id;


SELECT *
FROM User_Identifiers
WHERE Usage = 'REFERENCE'
AND Type = 'COLUMN';

-- These columns are not reported as referenced anywhere:
-- however, rowtypes may be used! - See p_Employees.AssignEmployeeToJob, line 74
SELECT Name, Signature, Type, Object_Name, Usage_Id
FROM User_Identifiers
WHERE Object_Type = 'TABLE'
AND Type = 'COLUMN'
--AND Object_Name IN ('DEPARTMENTS', 'EMPLOYEES')
AND Signature NOT IN (
    SELECT Signature
    FROM User_Identifiers
    WHERE Usage = 'REFERENCE'
    AND Type = 'COLUMN'
    --AND OBJECT_NAME IN ('P_EMPLOYEES')
)
ORDER BY Object_Name, Usage_Id;
-- Note that Department_Name is actually referenced through
-- the view Employees_Departments and the function DepartmentNameForEmployee


-- Performance troubleshooting!

-- Query from statspack: Where in the code is it coming from? Is it in a loop?
--Create different statements by adding fake hints
SELECT *
FROM All_Statements
WHERE SQL_ID = 'gg9cr1wsq60fs';

-- If we modify one of the statements and add a fake hint indicating where
-- the statement is placed, it's easier for us to find it in the source code
-- Note that pure comments (no +) will be stripped away by the preprocessor

SELECT Type, Object_Name, Object_type, Line, SQL_ID, Full_Text
FROM User_Statements
WHERE Object_Name = 'P_EMPLOYEES'
ORDER BY Line;

-- Combine it with all_source to get the code around it:
SELECT * 
FROM ALL_SOURCE S
JOIN ALL_STATEMENTS ST 
ON (S.OWNER = ST.OWNER
    AND S.NAME = ST.OBJECT_NAME
    AND S.TYPE = ST.OBJECT_TYPE
    AND S.LINE BETWEEN ST.LINE - 1 AND ST.LINE + 5 )
WHERE ST.SQL_ID = 'ap8w5fx1fjr4q'
ORDER BY ST.LINE, S.OWNER, S.TYPE, S.LINE
;


-- find duplicate statements - just group by SQL_ID
SELECT Sql_Id, Type, COUNT(*)
FROM User_Statements
WHERE SQL_ID IS NOT NULL
GROUP BY SQL_ID, Type
HAVING COUNT(*) > 1;


SELECT Type, Object_Name, Object_Type, Line, Full_Text
FROM User_Statements
WHERE SQL_ID IN (
    SELECT SQL_ID
    FROM User_Statements
    WHERE SQL_ID IS NOT NULL
    GROUP BY SQL_ID
    HAVING COUNT(*) > 1
);

SELECT Type, Object_Name, Object_Type, Line, Full_Text
FROM User_Statements
WHERE Type = 'SELECT';


-- Removing publicly declared constants
-- Constants and references in the code
-- Constants have a declaration and assignment.
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'CONSTANT';

-- Just declared constants
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'CONSTANT'
AND Usage = 'DECLARATION'
ORDER BY Object_Name, Object_Type, Name;

-- Referenced constants
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'CONSTANT'
AND Usage = 'REFERENCE';

-- Declared constants that have no reference
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'CONSTANT'
AND Usage = 'DECLARATION'
AND Signature NOT IN (
    SELECT Signature
    FROM User_Identifiers
    WHERE Type = 'CONSTANT'
    AND Usage = 'REFERENCE'
)
ORDER BY Object_Name, Object_Type, Name;

-- Removing publicly declared variables
-- Variables and references in the code
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'VARIABLE';

-- Just declared varibles
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'VARIABLE'
AND Usage = 'DECLARATION'
ORDER BY Object_Name, Object_Type, Name;

-- Varables with assignments
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'VARIABLE'
AND Usage = 'ASSIGNMENT';

-- Declared variables that have no reference (not being read)
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'VARIABLE'
AND Usage = 'DECLARATION'
AND Signature NOT IN (
    SELECT Signature
    FROM User_Identifiers
    WHERE Type = 'VARIABLE'
    AND Usage = 'REFERENCE'
)
ORDER BY Object_Name, Object_Type, Name;

-- Note that a cursor variable that is opened is not an assignment
-- You won't remove that one, but it's interesting.
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'VARIABLE'
AND Usage = 'DECLARATION'
AND Signature NOT IN (
    SELECT Signature
    FROM User_Identifiers
    WHERE Type = 'VARIABLE'
    AND Usage = 'ASSIGNMENT'
)
ORDER BY Object_Name, Object_Type, Name;

-- Open for cursors just have references:
SELECT Signature, Type, Object_Name, Object_Type, Usage, Name, Line
FROM User_Identifiers
WHERE Type = 'VARIABLE'
AND Name = 'LCRESULT';

-- HTTP-response coded with varchar2 as return value - change to clob and find usages.
-- Same as from where is this procedure used
SELECT *
FROM ALL_IDENTIFIERS
WHERE OBJECT_NAME = 'P_EMPLOYEES'
AND NAME = 'MANAGERFORDEPARTMENT';

-- Find queries in a package in v$sql
-- Don't go flushing the cache on your production system - this is for demo
ALTER SYSTEM FLUSH SHARED_POOL;

BEGIN
  P_Employees.Heavy;
END;
/

-- GV$SQL has information about cached statements and their performance
SELECT
    sql_fulltext,
    executions "Executions",
    round((buffer_gets / nvl(REPLACE(executions, 0, 1), 1))) "Buffer_gets/executions",
    (cpu_time / 1000000) "CPU_Seconds",
    disk_reads "Disk_Reads",
    buffer_gets "Buffer_Gets",
    CASE
    WHEN rows_processed = 0 THEN
        NULL
    ELSE
        round((buffer_gets / nvl(REPLACE(rows_processed, 0, 1), 1)))
    END "Buffer_gets/rows_proc",
    (elapsed_time / 1000000) "Elapsed_Seconds",
    sql_id
FROM GV$SQL
ORDER BY
    buffer_gets DESC NULLS LAST;



-- By joining on the sql_id, we can find out where the statements are coming from:
SELECT
    st.type,
    st.full_text,
    st.object_type,
    st.owner,
    st.object_name,
    st.line,
    executions "Executions",
    round((buffer_gets / nvl(REPLACE(executions, 0, 1), 1))) "Buffer_gets/executions",
    (cpu_time / 1000000) "CPU_Seconds",
    disk_reads "Disk_Reads",
    buffer_gets "Buffer_Gets",
    CASE
    WHEN rows_processed = 0 THEN
        NULL
    ELSE
        round((buffer_gets / nvl(REPLACE(rows_processed, 0, 1), 1)))
    END "Buffer_gets/rows_proc",
    (elapsed_time / 1000000) "Elapsed_Seconds",
    st.sql_id,
    st.owner         sdev_link_owner,
    st.object_name   sdev_link_name,
    st.object_type   sdev_link_type,
    st.line          sdev_link_line
 FROM
     all_statements st
     JOIN gv$sql s ON st.sql_id = s.sql_id
 ORDER BY
     buffer_gets DESC NULLS LAST;
     
-- In some cases the sql text is a pl/sql-block like begin <package>.<procedure>; end;
-- We can then examine all statements in the package and get a more holistic view;

SELECT
    st.type,
    st.full_text,
    st.object_type,
    st.owner,
    st.object_name,
    st.line,
    executions "Executions",
    round((buffer_gets / nvl(REPLACE(executions, 0, 1), 1))) "Buffer_gets/executions",
    (cpu_time / 1000000) "CPU_Seconds",
    disk_reads "Disk_Reads",
    buffer_gets "Buffer_Gets",
    CASE
    WHEN rows_processed = 0 THEN
        NULL
    ELSE
        round((buffer_gets / nvl(REPLACE(rows_processed, 0, 1), 1)))
    END "Buffer_gets/rows_proc",
    (elapsed_time / 1000000) "Elapsed_Seconds",
    st.sql_id,
    st.owner         sdev_link_owner,
    st.object_name   sdev_link_name,
    st.object_type   sdev_link_type,
    st.line          sdev_link_line
 FROM
     all_statements st
     LEFT JOIN gv$sql s ON st.sql_id = s.sql_id
 WHERE
     st.object_name like upper('P_EMPLOYEES')
     AND st.owner LIKE user
 ORDER BY
     buffer_gets DESC NULLS LAST;


-- What tables does this package reference?
SELECT NAME, COUNT(*)
FROM USER_IDENTIFIERS
WHERE OBJECT_NAME = 'P_EMPLOYEES'
AND USAGE = 'REFERENCE'
AND TYPE = 'TABLE'
GROUP BY NAME
ORDER BY 1;

SELECT *
FROM USER_IDENTIFIERS
WHERE OBJECT_NAME = 'P_EMPLOYEES'
AND USAGE = 'REFERENCE'
AND TYPE = 'TABLE'
ORDER BY 1;


-- Performance: Is this function suitable for result cache?
SELECT I.OBJECT_NAME, I.OBJECT_TYPE, I.LINE, S.TEXT,
    user            sdev_link_owner,
    I.object_name   sdev_link_name,
    I.object_type   sdev_link_type
FROM USER_IDENTIFIERS I
JOIN USER_SOURCE S ON (I.OBJECT_NAME = S.NAME AND I.OBJECT_TYPE = S.TYPE AND I.LINE BETWEEN S.LINE - 3 AND S.LINE + 5)
WHERE OBJECT_NAME = 'P_EMPLOYEES'
AND I.NAME = 'MANAGERFORDEPARTMENT'
AND I.USAGE = 'CALL';

-- Search for something in all_source
-- and make it easy to jump to that part of the code with SQL Developer
-- Not really PL/Scope, but still useful
SELECT
    s.owner,
    s.name,
    s.type,
    s.line,
    s.text,
    s.owner   sdev_link_owner,
    s.name    sdev_link_name,
    s.type    sdev_link_type,
    s.line    sdev_link_line
FROM
    all_source s
WHERE
    lower(s.text) LIKE '%<expression>%'
    AND owner != '<OWNER>'
ORDER BY
    owner,
    name,
    type,
    line;


-- This set of queries are running slow. Need to add an index. Can it be unique?
-- Check inserts and updates on the table to see where the values are set.


-- Code statistics

