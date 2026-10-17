"""Local HTTP host. Vehicle workflows are implemented in domain.jac."""
import argparse
import base64
from contextlib import contextmanager
import hashlib
from http.cookies import SimpleCookie
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import re
from pathlib import Path
import secrets
import sqlite3
import time
from urllib.parse import urlparse
import jaclang
import account_access
import application
import domain
import support
from showcase import seed_demo
import ai_service
import agent_tools
import account_settings
from client_build import build_client
ROOT = Path(__file__).resolve().parent
DB_PATH = Path(os.environ.get('SMARTMOTI_DB', str(ROOT / 'data' / 'smartmoti.db')))
MAX_BODY = 8 * 1024 * 1024
# Hosted deployments terminate TLS at a proxy; set SMARTMOTI_HTTPS=1 there.
HTTPS = os.environ.get('SMARTMOTI_HTTPS') == '1'
COOKIE_FLAGS = 'Path=/; HttpOnly; SameSite=Strict' + ('; Secure' if HTTPS else '')

@contextmanager
def database():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(DB_PATH, timeout=15)
    connection.row_factory = sqlite3.Row
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

def initialize():
    build_client()
    with database() as db:
        db.executescript('\n        CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL,\n            name TEXT NOT NULL, salt TEXT NOT NULL, password TEXT NOT NULL, demo INTEGER DEFAULT 0);\n        CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, user_id TEXT NOT NULL, expires REAL NOT NULL);\n        CREATE TABLE IF NOT EXISTS workspaces (user_id TEXT PRIMARY KEY, state TEXT NOT NULL);\n        CREATE TABLE IF NOT EXISTS offers (id TEXT PRIMARY KEY, listing_id TEXT NOT NULL,\n            seller_id TEXT NOT NULL, buyer_id TEXT NOT NULL, amount REAL NOT NULL,\n            message TEXT NOT NULL, status TEXT NOT NULL, created_at TEXT NOT NULL);\n        CREATE TABLE IF NOT EXISTS files (id TEXT PRIMARY KEY, user_id TEXT NOT NULL,\n            name TEXT NOT NULL, mime TEXT NOT NULL, content BLOB NOT NULL);\n        CREATE TABLE IF NOT EXISTS agent_sessions (id TEXT PRIMARY KEY, user_id TEXT NOT NULL,\n            contents TEXT NOT NULL, updated_at TEXT NOT NULL);\n        CREATE TABLE IF NOT EXISTS agent_proposals (id TEXT PRIMARY KEY, user_id TEXT NOT NULL,\n            proposal TEXT NOT NULL, status TEXT NOT NULL, result TEXT, updated_at TEXT NOT NULL);\n        CREATE TABLE IF NOT EXISTS account_settings (user_id TEXT PRIMARY KEY,\n            preferences TEXT NOT NULL, credential TEXT);\n        ')
        db.execute("CREATE TABLE IF NOT EXISTS agent_turns (id TEXT PRIMARY KEY, session_id TEXT NOT NULL, user_id TEXT NOT NULL, message TEXT NOT NULL, vehicle_id TEXT NOT NULL, response TEXT NOT NULL, created_at TEXT NOT NULL)")
        db.execute('DELETE FROM sessions WHERE expires < ?', (time.time(),))

def password_hash(password, salt):
    return hashlib.scrypt(password.encode(), salt=bytes.fromhex(salt), n=16384, r=8, p=1).hex()

def load_state(db, user_id):
    row = db.execute('SELECT state FROM workspaces WHERE user_id=?', (user_id,)).fetchone()
    return json.loads(row['state']) if row else {'vehicles': [], 'listings': []}

def save_state(db, user_id, state):
    db.execute('INSERT INTO workspaces VALUES (?,?) ON CONFLICT(user_id) DO UPDATE SET state=excluded.state', (user_id, json.dumps(state, allow_nan=False)))

