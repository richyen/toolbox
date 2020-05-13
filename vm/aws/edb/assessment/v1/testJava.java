import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Types;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.Struct;
import java.sql.Array;
import java.math.BigDecimal;
import java.sql.*;

public class testJava {

  public static void main(String[] args) throws Exception {

    Class.forName("com.edb.Driver");
    Connection connection = null;

    String url = "jdbc:edb://127.0.0.1:5432/edb";
    String user = "enterprisedb";
    String password = "password";
    connection = DriverManager.getConnection(url,user,password);
    connection.setAutoCommit(false);
    float floatVal = (float)10000.00;
    int new_empno = 5057;
    int bad_empno = 7934;

    CallableStatement cs1 = connection.prepareCall("{? = call new_empno()}");
    cs1.registerOutParameter(1, Types.NUMERIC);
    cs1.execute();
    new_empno = cs1.getBigDecimal(1).intValueExact();

    String s1 = "INSERT INTO emp (empn, ename, job, mgr, hiredate, sal, deptno) VALUES (?,?,?,?,now(),?,?)";
    PreparedStatement ps1 = connection.prepareStatement(s);
    ps1.setInt(1,new_empno);
    ps1.setString(2,"Bob Smith");
    ps1.setString(3,"JANITOR");
    ps1.setInt(4,7521);
    ps1.setFloat(5,floatVal);
    ps1.setInt(6,10);
    ps1.execute();

    String commandText = "UPDATE emp SET sal = sal * 1.1";
    PreparedStatement ps2 = connection.prepareStatement(commandText);
    ps2.executeUpdate();

    CallableStatement cs2 = connection.prepareCall("{call emp_admin.fire_emp(?)}");
    cs2.setInt(1,bad_empno);
    cs2.execute();
    connection.commit()

    String s2 = "SELECT empno, ename, job, sal FROM emp";
    PreparedStatement ps3 = connection.prepareStatement(s2);
    ResultSet rs = cs2.executeQuery();
    while (rs.next()) {
        String name  = rs.getString("ename");
        float  sal   = rs.getFloat("sal");
        String job   = rs.getString("job");
        int    empno = rs.getInt("empID");
        System.out.printline("Employee Name: " + name);
        System.out.printline("  Number:    " + empno);
        System.out.printline("  Job Title: " + sal);
        System.out.printline("  Salary:    " + job);
    }

    try {
      if (connection != null)
      {
        connection.close();
      }
    } catch (SQLException ex)
    {
      System.out.println(ex);
    }
  }
}
