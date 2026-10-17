"""Jac application request orchestration inside the Python-owned SQLite transaction."""
import from typing { cast }
import json;
import domain;
import support;
import account_settings;
import ai_service;
import agent_tools;
import agent_conversations;
def get_response(host: any, db: any, user: any, path: str) -> any {
    if path == "/api/agent/conversation" {
        workspace = cast(dict[str, any], host.load_state(db, user['id']));
        return host.respond(
            200, agent_conversations.latest_conversation(db, str(user['id']), workspace)
        );
    }
    if (path == '/api/state') {
        workspace = cast(dict[str, any], host.load_state(db, user['id']));
        result = domain.dispatch(workspace, 'snapshot', {});
        result['showcase_version'] = workspace.get('showcase_version', 0);
        result['settings'] = account_settings.public(db, user['id']);
        result['ai'] = result['settings']['ai'];
        result['user'] = {
            'id': user['id'],
            'name': user['name'],
            'email': user['email'],
            'demo': bool(user['demo'])
        };
        result['market'] = host.public_market(db, user);
        result['offers'] = [
            `dict(row)
            for row in db.execute(
                'SELECT * FROM offers WHERE seller_id=? OR buyer_id=? ORDER BY created_at DESC',
                (user['id'], user['id'])
            )
        ];
        return host.respond(200, result);
    }
    if path.startswith('/api/files/') {
        row = db.execute(
            'SELECT * FROM files WHERE id=? AND user_id=?',
            (path.rsplit('/', 1)[-1], user['id'])
        ).fetchone();
        if row {
            return host.respond(200, row['content'], row['mime'], filename=row['name']);
        }
    }
    if (path == '/api/ai/status') {
        return host.respond(200, account_settings.public(db, user['id'])['ai']);
    }
    if (path == '/api/settings') {
        return host.respond(200, account_settings.public(db, user['id']));
    }
    return host.respond(404, {'error': 'Not found'});
}

def post_response(
    host: any,
    db: any,
    user: any,
    state: dict[str, any],
    path: str,
    payload: dict[str, any]
) -> any {
    if path == "/api/agent/conversation/new" {
        session_id = support.identifier();
        db.execute(
            "INSERT INTO agent_sessions VALUES (?,?,?,?)",
            (session_id, user['id'], "[]", support.now())
        );
        return host.respond(200, {"session_id": session_id});
    }
    if (path == '/api/agent/chat') {
        import vehicle_agent;
        message = support.text(payload.get('message'), 'Message', 2000);
        prior: list[dict[str, any]] = [];
        session_id = str(payload.get('session_id') or '');
        if session_id {
            session = db.execute(
                'SELECT * FROM agent_sessions WHERE id=? AND user_id=?',
                (session_id, user['id'])
            ).fetchone();
            if not session {
                raise ValueError('Conversation not found in your workspace');
            }
            prior = cast(list[dict[str, any]], json.loads(str(session['contents'])));
            for turn in prior {
                for part in turn.get('parts', []) {
                    response = part.get('functionResponse', {}).get('response', {});
                    if response.get('proposal_id') {
                        saved = agent_conversations.public_proposal(
                            db, str(user['id']), str(response['proposal_id']), state
                        );
                        if saved {
                            response['proposal_status'] = saved['status'];
                            response['notice'] = (
                                'Current proposal status: ' + str(saved['status'])
                            );
                        }
                    }
                }
            }
        } else {
            (session_id, prior) = (support.identifier(), []);
        }
        with ai_service.use_config(
            cast(tuple[str, str], account_settings.effective_config(db, user['id']))
        ) {
            result = vehicle_agent.run_agent(
                state,
                message,
                str((payload.get('vehicle_id') or '')),
                prior
            );
        }
        contents = result.pop('contents');
        db.execute(
            'INSERT INTO agent_sessions VALUES (?,?,?,?) ON CONFLICT(id) DO UPDATE SET contents=excluded.contents, updated_at=excluded.updated_at',
            (session_id, user['id'], json.dumps(contents), support.now())
        );
        public_proposals = [];
        for proposal in result['proposals'] {
            db.execute(
                'INSERT INTO agent_proposals VALUES (?,?,?,?,?,?)',
                (
                    proposal['id'],
                    user['id'],
                    json.dumps(proposal),
                    'pending',
                    None,
                    support.now()
                )
            );
            public_proposals.append(
                agent_conversations.public_proposal(
                    db, str(user['id']), str(proposal['id']), state
                )
            );
        }
        result['proposals'] = public_proposals;
        result['session_id'] = session_id;
        db.execute(
            "INSERT INTO agent_turns VALUES (?,?,?,?,?,?,?)",
            (
                support.identifier(),
                session_id,
                user['id'],
                message,
                str(payload.get('vehicle_id') or ''),
                json.dumps(result),
                support.now()
            )
        );
        return host.respond(200, result);
    }
    if (path in ['/api/agent/approve', '/api/agent/reject']) {
        row = db.execute(
            'SELECT * FROM agent_proposals WHERE id=? AND user_id=?',
            (payload.get('proposal_id'), user['id'])
        ).fetchone();
        if not row {
            raise ValueError('Proposed change not found in your workspace');
        }
        if ((row['status'] == 'applied') and path.endswith('approve')) {
            return host.respond(
                200,
                {
                    'status': 'applied',
                    'result': json.loads(str(row['result'])),
                    'already_applied': True
                }
            );
        }
        if (row['status'] != 'pending') {
            raise ValueError('This proposal is no longer pending');
        }
        if path.endswith('reject') {
            db.execute(
                "UPDATE agent_proposals SET status='rejected',updated_at=? WHERE id=?",
                (support.now(), row['id'])
            );
            return host.respond(200, {'status': 'rejected'});
        }
        proposal = json.loads(str(row['proposal']));
        if (proposal['state_hash'] != agent_tools.workspace_hash(state)) {
            db.execute(
                "UPDATE agent_proposals SET status='stale',updated_at=? WHERE id=?",
                (support.now(), row['id'])
            );
            return host.respond(
                409,
                {
                    'error': 'Your vehicle data changed after this proposal. Ask the assistant to prepare it again.'
                }
            );
        }
        if (proposal['tool'] not in agent_tools.WRITE_TOOLS) {
            raise ValueError('This operation is not approved for the assistant');
        }
        result = domain.dispatch(
            state, str(proposal['action']), cast(dict[str, any], proposal['payload'])
        );
        host.save_state(db, user['id'], state);
        db.execute(
            "UPDATE agent_proposals SET status='applied',result=?,updated_at=? WHERE id=?",
            (json.dumps(result), support.now(), row['id'])
        );
        return host.respond(200, {'status': 'applied', 'result': result});
    }
    if (path in ['/api/ai/review', '/api/ai/draft', '/api/ai/diagnosis']) {
        with ai_service.use_config(
            cast(tuple[str, str], account_settings.effective_config(db, user['id']))
        ) {
            result = ai_service.generate(state, path.rsplit('/', 1)[-1], payload);
        }
        return host.respond(200, result);
    }
    if (path == '/api/workflow') {
        action = str(payload.get('action', ''));
        data = payload.get('payload', {});
        if not isinstance(data, `dict) {
            raise ValueError('Workflow data must be an object');
        }
        if ((action == 'add_record') and data.get('document')) {
            document = db.execute(
                'SELECT id FROM files WHERE id=? AND user_id=?',
                (data['document'], user['id'])
            ).fetchone();
            if not document {
                raise ValueError('Supporting document not found in your workspace');
            }
        }
        result = domain.dispatch(state, action, data);
        host.save_state(db, user['id'], state);
        return host.respond(200, {'result': result});
    }
    if (path == '/api/offer') {
        listing = domain.find_listing(
            public_market(db, user), payload.get('listing_id')
        );
        if (not listing or (listing['status'] != 'active')) {
            raise ValueError('This listing is not accepting offers');
        }
        if (listing['seller_id'] == user['id']) {
            raise ValueError('You cannot make an offer on your own listing');
        }
        amount = support.number(payload.get('amount'), 'Offer', 1, 1000000000);
        message = support.text(payload.get('message'), 'Message', 1000);
        db.execute(
            'INSERT INTO offers VALUES (?,?,?,?,?,?,?,?)',
            (
                support.identifier(),
                listing['id'],
                listing['seller_id'],
                user['id'],
                amount,
                message,
                'pending',
                support.now()
            )
        );
        return host.respond(200, {'ok': True});
    }
    if (path == '/api/listing-status') {
        domain.set_listing_status(state, payload);
        host.save_state(db, user['id'], state);
        return host.respond(200, {'ok': True});
    }
    return host.respond(404, {'error': 'Not found'});
}

