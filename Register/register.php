<?php

include './config.php';
include './AddFuncs.php';
include './MySQL.php';
include './PasswordStrength.php';

$resMySQL = new MySQL($arrConfig);
$resFuncs = new AddFuncs();
$resPWDChecker = new PasswordStrength();

$strUsername = $resFuncs->sanitizeData(filter_input(INPUT_POST, 'username'));
$strPassword = $resFuncs->sanitizeData(filter_input(INPUT_POST, 'password'));
$strGCaptcha = $resFuncs->sanitizeData(filter_input(INPUT_POST, 'g-recaptcha-response'));

$strIP = $_SERVER['REMOTE_ADDR'];

if (!isset($strUsername) || !isset($strPassword) || !isset($strGCaptcha)) {
	$resFuncs->sendMessage('Kindly fill in all the fields');
	exit();
} 
if (strlen($strUsername) < 4 || strlen($strUsername) > 10) {
	$resFuncs->sendMessage('Username is either too short or too long');
	exit();
} 
if (!ctype_alnum($strUsername)) {
	$resFuncs->sendMessage('Username should be alphanumeric');
	exit();
}
$isExistsUsername = $resMySQL->checkUsernameExists($strUsername);
if ($isExistsUsername != false) {
	$resFuncs->sendMessage('Username already exists');
	exit();
}
	
if (strlen($strPassword) < 5 || strlen($strPassword) > 20) {
	$resFuncs->sendMessage('Password is either too short or too long');
	exit();
} 

$strPasswordStrength = $resPWDChecker->classify($strPassword);

if ($strPasswordStrength == 0) {
	$resFuncs->sendMessage('Password is extremely weak');
	exit();
}
if ($strPasswordStrength == 1) {
	$resFuncs->sendMessage('Password is weak asf bruh');
	exit();
}

$arrResponse = $resFuncs->getRecaptchaResponse(array('secret' => $arrConfig['secret_key'], 'response' => $strGCaptcha, 'remoteip' => $strIP));

if (!$arrResponse->success) {
	$resFuncs->sendMessage('Stop tryna hack nigguh');
	exit();
}


if ($strPasswordStrength >= 2) {
	$encryptedPassword = $resFuncs->encryptedPassword($strPassword);
	$strUUID = $resFuncs->generateRandUUID();
	$resMySQL->registerPenguin($strUsername, $encryptedPassword, $strUUID);
	$resFuncs->sendMessage("Thanks for signing up with RBSE, {$strUsername} your UUID is {$strUUID}", 1);
}

?>
