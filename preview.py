#!/usr/bin/env python3
"""Preview web/ the way Cloudflare Pages serves it: HTML is extensionless, and
/foo.html redirects to /foo. Plain http.server 404s every /privacy-style link."""
import functools, http.server, os, socketserver, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'web')

class Pages(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        path = self.path.split('?')[0].split('#')[0]
        if path.endswith('.html'):
            self.send_response(308)
            self.send_header('Location', path[:-5])
            self.end_headers()
            return None
        if not os.path.splitext(path)[1] and path != '/':
            if os.path.isfile(os.path.join(ROOT, path.lstrip('/') + '.html')):
                self.path = path + '.html'
        return super().send_head()

    def send_error(self, code, *a, **kw):          # Pages serves 404.html on a miss
        if code == 404 and os.path.isfile(os.path.join(ROOT, '404.html')):
            self.path = '/404.html'
            self.send_response(404)
            body = open(os.path.join(ROOT, '404.html'), 'rb').read()
            self.send_header('Content-Type', 'text/html')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().send_error(code, *a, **kw)

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('', port), functools.partial(Pages, directory=ROOT)) as s:
    print(f'http://localhost:{port}/  (Pages-style routing, Ctrl-C to stop)')
    s.serve_forever()
