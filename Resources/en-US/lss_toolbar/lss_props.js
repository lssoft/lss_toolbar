var prop_dicts={};
var delimeter=",";

function get_prop_dict(prop_dict_str) {
	prop_dicts[prop_dict_str]=new Array ();
}

function get_property(prop_str){
	prop=prop_str.split("|");
	var dict=prop[0];
	var prop_name=prop[1];
	var prop_val=prop[2];
	prop_dicts[dict].push([prop_name, prop_val]);
}

function ctrl_onchange(evt){
	act_name="obtain_setting"+ delimiter + this.id + delimeter + this.value;
	callRuby(act_name);
	load_props();
}

function key_dwn_prop(evt) {
	if (event.keyCode==13) {
		act_name="obtain_setting"+ delimiter + this.id + delimeter + this.value;
		callRuby(act_name);
		load_props();
	}
}

function build_props_list(){
	for (var dict_name in prop_dicts) {
		var oTable = document.createElement("TABLE");
		var oTBody = document.createElement("TBODY");
		var oCaption = document.createElement("CAPTION");
		var oRow, nameCell, valCell;
		
		var props_list=prop_dicts[dict_name]
		
		oTable.style.width="100%";
		oTable.style.tableLayout="fixed";
		oTable.appendChild(oTBody);
		oCaption.style.width="100%";

		var dict_div = document.createElement("DIV");
		dict_div.style.whiteSpace="nowrap";
		dict_div.style.textOverflow="ellipsis";
		dict_div.style.overflow="hidden";
		dict_div.style.display="inline-block";
		dict_div.style.width="90%";
		dict_div.style.maxWidth="100%";
		dict_div.innerHTML = dict_name;
		oCaption.appendChild(dict_div);
		oCaption.title = "Properties Dictionary Name"; 
		oTable.appendChild(oCaption);
		for (i=0; i<props_list.length; i++)
		{
			var field_id = dict_name + delimiter + props_list[i][0];
			oRow = document.createElement("TR");
			oTBody.appendChild(oRow);
			nameCell = document.createElement("TD");
			nameCell.width="50%";
			var name_div = document.createElement("DIV");
			name_div.style.whiteSpace="nowrap";
			name_div.style.textOverflow="ellipsis";
			name_div.style.overflow="hidden";
			name_div.style.display="inline-block";
			name_div.style.width="100%";
			name_div.style.maxWidth="100%";
			name_div.innerHTML = props_list[i][0];
			nameCell.appendChild(name_div);
			oRow.appendChild(nameCell);
			valCell = document.createElement("TD");
			valCell.style.textAlign="right";
			if ((props_list[i][1] == "true") || (props_list[i][1] == "false")) {
				prop_select = document.createElement("select");
				true_opt=document.createElement("OPTION");
				true_opt.value="true";
				true_opt.innerHTML="true";
				prop_select.appendChild(true_opt);
				false_opt=document.createElement("OPTION");
				false_opt.value="false";
				false_opt.innerHTML="false";
				prop_select.appendChild(false_opt);
				prop_select.setAttribute("size", 1);
				prop_select.value=props_list[i][1]
				prop_select.setAttribute("id", field_id);
				prop_select.style.width="100%";
				prop_select.onchange=ctrl_onchange;
				valCell.appendChild(prop_select);
			}
			else {
				//Create an input type dynamically.
				var val_input = document.createElement("input");
				//Assign different attributes to the element.
				val_input.setAttribute("type", "text");
				val_input.setAttribute("value", props_list[i][1]);
				val_input.setAttribute("id", field_id);
				val_input.style.width="100%";
				val_input.onkeydown=key_dwn_prop;
				val_input.onchange=ctrl_onchange;
				//Append the element in page (in span).
				valCell.appendChild(val_input);
			}
			oRow.appendChild(valCell);
		}
		oTableContainer.appendChild(oTable);
	}
}

function load_props(){
	prop_dicts={};
	callRuby('get_props');
	oTableContainer.innerHTML="";
	build_props_list();
	var hash_size = 0;
	for (key in prop_dicts) {
		if (prop_dicts.hasOwnProperty(key)) hash_size++;
	}
	if (hash_size==0) {
		var info_div = document.createElement("DIV");
		info_div.style.fontStyle="italic";
		info_div.innerHTML="There are no entities selected or selected entity has no attributes.";
		oTableContainer.appendChild(info_div);
	}
}