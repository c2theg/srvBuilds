<?php
        $my_current_ip=exec("ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'");
        echo "Server IP: ".$my_current_ip;
        echo "<br /><br /><br />";
        phpinfo();
?>
