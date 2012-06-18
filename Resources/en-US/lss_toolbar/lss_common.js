var delimiter=",";
var settings_arr = new Array ();

function callRuby(actionName) {
	query = 'skp:get_data@' + actionName;
	window.location.href = query;
}

function get_setting(setting_pair_str) {
	var setting_pair=setting_pair_str.split("|");
	settings_arr.push(setting_pair);
}

function apply_defaults(){
	for (i=0; i<settings_arr.length; i++) {
		var img_btn=document.images[settings_arr[i][0]]
		if (img_btn) {
			if (settings_arr[i][1]=="true") {
				img_btn.setAttribute("className", "btn_checked");
			};
			else {
				img_btn.setAttribute("className", "btn_unchecked");
			};
		}
		var input_ctrl=document.getElementById(settings_arr[i][0]);
		if (input_ctrl) {
			if (input_ctrl.type == 'text') {
				input_ctrl.value=settings_arr[i][1];
			}
			if (input_ctrl.type == 'checkbox') {
				if (settings_arr[i][1]=='true'){
					input_ctrl.checked=true;
				}
				else{
					input_ctrl.checked=false;
				}
			}
		}
	}
}

function obtain_defaults(){
	callRuby('get_settings');
	apply_defaults();
	if (typeof window.custom_init == "function") { // Checks if custom_init exists
		custom_init(); // Calls a function within custom *.js file
	}
}

function reset_tool() {
	actionName="reset"
	callRuby(actionName);
	if (typeof window.custom_reset == "function") { // Checks if custom_init exists
		custom_reset(); // Calls a function within custom *.js file
	}
}

function apply_settings() {
	callRuby("apply_settings");
}

function terminate_tool() {
	callRuby("terminate_tool");
}

function key_dwn(field) {
	if (event.keyCode==13) {
		send_setting(field);
	}
}

function click_chk(btn) {
	if ((btn.getAttribute("className")=="btn_unchecked") || (btn.getAttribute("className")=="btn_unchecked_over")) {
		btn.setAttribute("className", "btn_checked");
		act_name="obtain_setting"+ delimiter+ btn.id+ delimiter +"true";
	}
	else {
		btn.setAttribute("className", "btn_unchecked");
		act_name="obtain_setting"+ delimiter+ btn.id+ delimiter +"false";
	}
	callRuby(act_name);
	callRuby('get_settings');
}

function click_speed(btn) {
	callRuby(btn.id);
	callRuby('get_settings');
}

function btn_over(btn) {
	if (btn.getAttribute("className")=="btn_unchecked") {
		btn.setAttribute("className", "btn_unchecked_over");
	}
	else {
		btn.setAttribute("className", "btn_checked_over");
	}
}

function btn_out(btn) {
	if ((btn.getAttribute("className")=="btn_unchecked_over") || (btn.getAttribute("className")=="btn_unchecked")) {
		btn.setAttribute("className", "btn_unchecked");
	}
	else {
		btn.setAttribute("className", "btn_checked");
	}
}

function speed_btn_over(btn) {
	btn.setAttribute("className", "speed_btn_over");
}

function speed_btn_out(btn) {
	btn.setAttribute("className", "speed_btn");
}

function radio_over(btn) {
	if (btn.getAttribute("className")=="radio_unselected") {
		btn.setAttribute("className", "radio_unselected_over");
	}
}

function radio_out(btn) {
	if (btn.getAttribute("className")=="radio_unselected_over") {
		btn.setAttribute("className", "radio_unselected");
	}
}

function radio_click(btn) {
	if ((btn.getAttribute("className")=="radio_unselected_over") || (btn.getAttribute("className")=="radio_unselected")) {
		radio_grp=btn.parentNode;
		for (i=0; i < document.images.length; i++) {
			if (document.images[i].parentNode==radio_grp) {
				document.images[i].setAttribute("className", "radio_unselected");
			}
		}
		btn.setAttribute("className", "radio_selected");
		for (i=0; i < radio_grp.all.length; i++) {
			if (radio_grp.all[i].type=="hidden") {
				radio_grp.all[i].value=btn.id;
				send_setting(radio_grp.all[i]);
			}
		}
	}
}

function send_setting(setting_control) {
	act_name="obtain_setting"+ delimiter+ setting_control.id+ delimiter +setting_control.value;
	callRuby(act_name);
	callRuby('get_settings');
}

function send_slider_val(val_name, val) {
	act_name="obtain_setting"+ delimiter+ val_name+ delimiter + val;
	callRuby(act_name);
	callRuby('get_settings');
}

function key_up_body(event){

}

function key_dwn(field) {
	if (event.keyCode==13) {
		send_setting(field);
	}
}