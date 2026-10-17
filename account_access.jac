"""Account workflows; Python owns password hashing, sessions and the transaction."""
import from typing { Any }
import secrets;
import re;
import hashlib;
import from http.cookies { SimpleCookie }
import support;
import from showcase { seed_demo }
def sign_in(host: Any, db: Any, path: Any, payload: Any) -> Any {
    if (path == '/api/demo') {
        user_id = support.identifier();
        email = user_id + '@demo.invalid';
        name = 'Demo garage';
        password = secrets.token_urlsafe(32);
    } else {
        email = support.text(payload.get('email'), 'Email', 200).lower();
        if ('@' not in email) {
            raise ValueError('Use a valid email address');
        }
        password = support.text(payload.get('password'), 'Password', 200);
        if (len(password) < 8) {
            raise ValueError('Password needs at least 8 characters');
        }
    }
    if (path == '/api/login') {
        user = db.execute(
            'SELECT * FROM users WHERE email=? AND demo=0', (email, )
        ).fetchone();
        if (
            not user
            or not secrets.compare_digest(
                host.password_hash(password, user['salt']), user['password']
            )
        ) {
            return host.respond(401, {'error': 'Email or password is incorrect'});
        }
        user_id = str(user['id']);
    } else {
        if (path == '/api/signup') {
            user_id = support.identifier();
            name = support.text(payload.get('name'), 'Name', 80);
        }
        salt = secrets.token_hex(16);
        db.execute(
            'INSERT INTO users VALUES (?,?,?,?,?,?)',
            (
                user_id,
                email,
                name,
                salt,
                host.password_hash(password, salt),
                int((path == '/api/demo'))
            )
        );
        host.save_state(
            db,
            user_id,
            seed_demo(db, user_id)
                if (path == '/api/demo')
                else {'vehicles': [], 'listings': []}
        );
    }
    return host.respond(200, {'ok': True}, cookie=host.session(db, user_id));
}

def update_account(host: Any, db: Any, user: Any, path: Any, payload: Any) -> Any {
    if (path == '/api/settings/profile') {
        name = support.text(payload.get('name'), 'Name', 80);
        email = support.text(payload.get('email'), 'Email', 200).lower();
        if not re.fullmatch('[^\\s@]+@[^\\s@]+\\.[^\\s@]+', email) {
            raise ValueError('Use a valid email address');
        }
        if (email != user['email']) {
            if user['demo'] {
                raise ValueError(
                    'Create a personal account to change your sign-in email'
                );
            }
            current = support.text(
                payload.get('email_password'), 'Current password', 200
            );
            if not secrets.compare_digest(
                host.password_hash(current, user['salt']), user['password']
            ) {
                raise ValueError('Current password is incorrect');
            }
        }
        db.execute(
            'UPDATE users SET name=?,email=? WHERE id=?', (name, email, user['id'])
        );
        return host.respond(200, {'ok': True});
    }
    if (path == '/api/settings/password') {
        if user['demo'] {
            raise ValueError('Create a personal account to manage a password');
        }
        current = support.text(
            payload.get('current_password'), 'Current password', 200
        );
        if not secrets.compare_digest(
            host.password_hash(current, user['salt']), user['password']
        ) {
            raise ValueError('Current password is incorrect');
        }
        password = support.text(payload.get('new_password'), 'New password', 200);
        if (len(password) < 8) {
            raise ValueError('Password needs at least 8 characters');
        }
        salt = secrets.token_hex(16);
        db.execute(
            'UPDATE users SET salt=?,password=? WHERE id=?',
            (salt, host.password_hash(password, salt), user['id'])
        );
        token = SimpleCookie(host.headers.get('Cookie', ''))['smartmoti_session'].value;
        db.execute(
            'DELETE FROM sessions WHERE user_id=? AND token<>?',
            (user['id'], hashlib.sha256(token.encode()).hexdigest())
        );
        return host.respond(200, {'ok': True});
    }
    raise ValueError('Unknown account operation');
}
