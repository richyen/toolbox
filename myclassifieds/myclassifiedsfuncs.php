<?
function generateID(){
	$ip_addr = $_SERVER['REMOTE_ADDR'];
	$ip_addr = ereg_replace("[^0-9]","",$ip_addr);
	$ip_addr = substr($ip_addr, 4);
	$rand_id = uniqid("");
	$rand_id = $rand_id.$ip_addr;

	if(strlen($rand_id) < 13){
		return(generateID());
	}else{
	$index = strlen($rand_id) - 10;
	$rand_id = substr($rand_id, $index);
	return($rand_id);
	}
}

function run_query($query) {
  $db = mysql_connect("localhost", "richyen", "cl0vis") or die("Could not connect to database!");
  mysql_select_db("richyen") or die("Could not select database: richyen!");
  $result = mysql_query($query) or die("Query failed! Query:$query --" . mysql_error());
  mysql_close($db);

  return($result);
}

function createTables(){
//  $query = "CREATE TABLE items (id VARCHAR(10) NOT NULL, type BIT, title VARCHAR(50), description TEXT, timestmp TIMESTAMP, PRIMARY KEY (id));";
//  $query2 = "CREATE TABLE contactinfo (id VARCHAR(10) NOT NULL, name VARCHAR(30), phone BIGINT(10) UNSIGNED, phonetype BIT, email VARCHAR(100), contactpref BIT, PRIMARY KEY (id));";
//run_query($query);
//echo "items created<br>\n";
//run_query($query2);
//echo "contactinfo created<br>\n";
$query3 = "LOAD DATA INFILE 'Book1.csv' INTO TABLE items FIELDS TERMINATED BY ',';";
$query4 = "LOAD DATA INFILE 'Book2.csv' INTO TABLE contactinfo FIELDS TERMINATED BY ',';";
run_query($query3);
echo "items loaded<br>\n";
run_query($query4);
echo "contactinfo loaded<br>\n";
}
//1062 is duplicate entry

function insertItem($args){
	$id = generateID();
	$query = "INSERT INTO items VALUES (\"".$id."\", ".$args['type'].", \"".$args['title']."\", \"".$args['description']."\", NOW());";
	run_query($query);
	if (mysql_errno() == 1062){
	insertItem($args);
	return;
	}else{
	$query2 = "INSERT INTO contactinfo VALUES (\"".$id."\", \"".$args['name']."\", ".$args['phone'].", ".$args['phonetype'].", \"".$args['email']."\", ".$args['contactpref'].");";
	run_query($query2);
	return $id;
	}

}

function removeItem($id){
	$query = "DELETE FROM items WHERE id=\"$id\";";
	run_query($query);
	$query2 = "DELETE FROM contactinfo WHERE id=\"$id\";";
	run_query($query2);
}

function editItem($id, $args){
	$query = "UPDATE items SET type=".$args['type'].", title=\"".$args['title']."\", description=\"".$args['description']."\" WHERE id=\"".$id."\";";
	run_query($query);
	$query2 = "UPDATE contactinfo SET name=\"".$args['name']."\", phone=".$args['phone'].", phonetype=".$args['phonetype'].", email=\"".$args['email']."\", contactpref=".$args['contactpref']." WHERE id=\"".$id."\";";
	run_query($query2);
}

function itemIDExists($id){
	$query = "SELECT id, type, title, description, timestmp FROM items WHERE id='".$id."';";
	$items = run_query($query);
	$row = mysql_fetch_row($items);
	if ($row[0] == ""){
		return false;
	}else return true;
}

function listItems($type){
	$query = "SELECT id, title, time FROM items WHERE type=".$type." ORDER BY time ASCENDING;";
	$items = run_query($query);
	//show titles sorted by date
}

function translatePhone($phone){
	if(strlen($phone)==10)
		$phone = "(" . substr($phone,0,3) . ") " . substr($phone,3,3) . "-" . substr($phone,6);
	elseif($phone!="")
		$phone = substr($phone,0,3) . "-" . substr($phone,3);
	return $phone;
}

function getCount($type){
	$query = "SELECT count(id) FROM items WHERE type=".$type.";";
	$result = run_query($query);
	$row = mysql_fetch_row($result);
	print $row[0];
}

function translatePhoneType($type){
	switch ($type){
		case 0:
			$type="";
			break;
		case 1:
			$type="home";
			break;
		case 2:
			$type="cell";
			break;
		case 3:
			$type="work";
			break;
		default:
			break;
	}
	return $type;
}

function translateItemType($type){
	switch ($type){
		case 0:
			$type="";
			break;
		case 1:
			$type="lost";
			break;
		case 2:
			$type="found";
			break;
		case 3:
			$type="wanted items";
			break;
		case 4:
			$type="free stuff";
			break;
		case 5:
			$type="jobs";
			break;			
		case 6:
			$type="housing";
			break;		
		case 7:
			$type="general info";
			break;		
		default:
			$type="";
			break;
	}
	return $type;
}
/*  Test Random ID Generator
function rand_test(){
$count = 0;
for($i=0; $i<100; $i++){
$rand_id[$i] = generateID();
}

for($i=0;$i<100;$i++){
	for($j=($i+1);$j<100;$j++){
		if(!strcmp($rand_id[$i], $rand_id[$j])){
			echo "<br>$i = $rand_id[$i], $j = $rand_id[$j]";
			$count++;
		}
	}
}
echo "<br>$count matches";
}

for($temp=0;$temp<100;$temp++){
rand_test();
usleep(15);
}
*/
?>
