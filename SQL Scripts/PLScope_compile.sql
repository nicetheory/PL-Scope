-- Setting up and compiling for PL/Scope
-- Author: Vidar Eidissen

-- Check system setting:
SELECT * FROM gv$parameter WHERE name = 'plscope_settings';
ALTER SYSTEM SET PLSCOPE_SETTINGS='IDENTIFIERS:ALL' SCOPE=BOTH;

-- PL/Scope-settings can be viewed through the %_plsql_object_settings-views:
SELECT * 
FROM user_plsql_object_settings;

SELECT NAME, TYPE, plscope_settings, plsql_ccflags
FROM user_plsql_object_settings;

-- Check the compile status of schema-objects and objects referring to our schema-objects:
SELECT type
     , plscope_settings
     , COUNT(*)
FROM all_plsql_object_settings
WHERE (OWNER, NAME, TYPE) IN (
	SELECT OWNER, NAME, TYPE
	FROM DBA_PLSQL_OBJECT_SETTINGS
    WHERE OWNER IN (USER)
    --
	UNION
	--
	SELECT OWNER, NAME, TYPE
	FROM DBA_DEPENDENCIES 
	WHERE REFERENCED_OWNER IN (USER)
)
GROUP BY type
       , plscope_settings
ORDER BY --type,
       plscope_settings;

-- Recompile objects where we are missing identifiers:
SELECT 'ALTER ' || replace( type, ' BODY' ) || ' ' || owner || '."' || name || '" COMPILE PLSCOPE_SETTINGS=''IDENTIFIERS:ALL'';'
FROM DBA_plsql_object_settings
WHERE (OWNER, NAME, TYPE) IN (
	SELECT OWNER, NAME, TYPE
	FROM DBA_PLSQL_OBJECT_SETTINGS
    WHERE OWNER IN (USER)
	--
	UNION
	--
	SELECT OWNER, NAME, TYPE
	FROM DBA_DEPENDENCIES 
	WHERE REFERENCED_OWNER IN (USER)
)
AND plscope_settings != 'IDENTIFIERS:ALL'
AND name not like 'BIN$%'
ORDER BY type
       , name;

SELECT * FROM DBA_OBJECTS;

