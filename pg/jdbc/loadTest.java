import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Types;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.Struct;
import java.sql.Array;
import java.math.BigDecimal;
import java.sql.*;

public class loadTest {

  public static void main(String[] args) throws Exception {
    int max_conn = Integer.parseInt(args[0]);
    Connection[] conarr = new Connection[max_conn];
    Connection c = null;
    Class.forName("org.postgresql.Driver");
    String url = "jdbc:postgresql://127.0.0.1:5432/postgres";
    String user = "postgres";
    String password = "o1234";

    try {
      System.out.println("started looping");
      for (int i = 0; i < max_conn; i++) {
        c = DriverManager.getConnection(url,user,password);
        c.setClientInfo("ApplicationName","richyen");
        System.out.println("Established Connection #" + i);
        conarr[i] = runquery(c);
      }
      System.out.println("finished looping");
    } catch (SQLException ex)
    {
      System.out.println("State: " + ex.getSQLState() +
          "\nMessage: " + ex.getMessage());

    }
    Thread.sleep(Integer.parseInt(args[1]));
    for (int i = 0; i < max_conn; i++) {
      if (conarr[i] != null)

      {
        conarr[i].close();
      }

    }
  }

  public static Connection runquery(Connection conn) throws Exception {
    try {
      String t = "SELECT 1";
      PreparedStatement s = conn.prepareStatement(t);
      ResultSet rs = s.executeQuery();
      System.out.println("ran query: SELECT 1");
    } catch (SQLException ex)
    {
      System.out.println("State: " + ex.getSQLState() +
          "\nMessage: " + ex.getMessage());

    }
    return conn;
  }

}
