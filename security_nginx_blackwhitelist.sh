
# https://docs.nginx.com/nginx/admin-guide/security-controls/blacklisting-ip-addresses/

$ curl -X POST -d '{
     "10.0.0.1": "1",
     "192.168.13.0/24": "1",
     "10.0.0.3": "0",
     "10.0.0.4": "0"
}' -s 'http://www.example.com/api/5/http/keyvals/one'

