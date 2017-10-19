<?php
    // Chreistopher Gray - Christophermjgray@gmail.com
    // Version 0.6.0
    // Updated 10/19/17
    // WARNING: ---- Make sure to change default passwords / salts. Use: https://www.grc.com/passwords.htm


    ini_set('session.hash_function', 'sha256');
    
    function gen_Salt($length = '64'){
        return substr(strtr(base64_encode(hex2bin(RandomToken())), '+', '.'), 0, $length);
    }
    
    function cryptoGenHMAC($Value, $Length = 64, $key = '', $Cypher = 'sha512', $debug = 0) {
        // old. dont use, use gen_StrongHash
        $Output = substr(hash_hmac($Cypher, $Value, $key),0,$Length);
        return $Output;
    }
    
    function gen_StrongHash($Plaintext,  $cost = '14') {
        $Hash = password_hash($Plaintext, PASSWORD_BCRYPT, array('cost' => 14));  // generate blowfish hash with a cost of 14. (1.3 seconds) -  http://php.net/manual/en/function.password-hash.php
        return $Hash;
    }
    
    function Super_Encrypt($PlainText, $password = '', $enc_method = 'AES-256-CTR') {
        //$enc_method = 'AES-256-CTR';  // http://php.net/openssl_get_cipher_methods
        // https://www.xkcd.com/221/
        //----------------------------------------------------------------------------------
        $iv = RandomToken($enc_method);  // initialization vector
        $encrypted_text = base64_encode(openssl_encrypt($PlainText, $enc_method, $password, 0, $iv) . "::" . bin2hex($iv));  // encrypt data, append the IV to the end of the encypted data, and base64 encode all of it
        unset($PlainText, $password, $enc_method, $iv);
        return $encrypted_text;
    }
    
    function Super_decrypt($encrypted_data, $password = '', $iv = '', $enc_method = 'AES-256-CTR') {
        $encrypted_data = base64_decode($encrypted_data);
        if ($iv == '') {
            if(preg_match("/^(.*)::(.*)$/", $encrypted_data, $regs)) { // check if the iv is stored in the encrypted payload. if so, extract it, and use it for decryption
                list(, $encrypted_data, $enc_ivD) = $regs;
                $decrypted_token = openssl_decrypt($encrypted_data, $enc_method, $password, 0, hex2bin($enc_ivD));
                unset($encrypted_data, $password, $enc_method, $enc_ivD, $regs);
            }
        } else {
            $decrypted_token = openssl_decrypt($encrypted_data, $enc_method, $password, 0, hex2bin($iv));
            unset($encrypted_data, $password, $enc_method, $iv);
        }
        return $decrypted_token;
    }


    function RandomToken($Cipher = 'AES-256-CTR'){
        $length = openssl_cipher_iv_length($Cipher);
        
        if(!isset($length) || intval($length) <= 8 ){
            $length = 32;
        }
        if (function_exists('random_bytes')) {
            return bin2hex(random_bytes($length));
        }
        if (function_exists('mcrypt_create_iv')) {
            return bin2hex(mcrypt_create_iv($length, MCRYPT_DEV_URANDOM));
        }
        if (function_exists('openssl_random_pseudo_bytes')) {
            return bin2hex(openssl_random_pseudo_bytes($length));
        }
    }
    

?>