def public_market(db: any, viewer: any) -> list[dict[str, any]] {
    listings: list[dict[str, any]] = [];
    for row in db.execute(
        'SELECT users.id, users.name, users.demo, workspaces.state FROM users JOIN workspaces ON users.id=workspaces.user_id'
    ) {
        if (viewer['demo'] and (row['id'] != viewer['id'])) {
            continue;
        }
        if (not viewer['demo'] and row['demo']) {
            continue;
        }
        for listing in json.loads(str(row['state'])).get('listings', []) {
            if (listing['status'] in ['active', 'reserved']) {
                listings.append(
                    cast(
                        dict[str, any],
                        (
                            {} | listing | {'seller_id': row['id']} | {
                                'seller': row['name']
                            } | {'demo': bool(row['demo'])}
                        )
                    )
                );
            }
        }
    }
    return listings;
}

glob PUBLIC_LISTING_FIELDS: list[str] = [
    'id', 'make', 'model', 'year', 'odometer', 'price', 'currency', 'location',
    'description', 'history', 'status', 'created_at'
];

"""Listings anyone can browse without signing in: real accounts only, no account identifiers."""
def public_listings(db: any) -> list[dict[str, any]] {
    listings: list[dict[str, any]] = [];
    for row in db.execute(
        'SELECT users.name, workspaces.state FROM users JOIN workspaces ON users.id=workspaces.user_id WHERE users.demo=0'
    ) {
        name = str(row['name']).strip();
        seller = name.split(' ')[0] if name else 'Private seller';
        for listing in json.loads(str(row['state'])).get('listings', []) {
            if (listing['status'] in ['active', 'reserved']) {
                listings.append(
                    {key: listing.get(key) for key in PUBLIC_LISTING_FIELDS} | {'seller': seller}
                );
            }
        }
    }
    return listings;
}
