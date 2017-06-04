<?php
        $my_current_ip=exec("ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'");
        echo "Server IP: ".$my_current_ip;
        echo "<br /><br /><br />";

        echo "Links: <br /><br />
                Cockpit <a href='https://127.0.0.1:9090'>https://127.0.0.1:9090</a>  <br />
                Webmin <a href='https://127.0.0.1:10000'>https://127.0.0.1:10000</a>  <br /><br />
                
        <br /><br /><br />";
        phpinfo();
?>
