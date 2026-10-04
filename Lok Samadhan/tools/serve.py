import http.server
import socketserver
import os
import sys

# Ensure sys.stdout and sys.stderr are valid when run under pythonw
if sys.stdout is None:
    sys.stdout = open(os.devnull, 'w')
if sys.stderr is None:
    sys.stderr = open(os.devnull, 'w')

PORT = 8088
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DIRECTORY = os.path.join(PROJECT_ROOT, "build", "web")

if not os.path.isdir(DIRECTORY):
    print(f"Error: Build directory '{DIRECTORY}' not found. Run 'flutter build web' first.")
    sys.exit(1)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def log_message(self, format, *args):
        # Silently ignore or write to log to avoid pythonw NoneType crashes
        pass

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

Handler.extensions_map.update({
    '.wasm': 'application/wasm',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
})

print(f"Serving Flutter Web from: {DIRECTORY}")
print(f"Local URL: http://localhost:{PORT}")
with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
