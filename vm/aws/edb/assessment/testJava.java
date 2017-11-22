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
    int e = 5057;
    float floatVal = (float)10000.00;

    try {
      String s = "INSERT INTO emp (empno, ename, job, mgr, hiredate, sal, deptno) VALUES (?,?,?,?,now(),?,?)";
      PreparedStatement s1 = connection.prepareStatement(s);
      s1.setInt(1,e);
      s1.setString(2,"Bob Smith");
      s1.setString(3,"JANITOR");
      s1.setInt(4,7521);
      s1.setFloat(5,floatVal);
      s1.setInt(6,10);
      s1.execute();

      String t = "SELECT ename, job, sal FROM emp WHERE empno = ?";
      PreparedStatement s2 = connection.prepareStatement(t);
      s2.setInt(1,e);
      ResultSet rs = s2.executeQuery();
      while (rs.next()) {
          String name = rs.getString("ename");
          float  sal  = rs.getFloat("sal");
          String job  = rs.getString("job");
          System.out.println("Employee Name: " + name);
          System.out.println("  Job Title: " + sal);
          System.out.println("  Salary:    " + job);
      }

      String commandText = "UPDATE emp SET sal = sal * 1.1";
      PreparedStatement cs = connection.prepareStatement(commandText);
      cs.executeUpdate();
      connection.commit();

      String t2 = "SELECT ename, job, sal FROM emp WHERE empno = ?";
      PreparedStatement s3 = connection.prepareStatement(t2);
      s3.setInt(1,e);
      ResultSet rs2 = s3.executeQuery();
      while (rs2.next()) {
          String name = rs2.getString("ename");
          float  sal  = rs2.getFloat("sal");
          String job  = rs2.getString("job");
          System.out.println("Employee Name: " + name);
          System.out.println("  Job Title: " + sal);
          System.out.println("  Salary:    " + job);
      }

      String commandText2 = "DELETE FROM emp WHERE empno = ?";
      PreparedStatement cs2 = connection.prepareStatement(commandText2);
      cs2.setInt(1,e);
      cs2.executeUpdate();
      connection.commit();
    } catch (SQLException ex)
    {
      System.out.println("State: " + ex.getSQLState() +
                         "\nMessage: " + ex.getMessage());

    }

    finally {
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
}
