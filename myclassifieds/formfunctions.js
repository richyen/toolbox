function confirm_delete(itemID){
	var result = confirm("Are you sure you want to delete this item?");
	if(result){
		window.location = "item.php?action=remove&itemID="+itemID;
	}else return;
}

function validateForm(){
	var i;
	var returner = 0;
	var elems = new Array();
	var bad = new Array();
	var errors = "";
	elems = document.forms['item'].elements;
	var len = elems.length;
	for (i = 0; i < len; i++){
		if (elems[i].name == "itemType"){	//validate itemType
			if(elems[i].selectedIndex == 0){
				errors = errors + "- Please select an Item Type for your item\n";
				returner++;
				continue;
			}
		}
	}
	if(returner > 0){
		errors = "Your submission returned the following errors:\n\n" + errors;
		alert(errors);
		 return false;
	}
	else return true;
}

function isNameBlank(name){
	if (name.search(/.+/) == -1)		//check for a name
		return true;
	else if (name.search(/\s/) == -1)	//check for a surname
		return true;
	else
		return false;
}

function isNameInvalid(name){	//check for numbers or punctuation
	if (name.search(/^([-A-Za-z]+)(\s([-A-Za-z]+))+$/) == -1)
		return true;
	else
		return false;
}

function isEmailValid(email){	//checks for valid email address format
	if (email.search(/^\w+((-\w+)|(\.\w+))*\@[A-Za-z0-9]+((\.|-)[A-Za-z0-9]+)*\.[A-Za-z0-9]+$/) != -1)
        return false;
    else
        return true;
}

function isNumeric(idno){		//check for alphabetic characters
	if (idno.search(/^[\d\s()-]+$/) != -1)
		return false;
	else
		return true;
}