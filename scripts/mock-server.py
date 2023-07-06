#!/usr/bin/env python3

import http.server
import requests
import json
import os

PROXY = 'https://bandcamp.com'
RESPONSES = {}

class S(http.server.BaseHTTPRequestHandler):

    def do_POST(self):
        path = self.path
        content_len = int(self.headers.get('content-length', 0))
        body = self.rfile.read(content_len).decode('utf-8')

        if path not in RESPONSES:
            RESPONSES[path] = {}
        
        if body in RESPONSES[path]:
            print('sending cache')
            self.send_response(200)
            self.send_header('content-type', 'application/json')
            self.end_headers()

            self.wfile.write(RESPONSES[path][body].encode('utf-8'))
        else:
            data = json.loads(body)
            print(f'proxying...{PROXY}{path} :: {data}')
            headers = dict([(k, v) for k, v in self.headers.items()])
            headers.pop('Host', None)
            #print(headers)
            r = requests.post(f'{PROXY}{path}', headers = headers, json=data)
            #print('sending response', r.status_code)
            self.send_response(r.status_code)
            # for key, value in r.headers.items():
            #     if key.lower() not in ('transfer-encoding', 'content-encoding', 'vary'):
            #         print('sending header', key, value)
            #         self.send_header(key, value)
            self.send_header('content-type', 'application/json')
            self.end_headers()

            resp_body = r.text
            RESPONSES[path][body] = resp_body

            #print('sending body', resp_body)
            self.wfile.write(resp_body.encode('utf-8'))

if __name__ == '__main__':
    try:
        f = open(os.path.join(os.path.dirname(__file__), 'stream.dump'), 'r')
        for k, v in json.load(f).items():
            RESPONSES[k] = v
        f.close()
    except IOError:
        pass

    try:
        port = http.server.HTTPServer(('', 8081), S)
        port.serve_forever()
    except (Exception, KeyboardInterrupt):
        f = open(os.path.join(os.path.dirname(__file__), 'stream.dump'), 'w')
        json.dump(RESPONSES, f)
        f.close()
