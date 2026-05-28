openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.req #When prompted for input leave empty
openssl req -x509 -key server.key -in server.req -out server.crt -days 7300
