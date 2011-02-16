<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%
try {
String connectionURL = "jdbc:mysql://[DBHOST]:3306/[DBNAME]";
Connection connection = null;
Class.forName("com.mysql.jdbc.Driver").newInstance();
connection = DriverManager.getConnection(connectionURL, "[DBUSER]", "[DBPASS]");
if(!connection.isClosed())
    out.println("DB=UP");
    connection.close();
} catch(Exception ex){
    out.println("DB=DOWN");
}
%>