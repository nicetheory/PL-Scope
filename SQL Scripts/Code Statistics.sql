-- Can we say something about the code quality/maintainability
-- by using metrics from PL/Scope?

-- How many lines are there in each package?
SELECT Object_Name, Object_Type, MAX(Line)
FROM User_Identifiers
WHERE Object_Type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY', 'TRIGGER')
GROUP BY Object_Name, Object_Type;

-- Note the Usage_Context_Id for internal functions
SELECT * --Object_Name, Object_Type, MAX(Line)
FROM User_Identifiers
WHERE USAGE = 'DEFINITION'
ORDER BY Line;

-- There's an implicit Declaration for internal functions on the same line as the definition
SELECT * --Object_Name, Object_Type, MAX(Line)
FROM User_Identifiers
WHERE Object_Name = 'P_EMPLOYEES'
AND Name = 'ADDTOHISTORY'
ORDER BY LINE;

-- To find the lengths of the procedures, we find the Definitions and calculate
-- an estimated end line
SELECT Name, Signature, Object_Name, Object_Type, Line, 
  LEAD(Line, 1) OVER ( ORDER BY LINE) NextProcStart
FROM User_Identifiers
WHERE USAGE = 'DEFINITION'
AND Type IN ('FUNCTION', 'PROCEDURE')
ORDER BY Object_Name, Line;


-- Using max(Line) from all_Identifiers for the last procedure
-- doesn't quite match but it's close enough
SELECT Name, Signature, Object_Name, Object_Type, Line StartLine,
  NVL(
    LEAD(Line, 1) OVER ( ORDER BY LINE)-2, 
    (SELECT MAX (Line) - 2 FROM User_Identifiers ui WHERE ui.Object_Name = i.Object_Name AND ui.Object_Type = i.Object_Type)
  )
  LastLine
FROM User_Identifiers i
WHERE USAGE = 'DEFINITION'
AND Type IN ('FUNCTION', 'PROCEDURE')
ORDER BY Object_Name, Line;


-- Could use user_source though:
-- But if you have an initialization section - that'll set the estimate off.
SELECT Name, Signature, Object_Name, Object_Type, Line StartLine,
  NVL(
    LEAD(Line, 1) OVER ( ORDER BY LINE)-2, 
    (SELECT MAX (Line) - 2 FROM User_source s WHERE s.Name = i.Object_Name AND s.Type = i.Object_Type)
  )
  LastLine
FROM User_Identifiers i
WHERE USAGE = 'DEFINITION'
AND Type IN ('FUNCTION', 'PROCEDURE')
ORDER BY Object_Name, Line;

-- So we'll stick to user_identifiers and can now list out the length of the procedures and functions:
-- Long ones may have need to be broken up for maintainability
WITH MyProcedures AS (
    SELECT Name, Signature, Object_Name, Object_Type, Line StartLine,
      NVL(
        LEAD(Line, 1) OVER ( ORDER BY LINE)-2, 
        (SELECT MAX (Line) FROM User_Identifiers ui WHERE ui.Object_Name = i.Object_Name AND ui.Object_Type = i.Object_Type)
      )
      LastLine
    FROM User_Identifiers i
    WHERE USAGE = 'DEFINITION'
    AND Type IN ('FUNCTION', 'PROCEDURE')
)
SELECT Name, Object_Name, Object_Type, LastLine - StartLine AS ProcLength
FROM MyProcedures
ORDER BY LastLine - StartLine DESC;

