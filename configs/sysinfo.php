<?php
  echo "<h1>This is for DEVELOPMENT ONLY!</h1><h2>Do not deploy on a production server, as it will expose sensitive service info to the world</h2>";
    
  $ServerIP = $_SERVER["SERVER_ADDR"];
  echo 'ServerIP: '.$ServerIP.'<br /><br />';
    
  $RemoteIP = $_SERVER["REMOTE_ADDR"];
  echo 'Client: '.$RemoteIP.'<br /><br />';
  
  phpinfo();
?>
