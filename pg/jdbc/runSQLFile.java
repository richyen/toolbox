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
import java.util.Scanner;
import java.io.File;

public class runSQLFile {

  public static void main(String[] args) throws Exception {


    Connection con = null;
    Statement st = null;
    ResultSet rs = null;

    Integer val=5;
    String url = "jdbc:edb://host:port/dbname";
    String user = "username";
    String password = "password";

    try {
      con = DriverManager.getConnection(url, user, password);
      Statement s = con.createStatement();

      System.out.println("Reading in file " + args[0]);
      String sql = new Scanner(new File(args[0])).useDelimiter("\\Z").next();
      System.out.println("Executing query");
      //System.out.println(sql);
      s.execute(sql);
      System.out.println("Successfully executed query");

    } catch (SQLException ex)
    {
      System.out.println(ex);
    }

    finally {
      try {

        if (con != null)

        {
          con.close();
        }

      } catch (SQLException ex)
      {
        System.out.println(ex);
      }
    }
  }
}