class Handler(BaseHTTPRequestHandler):
    password_hash = staticmethod(password_hash)
    load_state = staticmethod(load_state)
    save_state = staticmethod(save_state)
    server_version = 'Smartmoti/0.1'

    def log_message(self, *_args):
        pass

    def respond(self, status, content, mime='application/json', cookie=None, filename=None):
        data = json.dumps(content, allow_nan=False).encode() if mime == 'application/json' else content
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'same-origin')
        self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")
        if HTTPS:
            self.send_header('Strict-Transport-Security', 'max-age=31536000')
        if cookie:
            self.send_header('Set-Cookie', cookie)
        if filename:
            self.send_header('Content-Disposition', 'attachment; filename="vehicle-record.pdf"' if mime == 'application/pdf' else 'inline')
        self.end_headers()
        self.wfile.write(data)

    def user(self, db):
        cookie = SimpleCookie()
        try:
            cookie.load(self.headers.get('Cookie', ''))
        except Exception:
            return None
        token = cookie.get('smartmoti_session')
        if not token:
            return None
        return db.execute('SELECT users.* FROM users JOIN sessions ON users.id=sessions.user_id WHERE sessions.token=? AND expires>?', (hashlib.sha256(token.value.encode()).hexdigest(), time.time())).fetchone()

    def session(self, db, user_id):
        token = secrets.token_urlsafe(32)
        db.execute('INSERT INTO sessions VALUES (?,?,?)', (hashlib.sha256(token.encode()).hexdigest(), user_id, time.time() + 604800))
        return f'smartmoti_session={token}; {COOKIE_FLAGS}; Max-Age=604800'

    def public_market(self, db, viewer):
        return application.public_market(db, viewer)

    def do_GET(self):
        try:
            path = urlparse(self.path).path
            if path == '/api/health':
                return self.respond(200, {'status': 'ok', 'engine': 'Jac', 'version': '0.1.0'})
            with database() as db:
                if path == '/api/public/market':
                    return self.respond(200, {'listings': application.public_listings(db)})
                user = self.user(db)
                if path.startswith('/api/'):
                    if not user:
                        return self.respond(401, {'error': 'Sign in to continue'})
                    return application.get_response(self, db, user, path)
            files = {'/': 'index.html', '/demo': 'index.html', '/market': 'index.html', '/app.js': 'app.js', '/styles.css': 'styles.css',
                     '/assets/road-editorial-900.webp': 'assets/road-editorial-900.webp',
                     '/assets/road-editorial-2000.webp': 'assets/road-editorial-2000.webp'}
            if path not in files:
                return self.respond(404, {'error': 'Not found'})
            target = ROOT / 'web' / files[path]
            if path == '/app.js':
                target = ROOT / '.jac' / 'client' / 'app.js'
            mime = {'.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.webp': 'image/webp'}[target.suffix]
            return self.respond(200, target.read_bytes(), mime)
        except (ValueError, TypeError) as error:
            self.respond(400, {'error': str(error)})
        except Exception:
            self.respond(500, {'error': 'The request could not be completed'})

    def do_POST(self):
        try:
            origin = self.headers.get('Origin')
            host = (self.headers.get('X-Forwarded-Host') if HTTPS else None) or self.headers.get('Host', '')
            if origin and origin != ('https://' if HTTPS else 'http://') + host:
                return self.respond(403, {'error': 'Request origin is not allowed'})
            if self.headers.get('Content-Type', '').split(';')[0] != 'application/json':
                return self.respond(415, {'error': 'Send JSON'})
            length = int(self.headers.get('Content-Length', '0'))
            if length <= 0 or length > MAX_BODY:
                return self.respond(413, {'error': 'Request size is invalid'})
            payload = json.loads(self.rfile.read(length))
            if not isinstance(payload, dict):
                raise ValueError('Send a JSON object')
            path = urlparse(self.path).path
            with database() as db:
                db.execute('BEGIN IMMEDIATE')
                if path in ['/api/signup', '/api/login', '/api/demo']:
                    return account_access.sign_in(self, db, path, payload)
                user = self.user(db)
                if not user:
                    return self.respond(401, {'error': 'Sign in to continue'})
                if path == '/api/logout':
                    cookie = SimpleCookie(self.headers.get('Cookie', ''))
                    if cookie.get('smartmoti_session'):
                        db.execute('DELETE FROM sessions WHERE token=?', (hashlib.sha256(cookie['smartmoti_session'].value.encode()).hexdigest(),))
                    return self.respond(200, {'ok': True}, cookie=f'smartmoti_session=; {COOKIE_FLAGS}; Max-Age=0')
                state = load_state(db, user['id'])
                if path in ['/api/settings/profile', '/api/settings/password']:
                    return account_access.update_account(self, db, user, path, payload)
                if path in ['/api/settings/ai', '/api/settings/preferences', '/api/settings/remove-key']:
                    return self.respond(200, account_settings.save(db, user['id'], path.rsplit('/', 1)[-1], payload))
                if path == '/api/settings/test-ai':
                    return self.respond(200, account_settings.test_connection(account_settings.effective_config(db, user['id'])))
                if path == '/api/upload':
                    name = support.text(payload.get('name'), 'Filename', 200)
                    raw = base64.b64decode(payload.get('content', ''), validate=True)
                    mime = payload.get('mime')
                    valid = mime == 'application/pdf' and raw.startswith(b'%PDF-') or (mime == 'image/png' and raw.startswith(b'\x89PNG\r\n\x1a\n')) or (mime == 'image/jpeg' and raw.startswith(b'\xff\xd8\xff'))
                    if not valid or not 0 < len(raw) <= 5 * 1024 * 1024:
                        raise ValueError('Upload a PDF, PNG, or JPEG up to 5 MB')
                    file_id = support.identifier()
                    db.execute('INSERT INTO files VALUES (?,?,?,?,?)', (file_id, user['id'], name, mime, raw))
                    return self.respond(200, {'id': file_id, 'name': name})
                return application.post_response(self, db, user, state, path, payload)
        except ai_service.AIUnavailable as error:
            self.respond(503, {'error': str(error)})
        except sqlite3.IntegrityError:
            self.respond(409, {'error': 'An account with this email already exists'})
        except (ValueError, TypeError, KeyError, json.JSONDecodeError) as error:
            self.respond(400, {'error': str(error)})
        except Exception:
            self.respond(500, {'error': 'The request could not be completed'})

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=int(os.environ.get('PORT', 8000)))
    parser.add_argument('--host', default=os.environ.get('SMARTMOTI_HOST', '127.0.0.1'))
    args = parser.parse_args()
    initialize()
    print(f'Smartmoti · Jac vehicle workspace\nListening on {args.host}:{args.port}', flush=True)
    HTTPServer((args.host, args.port), Handler).serve_forever()
if __name__ == '__main__':
    main()
