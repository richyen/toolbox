<?
include 'header.php';
include 'myclassifiedsfuncs.php';
if($_GET['action'] == 'remove'){
	removeItem($_GET['itemID']);
?>
	
<h4>Your item has been successfully removed. Return to MyClassifieds <a href=myclassifieds.html>Home 
  Page</a></h4>
<?
	include 'footer.php';
}else{	
	if($_GET['action'] == 'edit' && ($exists = itemIDExists($_GET['itemID']))){
		$id = $_GET['itemID'];
		$query = "SELECT i.id, type, title, description, timestmp, c.id, name, phone, phonetype, email, contactpref FROM items i, contactinfo c WHERE i.id=\"$id\" AND c.id=\"$id\";";
		$result = run_query($query);
		$row = mysql_fetch_row($result);
		$itemType = $row[1];
		$itemName = $row[2];
		$itemDescription = $row[3];
		$postName = $row[6];
		$postPhone = translatePhone($row[7]);
		$postPhoneType = $row[8];
		$postEmail = $row[9];
		//$postContactPref = $_GET['postContactPref'];
	}else{
		$itemName = $itemDescription = $postName = $postPhone = $postEmail = '';
		$itemType = $postPhoneType = 0;
	}
?>
	
	<html>
	<head>
		<title><? if($_GET['action']=='edit') echo "Edit Item"; else echo "Post New Item";?></title>
	</head>
	
	<body>
	<form name="item" method="post" action="submit.php" onSubmit="return validateForm();">
	<input type="hidden" name="action" value="<? 
		if($_GET['action'] == 'edit' && $exists)
			echo "edit";
		else echo "insert";?>">
	<input type="hidden" name="id" value="<? echo $_GET['itemID'];?>">
	<table width="100%">
	<tr><td height="20"></td></tr>
	<tr><td align="center">
	<table>
		<tr>
			<td colspan=2><b><u>Item Information</u></b></td>
			<td width="10" rowspan="7">&nbsp;</td>
			<td colspan=2><b><u>Your Contact Information</u></b></td>
		</tr>
		<tr>
			<td>Item Type:</td>
			<td>
				<select tabindex="1" name="itemType">
					<option value=0 <? if ($itemType==0) echo "SELECTED";?>></option>         
					<option value=1 <? if ($itemType==1) echo "SELECTED";?>>lost</option>
					<option value=2 <? if ($itemType==2) echo "SELECTED";?>>found</option>
					<option value=3 <? if ($itemType==3) echo "SELECTED";?>>wanted</option>
					<option value=4 <? if ($itemType==4) echo "SELECTED";?>>free</option>
					<option value=5 <? if ($itemType==5) echo "SELECTED";?>>jobs</option>
					<option value=6 <? if ($itemType==6) echo "SELECTED";?>>housing</option>
					<option value=7 <? if ($itemType==7) echo "SELECTED";?>>general info</option>
				</select>
			</td>
			<td>Name:</td>
			<td><input name="postName" type=text tabindex="4" value="<? echo $postName;?>" maxlength="30"></td>
		</tr>
		<tr>
			<td>Item name:</td>
			<td><input name="itemName" type=text tabindex="2" value="<? echo $itemName;?>" maxlength="100"></td>
			<td>Phone Number:</td>
			<td><input tabindex="5" type=text name="postPhone" value="<? echo $postPhone;?>"></td></tr>
		<tr>
			<td rowspan="4" valign="top">Description:</td>
			<td rowspan="4"><textarea tabindex="3" name="itemDescription" cols="50" rows="10"><? echo $itemDescription;?></textarea></td>
		</tr>
		<tr>
			<td valign="top">Phone Type:</td>
			<td valign="top">
				<select tabindex="6" name="postPhoneType" value="<? echo $postPhoneType;?>">
					<option value=0 <? if ($postPhoneType==0) echo "SELECTED";?>></option>
					<option value=1 <? if ($postPhoneType==1) echo "SELECTED";?>>home</option>
					<option value=2 <? if ($postPhoneType==2) echo "SELECTED";?>>cell</option>
					<option value=3 <? if ($postPhoneType==3) echo "SELECTED";?>>work</option>
				</select>
			</td>
		</tr>
		<tr>
			<td valign="top">Email:</td>
			<td valign="top"><input name="postEmail" type=text tabindex="7" value="<? echo $postEmail;?>" maxlength="100"></td>
		</tr>
		<!--<tr>
			<td>How do you prefer to be conacted?</td>
			<td>
				<select name="postContactPref">
						<option value="blank"></option>
						<option value=phone>phone</option>
						<option value=email>email</option>
				</select>
			</td>
		</tr>-->
		<tr>
			<td colspan="2" align="right" valign="bottom">
				<input tabindex="8" type=submit value="<? if(($_GET['action'] == 'insert') || ($_GET['action'] == '')) echo "List my item!";
											 if($_GET['action'] == 'edit') echo "Commit Edits";?>">&nbsp;&nbsp;&nbsp;
				<input tabindex="9" type=reset value="<? if(($_GET['action'] == 'insert') || ($_GET['action'] == '')) echo "Clear data";
											 if($_GET['action'] == 'edit') echo "Clear Changes";?>">
		  </td>
		</tr>
	</table>
	</td></tr></table>
	</form>
<? 
include 'footer.php';
}
?>
