<?php

class AddFuncs {

	public function sanitizeData($resInput) {
			return htmlentities(stripslashes($resInput), ENT_QUOTES);
	}
	
	public function sendMessage($strMessage, $blnKill = 0) {
		echo json_encode(array('message' => $strMessage, 'status' => ($blnKill ? true : false)));
	}
	
	public function encryptedPassword($strPassword) {
		$strSHA256 = hash('sha256', $strPassword);
		$strBcrypt = password_hash($strSHA256, PASSWORD_BCRYPT, array('cost' => 12, 'salt' => bin2hex(openssl_random_pseudo_bytes(12))));
		return $strBcrypt;
	}
	
	public function generateRandUUID() {
		$data = openssl_random_pseudo_bytes(16);
		assert(strlen($data) == 16);
		$data[6] = chr(ord($data[6]) & 0x0f | 0x40);
		$data[8] = chr(ord($data[8]) & 0x3f | 0x80);
		return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
	}
	
	public function getRecaptchaResponse($arrDetails) {
		$resCURL = curl_init();
		curl_setopt($resCURL, CURLOPT_URL, "https://www.google.com/recaptcha/api/siteverify");
		curl_setopt($resCURL, CURLOPT_HEADER, 0);
		curl_setopt($resCURL, CURLOPT_RETURNTRANSFER, 1); 
		curl_setopt($resCURL, CURLOPT_POST, 1);
		curl_setopt($resCURL, CURLOPT_POSTFIELDS, $arrDetails);
		$arrResp = json_decode(curl_exec($resCURL));
		curl_close($resCURL);
		return $arrResp;
	}
	
}

?>
