<?
	include 'header.php';
	include 'myclassifiedsfuncs.php';
	$itemID = $_GET['itemID'];
	
	$query = "SELECT c.id, type, title, description, timestmp, i.id, name, phone, phonetype, email, contactpref FROM items i, contactinfo c WHERE i.id=\"$itemID\" AND c.id=\"$itemID\";";
	$info = run_query($query);
	$item = mysql_fetch_row($info);
	$phoneNum = translatePhone($item[7]);
	$phoneType = translatePhoneType($item[8]);
	$itemType = translateItemType($item[1]);
	$item[3] = nl2br($item[3]);
	$m = substr($item[4],4,2);
	$d = substr($item[4],6,2);
	$y = substr($item[4],0,4);
?>
<table width=100%>
	<tr>
		<td>
			
      <h3><a href=myclassifieds.html>home</a> -> <a href=viewitems.php?type=<? echo $item[1];?>>
        <? echo $itemType;?>
        </a> -> 
        <? echo $item[2];?>
      </h3>
    </td>
			<td align=right>[<? echo date("D d M Y  h:iA")?>]
		</td>
	</tr>
</table>
<blockquote>
<?
	if($_GET['status'] === 'done'){
		echo "<table width=90%><tr><td bgcolor='00cc00'>\n";
		echo "<font face=\"Verdana, Arial, Helvetica, sans-serif\" size=\"2\"><b>&nbsp;&nbsp;Congratulations!  Your item has been posted.</b></font>\n";
		echo "</td></tr></table>\n";
	}
	echo "\t<h1>$item[2]</h1><br>\n";
	echo "\t\t<b>Reply to:</b> $item[6]<br>\n";
	echo "\t\t<dd><b>Phone:</b> $phoneNum ($phoneType)<br>\n";
	echo "\t\t<dd><b>E-mail:</b> <a href=mailto:$item[9]>$item[9]</a><br><br>\n";
	echo "\t\t<b>Date Posted:</b> " . date("D M d", mktime (0,0,0,$m,$d,$y)) . "<br><br>\n";
	echo "\t\t<b>Description:</b><br>".$item[3]."<br><br>\n";
?>
	|&nbsp;&nbsp;<a href="item.php?action=edit&itemID=<?php echo $itemID;?>">Edit this listing</a>&nbsp;&nbsp;
	|&nbsp;&nbsp;<a href="javascript:confirm_delete('<?php echo $itemID;?>');">Remove this listing</a>&nbsp;&nbsp;|
</blockquote>
<?
include 'footer.php';
?>
