<?php
    // Chreistopher Gray - Christophermjgray@gmail.com
    // Version 0.5.1
    // Updated 10/12/17
    // WARNING: ---- Make sure to change default passwords / salts. Use: https://www.grc.com/passwords.htm
    ini_set('session.hash_function', 'sha256');
    
    function cryptoGenHMAC($Value, $Length = 64, $key = 'sbfXJToi1OBHLGQxGJwPDZOZk3HIk24OVvh8CO4Y8eUnOdpuWL2ClG1ipYA3mEj', $Cypher = 'sha512', $debug = 0) {
        // old. dont use, use gen_StrongHash
        $Output = substr(hash_hmac($Cypher, $Value, $key),0,$Length);
        return $Output;
    }
    
    function gen_StrongHash($Plaintext,  $cost = '14') {
        $Hash = password_hash($Plaintext, PASSWORD_BCRYPT, array('cost' => 14));  // generate blowfish hash with a cost of 14. (1.3 seconds) -  http://php.net/manual/en/function.password-hash.php
        return $Hash;
    }
    
    function Super_Encrypt($PlainText, $password = 'kPU2RJ55VYOXL99L3Z3ZxEGOiUggYYXNxso7CW3WChUL5DejSQqT717xF1WrG8q', $enc_method = 'AES-256-CTR') {
        //$enc_method = 'AES-256-CTR';  // http://php.net/openssl_get_cipher_methods
        //----------------------------------------------------------------------------------
        $iv = openssl_random_pseudo_bytes(openssl_cipher_iv_length($enc_method));  // initialization vector
        $encrypted_text = base64_encode(openssl_encrypt($PlainText, $enc_method, $password, 0, $iv) . "::" . bin2hex($iv));  // encrypt data, append the IV to the end of the encypted data, and base64 encode all of it
        unset($PlainText, $password, $enc_method, $iv);
        return $encrypted_text;
    }
    
    function Super_decrypt($encrypted_data, $password = 'kPU2RJ55VYOXL99L3Z3ZxEGOiUggYYXNxso7CW3WChUL5DejSQqT717xF1WrG8q', $iv = '', $enc_method = 'AES-256-CTR') {
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

?>
