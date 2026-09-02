<!DOCTYPE html>
<html>
<head>
	<title>aMule - Control Panel - Login</title>

	<script language="JavaScript" type="text/javascript">
		function login_init()
		{
			breakout_of_frame();
			document.login.pass.focus();
		}
	</script>
	<meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link href="bootstrap5.min.css" rel="stylesheet">
</head>

<body class="bg-dark">

	<div class="container">
		<div class="card position-absolute top-50 start-50 translate-middle" style="width: 18rem;">
			<div class="card-body">
				<div class="d-flex justify-content-center mb-2">
					<img src="logo-nav-2.png" class="mx-auto" alt="...">
				</div>
				<h5 class="card-title text-center mb-5">aMule Web</h5>
				<form action="" method="post" name="login">
			   			<input name="pass" type="password" class="form-control mb-3" placeholder="Password" required autofocus>
						<div class="d-grid gap-2">
			   				<button class="btn btn-secondary" type="submit" name="submit" value="Submit">Login</button>
						</div>
    			</form>
			</div>
		</div>
	</div>

</body>

</html>
