<?
include 'myclassifiedsfuncs.php';
	$_POST['postPhone'] = ereg_replace("[^0-9]","",$_POST['postPhone']);
	while(list($key, $val) = each($_POST)){
		if(!$val){
			$_POST[$key] = 'NULL';
		}
	}
	$args = array('type' => $_POST['itemType'], 'title' => $_POST['itemName'], 'description' => $_POST['itemDescription'], 'name' => $_POST['postName'], 'phone' => $_POST['postPhone'], 'phonetype' => $_POST['postPhoneType'], 'email' => $_POST['postEmail'], 'contactpref' => 0);	

if($_POST['action'] == 'edit'){
	$id = $_POST['id'];
	editItem($id,$args);
}else{
	$id = insertItem($args);
}
?>
<html>
<head>
<meta http-equiv="refresh" content="0;URL=viewitem.php?itemID=<? echo $id;?>&status=done">
</head>
</html>
