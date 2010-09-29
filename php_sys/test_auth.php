<?php
defaults('ADMIN_USERNAME','playcrab'); 			// Admin Username
defaults('ADMIN_PASSWORD','airmud');  	// Admin Password - CHANGE THIS TO ENABLE!!!
function defaults($d,$v) {
	if (!defined($d)) define($d,$v); // or just @define(...)
}
if (ADMIN_PASSWORD!='password') {

	if (!isset($_SERVER['PHP_AUTH_USER']) ||
			!isset($_SERVER['PHP_AUTH_PW']) ||
			$_SERVER['PHP_AUTH_USER'] != ADMIN_USERNAME ||
			$_SERVER['PHP_AUTH_PW'] != ADMIN_PASSWORD) {
		Header("WWW-Authenticate: Basic realm=\"Login\"");
		Header("HTTP/1.0 401 Unauthorized");

		echo <<<EOB
			<html><body>
			<h1>Rejected!</h1>
			<big>Wrong Username or Password!</big><br/>&nbsp;<br/>&nbsp;
		<big><a href='$PHP_SELF?OB={$MYREQUEST['OB']}'>Continue...</a></big>
			</body></html>
EOB;
		exit;

	} else {
		$AUTHENTICATED=1;
	}
}
