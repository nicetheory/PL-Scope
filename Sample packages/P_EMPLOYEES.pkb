create or replace PACKAGE BODY P_EMPLOYEES AS

  gcInternallyUnusedConstant CONSTANT PLS_INTEGER := 1;
  
  gnInternalGlobalNumber NUMBER;

  FUNCTION GenerateEMailAddress(p_First_Name Employees.Last_Name%type,
                                p_Last_Name Employees.Last_Name%type) return Employees.EMail%type AS
    lsEMailAddress Employees.EMail%type;
  BEGIN
    lsEMailAddress := gcUsedConstant;
    gnInternalGlobalNumber := 2;
    
    lsEMailAddress := substr(p_First_Name, 1, 1) || p_Last_Name;
    RETURN lsEmailAddress;
  END;
  
  FUNCTION ManagerForDepartment(p_Department_Id Departments.Department_Id%type) return Employees.Manager_Id%type  IS
    lnDepartmentManagerId Departments.Manager_Id%type;
    lnDepartmentManagerId2 Departments.Manager_Id%type;
  BEGIN
    SELECT Manager_Id
    INTO lnDepartmentManagerId
    FROM Departments
    WHERE department_id = p_Department_Id;
    
    --
    -- Comments for something
    --
    
    select /*this is the second one*/ manager_id into lndepartmentmanagerid2
    from departments where department_id = p_department_id;
    
    RETURN lnDepartmentManagerId;
  END;

  FUNCTION AddEmployee(p_First_Name Employees.Last_Name%type,
                       p_Last_Name Employees.Last_Name%type) return number AS
    lsEMailAddress Employees.EMail%type;
    lnEmployee_Id  Employees.Employee_Id%type;
  BEGIN
    lsEMailAddress := GenerateEmailAddress(p_First_Name, p_Last_Name);
    
    INSERT INTO Employees(First_Name, Last_Name, Email, Hire_date)
    VALUES (p_First_Name, p_Last_Name, lsEMailAddress, trunc(sysdate))
    RETURNING Employee_Id INTO lnEmployee_Id;

    RETURN lnEmployee_Id;
  END AddEmployee;

  PROCEDURE AssignEmployeeToDepartment(p_Employee_Id Employees.Employee_Id%type,
                               p_Department_Id Employees.Department_Id%type) AS
    lnDepartmentManagerId Employees.Manager_Id%type;
  BEGIN
    lnDepartmentManagerId := ManagerForDepartment(p_Department_Id);

    UPDATE Employees
    SET Department_id = p_Department_Id,
        manager_id = lnDepartmentManagerId
    WHERE employee_id = p_Employee_Id;

  END AssignEmployeeToDepartment;

  PROCEDURE AssignEmployeeToJob(p_Employee_Id Employees.Employee_Id%type,
                      p_Job_Id Employees.Job_Id%type) AS
    lrEmployee Employees%rowtype;
  BEGIN
    SELECT *
    INTO lrEmployee
    FROM Employees
    WHERE Employee_id = p_Employee_Id;
    
    lrEmployee.Job_Id := p_Job_Id;
    
    -- Rowtypes are not tracked on column-level:
    UPDATE Employees
    SET ROW = lrEmployee
    WHERE Employee_id = p_Employee_Id;
    
    COMMIT;

  END AssignEmployeeToJob;

  FUNCTION Employee(p_Employee_Id Employees.Employee_Id%type) RETURN t_Employee is
    loEmployee t_Employee;
  BEGIN
    SELECT /*p_Employees.Employee*/ *
    INTO loEmployee
    FROM Employees
    WHERE Employee_Id = p_Employee_Id;

    -- Example of code thats commented out
    /*
    SELECT /*This is actually commented out* / *
    INTO loEmployee
    FROM Employees
    WHERE Employee_Id = p_Employee_Id;
    */


    RETURN loEmployee;
  END;
  
  FUNCTION EmployeesInDepartment(p_Department_Id Employees.Department_id%type) RETURN SYS_REFCURSOR IS
    lcResult SYS_REFCURSOR;
    lsStatement VARCHAR2(1000);
  BEGIN
    -- Objects referenced in dynamic SQL are not tracked!
    lsStatement := 'SELECT * FROM Employees WHERE Department_id = :Dept_id';

    OPEN lcResult FOR lsStatement USING p_Department_id;

    RETURN lcResult;
  END;
  
  PROCEDURE FireEverybody IS
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE Employees';
  END;
  
  PROCEDURE AddToHistory IS
    lrEmpHistory Employees_History%rowtype;
  BEGIN
    -- Beware: Column usage like this is not tracked!
    lrEmpHistory.Id := 1;
    
    INSERT INTO Employees_history
    VALUES lrEmpHistory;

    INSERT INTO EmployeesHistory
    VALUES lrEmpHistory;

    COMMIT;

    FireEveryBody;
  END;
  
  FUNCTION DepartmentNameForEmployee(pEmployee_Id IN NUMBER) RETURN VARCHAR2 IS
    lsDepartmentName VARCHAR2(50);
  BEGIN
    SELECT Department_Name
    into lsDepartmentName
    FROM Employees_Departments
    WHERE Employee_id = pEmployee_id;
    RETURN lsDepartmentName;
  END;  

  PROCEDURE Heavy IS
    lnIterations CONSTANT PLS_INTEGER := 500;
    lrEmployee Employees%rowtype;
    lrDepartment Departments%rowtype;
  BEGIN
    FOR i IN 1 .. lnIterations LOOP
        FOR c IN (SELECT Employee_Id FROM Employees) LOOP
          SELECT /*Heavy*/ *
          INTO lrEmployee
          FROM Employees
          WHERE Employee_Id = c.Employee_Id;
          
          IF lrEmployee.Department_Id IS NOT NULL THEN
              SELECT /*Heavy*/ *
              INTO lrDepartment
              FROM Departments
              WHERE Department_Id = lrEmployee.Department_Id;
          END IF;
        END LOOP;
    END LOOP;
  END;

END P_EMPLOYEES;