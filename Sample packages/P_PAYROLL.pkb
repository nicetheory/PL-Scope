create or replace PACKAGE BODY P_PAYROLL AS

  FUNCTION SalaryIsLowEnough(p_Salary IN Employees.Salary%type, 
                             p_Department_Id Employees.Department_id%type) RETURN BOOLEAN IS
    lnDepartmentManagerId Departments.Manager_Id%type;
    lnManagersSalary      Employees.Salary%type;
  BEGIN
    lnDepartmentManagerId := p_Employees.   --test on "broken" reference
    ManagerForDepartment(p_Department_Id);
    
    SELECT Salary
    INTO lnManagersSalary
    FROM Employees e 
    JOIN Departments d ON (e.Employee_Id = d.Manager_Id)
    WHERE d.Department_Id = p_Department_Id;
    
    RETURN p_Salary < lnManagersSalary;
  END;

  PROCEDURE SetSalary(p_Employee_Id Employees.Employee_Id%type,
                      p_Salary      Employees.Salary%type) AS
    loEmployee p_Employees.t_Employee;
  BEGIN
    loEmployee := p_Employees.Employee(p_Employee_Id);
    
    IF SalaryIsLowEnough(p_Salary, loEmployee.Department_Id) THEN
        UPDATE Employees
        SET Salary = p_Salary
        WHERE Employee_Id = p_Employee_Id;
    ELSE
      RAISE PROGRAM_ERROR;
    END IF;
  END SetSalary;

  PROCEDURE SetSalaryAndCommission(p_Employee_Id    Employees.Employee_Id%type,
                                   p_Salary         Employees.Salary%type,
                                   p_Commission_Pct Employees.Commission_Pct%type) AS
  BEGIN
    UPDATE Employees
    SET Salary = p_Salary,
        Commission_Pct = p_Commission_Pct
    WHERE Employee_Id = p_Employee_Id;
  END SetSalaryAndCommission;

  PROCEDURE SetCommission(p_Employee_Id    Employees.Employee_Id%type,
                          p_Commission_Pct Employees.Commission_Pct%type) AS
  BEGIN
    UPDATE Employees
    SET Commission_Pct = p_Commission_Pct
    WHERE Employee_Id = p_Employee_Id;
  END SetCommission;

END P_PAYROLL;