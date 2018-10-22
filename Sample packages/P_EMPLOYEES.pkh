create or replace package p_employees as 

  SUBTYPE t_Employee is Employees%rowtype;

  gcUnusedConstant CONSTANT VARCHAR2(10) := 'Not in use';
  gcUsedConstant CONSTANT VARCHAR2(10) := 'In use!';

  FUNCTION AddEmployee(p_First_Name Employees.Last_Name%type,
                       p_Last_Name Employees.Last_Name%type) return number;
  
  PROCEDURE AssignEmployeeToDepartment(p_Employee_Id Employees.Employee_Id%type,
                                       p_Department_Id Employees.Department_Id%type);
  
  PROCEDURE AssignEmployeeToJob(p_Employee_Id Employees.Employee_Id%type,
                                p_Job_Id Employees.Job_Id%type);
                                
  FUNCTION Employee(p_Employee_Id Employees.Employee_Id%type) RETURN t_Employee;

  FUNCTION ManagerForDepartment(p_Department_Id Departments.Department_Id%type) return Employees.Manager_Id%type;

  PROCEDURE Heavy;


END P_EMPLOYEES;