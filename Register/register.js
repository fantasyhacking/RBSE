function createAccount() {
        var username = $("#username").val();
        var password = $("#password").val();
		var captcha_response = grecaptcha.getResponse();
		var dataString = {"username": username, "password": password, "g-recaptcha-response": captcha_response};
        $.ajax({
            type: "POST",
            url: "http://127.0.0.1/register/register.php",
            data: dataString,
            dataType: 'text',
			success: function(returnedData) {
				console.log(returnedData);
				var data = $.parseJSON(returnedData);
				if (data.status == true) {
					swal("Atta boi!", data.message, "success")
				} else {
					sweetAlert("Yikes..", data.message, "error");
				}
			}
        });
}
