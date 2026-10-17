"""Gemini connection verification; credentials never leave the request transport."""
import from typing { Any, cast }
import from http.client { HTTPResponse }
import json;
import re;
import ai_service;
import from urllib.request { Request }
import from urllib.error { HTTPError, URLError }
def test_connection(config: tuple[str, str], transport: Any) -> dict[str, any] {
    (key, model) = config;
    if not key {
        raise ai_service.AIUnavailable(
            'Enable AI and save a personal key, or choose a configured server key.'
        );
    }
    model = model.removeprefix('gemini/');
    if not re.fullmatch('gemini-[a-zA-Z0-9._-]+', model) {
        raise ValueError('Use a valid Gemini model');
    }
    body = {
        'contents': [
            {
                'role': 'user',
                'parts': [{'text': 'Connection check. Reply with OK only.'}]
            }
        ],
        'generationConfig': {'maxOutputTokens': 512}
    };
    request = Request(
        f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
        data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'x-goog-api-key': key},
        method='POST'
    );
    try {
        with cast(HTTPResponse, transport(request, timeout=20)) as response {
            envelope = json.loads(response.read((1024 * 1024)));
        }
        parts = envelope['candidates'][0]['content']['parts'];
        if not `any(
            part.get('text')
            for part in parts
            if not part.get('thought')
        ) {
            raise ValueError('No completed response');
        }
    } except HTTPError as error {
        detail = {
            401: 'Key rejected.',
            403: 'Key or model access rejected.',
            404: 'Model unavailable.',
            429: 'Quota or rate limit reached.'
        }.get(
            error.code, 'Provider request failed.'
        );
        raise ai_service.AIUnavailable(
            ('Gemini connection failed. ' + detail)
        ) from None;
    } except (URLError, TimeoutError, ValueError, KeyError, IndexError, TypeError) {
        raise ai_service.AIUnavailable(
            'Gemini connection could not be verified. Check your key and model, then try again.'
        ) from None;
    }
    return {
        'ok': True,
        'message': 'Gemini responded successfully using your current configuration.'
    };
}
