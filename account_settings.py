"""Account preferences and encrypted, account-scoped Gemini credentials."""
import jaclang
import account_preferences, gemini_health
import json
import os
from pathlib import Path
from urllib.request import urlopen
from cryptography.fernet import Fernet, InvalidToken
import ai_service
DEFAULTS = {'currency': 'KES', 'start_page': 'garage', 'ai_enabled': True, 'use_server_ai': True, 'model': 'gemini/gemini-3.8-flash'}
CURRENCIES = ['KES', 'USD', 'UGX', 'TZS', 'EUR', 'GBP']

def read(db, user_id):
    row = db.execute('SELECT * FROM account_settings WHERE user_id=?', (user_id,)).fetchone()
    return ({**DEFAULTS, **json.loads(row['preferences'])} if row else dict(DEFAULTS), row['credential'] if row else None)

def cipher(db, create=False):
    database_path = next((row[2] for row in db.execute('PRAGMA database_list') if row[1] == 'main'))
    path = Path(os.environ.get('SMARTMOTI_SECRET_FILE', str(Path(database_path).with_suffix('.credentials.key'))))
    if create:
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            with path.open('xb') as stream:
                stream.write(Fernet.generate_key())
            os.chmod(path, 384)
        except FileExistsError:
            pass
    try:
        return Fernet(path.read_bytes())
    except (OSError, ValueError):
        raise ai_service.AIUnavailable('The credential store cannot be opened. Check the server encryption key.') from None

def effective_config(db, user_id):
    prefs, credential = read(db, user_id)
    if not prefs['ai_enabled']:
        return ('', prefs['model'])
    if credential:
        try:
            stored = json.loads(cipher(db).decrypt(credential.encode()))
            if stored['user_id'] != user_id:
                raise ValueError('Invalid credential owner')
            return (stored['key'], prefs['model'])
        except (InvalidToken, ValueError, KeyError):
            raise ai_service.AIUnavailable('Your saved key cannot be read. Replace it in Settings.') from None
    return ai_service.load_ai_config() if prefs['use_server_ai'] else ('', prefs['model'])

def public(db, user_id):
    prefs, credential = read(db, user_id)
    return account_preferences.public_settings(prefs, bool(credential), ai_service.status())

def save(db, user_id, section, payload):
    prefs, credential = read(db, user_id)
    if section == 'preferences':
        prefs = account_preferences.update_preferences(prefs, payload, section, CURRENCIES)
    elif section == 'ai':
        prefs = account_preferences.update_preferences(prefs, payload, section, CURRENCIES)
        key = payload.get('api_key', '')
        if not isinstance(key, str) or len(key) > 512 or any((c.isspace() for c in key)):
            raise ValueError('Paste a key without spaces or line breaks')
        if key:
            credential = cipher(db, create=True).encrypt(json.dumps({'user_id': user_id, 'key': key}).encode()).decode()
    elif section == 'remove-key':
        credential = None
    else:
        raise ValueError('Unknown settings section')
    db.execute('INSERT INTO account_settings VALUES (?,?,?) ON CONFLICT(user_id) DO UPDATE SET preferences=excluded.preferences,credential=excluded.credential', (user_id, json.dumps(prefs), credential))
    return public(db, user_id)

def test_connection(config):
    return gemini_health.test_connection(config, urlopen)
