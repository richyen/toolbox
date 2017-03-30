<?
include 'myclassifiedsfuncs.php';
include 'header.php';
$type = $_GET['type'];
$textType = translateItemType($type);
?>
<table width=100%>
	<tr>
		<td>
			
      <h3><a href=myclassifieds.html>home</a> -> 
        <? echo $textType;?>
      </h3>
    </td>
			<td align=right>[<? echo date("D d M Y  h:iA")?>]
		</td>
	</tr>
</table>
<?
echo "<blockquote>\n\t<table width=90%>";
for ($days = 0; $days < 30; $days++){
	$query = "SELECT id, type, title, description, timestmp FROM items WHERE type=$type AND to_days(timestmp)=to_days(date_sub(NOW(),INTERVAL $days DAY));";
	$result = run_query($query);
	$row = mysql_fetch_row($result);
	if ($row[0] == ""){
		continue;
	}else{
		$query2 = "SELECT date_sub(NOW(),INTERVAL $days DAY);";
		$result2 = run_query($query2);
		$showDate = mysql_fetch_row($result2);
		$m = substr($showDate[0],5,2);
		$d = substr($showDate[0],8,2);
		$y = substr($showDate[0],0,4);	
		$rowDate = date("D M d", mktime(0,0,0,$m,$d,$y));
		echo "<tr><td colspan=2 bgcolor=cccccc>&nbsp;&nbsp;&nbsp;$rowDate</td></tr>\n";
		while($row[0]){
			echo "<tr>\n";
			echo "\t<td width=10>&nbsp;</td>\n";
			echo "\t<td>&nbsp;&nbsp;&nbsp;<a href=viewitem.php?itemID=$row[0]>$row[2]</a></td></tr>\n";
			echo "<tr><td colspan=2 height=3></td></tr>\n";
			$row = mysql_fetch_row($result);
		}
		echo "<tr><td colspan=2 height=5></td></tr>\n";
	}
}
echo "\t</table>\n</blockquote>\n";
include 'footer.php';
?>
