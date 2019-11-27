#!/usr/bin/env python3  

# Inspired by:
# https://www.acmesystems.it/python_http
# https://f-o.org.uk/2017/receiving-files-over-http-with-python.html

import os, sys
from os import curdir, sep
from http.server import HTTPServer, BaseHTTPRequestHandler

# Colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_PUT(self):
        filename = os.path.basename(self.path)

        file_length = int(self.headers['Content-Length'])
        with open(filename, 'wb') as output_file:
            output_file.write(self.rfile.read(file_length))
        self.send_response(201, 'Created')
        self.end_headers()
        reply_body = 'Saved "%s"\n' % filename
        self.wfile.write(reply_body.encode('utf-8'))

    def do_GET(self):
        f = open(curdir + sep + self.path)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(bytes(f.read(), 'utf-8'))
        f.close()

if not len(sys.argv) >= 3:
    print(f'{RED}[!] Missing IP address or port! Exiting...{NC}')
    sys.exit(1)

IP=str(sys.argv[1])
PORT=int(sys.argv[2])
print(f'{BLUE}[i] Starting web server on {IP}:{PORT}{NC}')
print(f'{BLUE}[i] Press ctrl+c to exit when all files have transferred.{NC}')

httpd = HTTPServer((IP, PORT), SimpleHTTPRequestHandler)
httpd.serve_forever()
