#!/usr/bin/env python3
"""Local server for the dashboard.

Run with:  python3 serve.py        (override the port with PORT=8123 python3 serve.py)

Zero dependencies — Python 3 standard library only. No web framework, no pip install,
no virtualenv. `python3 -m http.server` will not work in its place: it 501s on POST, so
every write from the dashboard would silently fail.

WHAT IT SERVES
  dashboard/            the only static root. index.html and nothing above it.
  /api/*                explicit JSON routes. Five of them read and write
                        dashboard/data/; /api/queue reads and writes brain/queue.json,
                        which is THE queue for the whole system and must not be
                        forked into a second copy.

  brain/ is NOT a static root. `GET /brain/queue.json` 404s. It is reachable only
  through /api/queue, which validates the document before it writes. That is the
  whole reason for having explicit API routes instead of static file serving.

SECURITY POSTURE
  - Binds 127.0.0.1 ONLY. Binding 0.0.0.0 would publish this to everyone on the
    same Wi-Fi.
  - No CORS. The dashboard is same-origin, so it never needed it — and
    Access-Control-Allow-Origin:* would let any open tab read your data.
  - Writes require a same-origin Origin/Referer AND Content-Type: application/json.
    Dropping CORS alone does not stop a plain <form> POST from another site; those
    skip preflight entirely.
  - Dotfiles (.env, .git, ...) and backup/temp files are unreachable; directory
    listings are off.
  - Writes are atomic and back up the previous copy, so a crash mid-write cannot
    truncate queue.json to zero bytes.

STILL UNAUTHENTICATED BY DESIGN: localhost-only, single user. Anyone who can reach
the port can read and overwrite everything. Do not port-forward it, tunnel it, or
map it out of a container.
"""

import json
import os
import shutil
import sys
from datetime import date
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

ROOT       = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(ROOT, 'dashboard')
DATA_DIR   = os.path.join(STATIC_DIR, 'data')

# THE queue lives in brain/ — outside the static root on purpose. It is the source of
# truth the rest of the system reads, and a second copy under dashboard/data/ would fork it.
QUEUE_PATH       = os.path.join(ROOT, 'brain', 'queue.json')

PROJECTS_PATH    = os.path.join(DATA_DIR, 'projects.json')
LIFE_PATH        = os.path.join(DATA_DIR, 'life-data.json')
BRIEF_PATH       = os.path.join(DATA_DIR, 'morning-brief.json')
BUILD_ORDER_PATH = os.path.join(DATA_DIR, 'build-order.json')
SKILLS_PATH      = os.path.join(DATA_DIR, 'skills-index.json')

PORT = int(os.environ.get('PORT', 8000))
HOST = '127.0.0.1'

MAX_BODY_BYTES = 4 * 1024 * 1024   # a big queue.json is ~300KB; 4MiB is generous and bounds an OOM

# Never serve these over HTTP, no matter what the filesystem says. Anything whose path has a
# component starting with '.' is also blocked (.env, .git, .DS_Store).
BLOCKED_NAMES    = {'credentials.md'}
BLOCKED_DIRS     = {'_trash', 'node_modules'}
BLOCKED_SUFFIXES = ('.bak', '.tmp')   # save_json's own artifacts are not public


class BadRequest(Exception):
    """Raised by _read_body and the route handlers; carries the status code to return."""
    def __init__(self, status, message):
        super().__init__(message)
        self.status = status
        self.message = message


def load_json(path, default=None):
    """Read a data file. `default` is returned when the file does not exist yet."""
    if not os.path.exists(path):
        if default is None:
            raise BadRequest(404, f'{os.path.basename(path)} does not exist')
        return default
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_json(path, data):
    """Atomic write with a one-deep backup.

    A naive open('w') truncates first, so a crash or Ctrl-C mid-write leaves a zero-length
    file. For queue.json — the entire task history — that is the failure that actually bites.
    Write a sibling .tmp, fsync, then os.replace() (atomic on the same filesystem).
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path):
        try:
            shutil.copy2(path, path + '.bak')
        except OSError:
            pass  # a failed backup must never block the write itself
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # directory= pins the static root to dashboard/ regardless of the process cwd.
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def log_message(self, fmt, *args):
        print(fmt % args)

    def _send_json(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(payload))
        self.send_header('Cache-Control', 'no-store')
        # No Access-Control-Allow-Origin: the dashboard is same-origin and never needed it,
        # while '*' would let any site open in the browser read this data.
        self.end_headers()
        self.wfile.write(payload)

    # ---- request guards -------------------------------------------------------------------

    def _allowed_origins(self):
        port = self.server.server_address[1]
        return {f'http://127.0.0.1:{port}', f'http://localhost:{port}'}

    def _check_origin(self):
        """Reject cross-site writes. Returns True if the request may proceed.

        Browsers send Origin on every POST/PATCH, including same-origin ones. A curl request
        with no Origin and no Referer is a local shell, not a drive-by page, so it's allowed.
        """
        origin = self.headers.get('Origin')
        if origin is not None:
            if origin in self._allowed_origins():
                return True
            self._send_json(403, {'error': 'cross-origin write refused'})
            return False
        referer = self.headers.get('Referer')
        if referer:
            split = urlsplit(referer)
            if f'{split.scheme}://{split.netloc}' not in self._allowed_origins():
                self._send_json(403, {'error': 'cross-origin write refused'})
                return False
        return True

    def _read_body(self):
        ctype = (self.headers.get('Content-Type') or '').split(';')[0].strip().lower()
        if ctype != 'application/json':
            # Without this, a plain <form enctype="text/plain"> POST from any website is a
            # "simple request" that skips preflight and lands here with attacker-chosen JSON.
            raise BadRequest(415, 'Content-Type must be application/json')
        try:
            length = int(self.headers.get('Content-Length', 0))
        except ValueError:
            raise BadRequest(400, 'bad Content-Length')
        if length <= 0:
            raise BadRequest(400, 'empty body')
        if length > MAX_BODY_BYTES:
            raise BadRequest(413, f'body too large (max {MAX_BODY_BYTES} bytes)')
        try:
            return json.loads(self.rfile.read(length))
        except (json.JSONDecodeError, UnicodeDecodeError):
            raise BadRequest(400, 'body is not valid JSON')

    # ---- static file lockdown -------------------------------------------------------------

    def translate_path(self, path):
        resolved = super().translate_path(path)
        root = os.path.abspath(STATIC_DIR)
        target = os.path.abspath(resolved)
        # Belt and braces: SimpleHTTPRequestHandler already strips '..', but confirm containment.
        if target != root and not target.startswith(root + os.sep):
            return os.path.join(root, '__forbidden__')
        rel = os.path.relpath(target, root)
        if rel != '.':
            parts = rel.split(os.sep)
            if any(p.startswith('.') for p in parts) \
               or any(p in BLOCKED_DIRS for p in parts) \
               or parts[-1] in BLOCKED_NAMES \
               or parts[-1].endswith(BLOCKED_SUFFIXES):
                return os.path.join(root, '__forbidden__')
        return resolved

    def list_directory(self, path):
        # Directory listings would turn dashboard/ into a browsable index.
        self.send_error(404, 'Not Found')
        return None

    # ---- routing --------------------------------------------------------------------------

    def do_OPTIONS(self):
        # No CORS headers — this exists only so a preflight doesn't 501.
        self.send_response(204)
        self.send_header('Content-Length', '0')
        self.end_headers()

    def do_GET(self):
        path = urlsplit(self.path).path
        try:
            if path == '/':
                # Directory listings are off, so '/' would 404. Send it to the dashboard.
                self.send_response(302)
                self.send_header('Location', '/index.html')
                self.send_header('Content-Length', '0')
                self.end_headers()
                return
            if path == '/api/health':
                return self._send_json(200, {'ok': True, 'data_dir': 'dashboard/data',
                                             'queue': 'brain/queue.json'})
            if path == '/api/projects':
                return self._send_json(200, load_json(PROJECTS_PATH, []))
            if path == '/api/queue':
                return self._send_json(200, load_json(QUEUE_PATH, {'_meta': {'count': 0}, 'items': []}))
            if path == '/api/life':
                return self._send_json(200, load_json(LIFE_PATH, []))
            if path == '/api/brief':
                return self._send_json(200, load_json(BRIEF_PATH, {}))
            if path == '/api/build-order':
                return self._send_json(200, load_json(BUILD_ORDER_PATH, []))
            if path == '/api/skills':
                return self._send_json(200, load_json(SKILLS_PATH, []))
            if path.startswith('/api/'):
                return self._send_json(404, {'error': 'Not found'})
        except BadRequest as e:
            return self._send_json(e.status, {'error': e.message})
        except Exception as e:
            print(f'ERROR GET {self.path}: {e}', file=sys.stderr)
            return self._send_json(500, {'error': 'internal error'})
        # Fall through to static file serving out of dashboard/.
        super().do_GET()

    def do_POST(self):
        if not self._check_origin():
            return
        path = urlsplit(self.path).path
        try:
            if path == '/api/queue':
                self._handle_write_queue()
            elif path == '/api/projects':
                self._handle_write_project()
            elif path == '/api/archive-project':
                self._handle_archive_project()
            elif path == '/api/build-order':
                self._handle_write_build_order()
            elif path == '/api/life':
                self._handle_post_life()
            elif path.startswith('/api/life/'):
                # Same as PATCH, for clients that cannot send one.
                self._handle_patch_life(path[len('/api/life/'):])
            else:
                self._send_json(404, {'error': 'Not found'})
        except BadRequest as e:
            self._send_json(e.status, {'error': e.message})
        except Exception as e:
            # Raw exception text leaks filesystem paths to the response. Log it, don't send it.
            print(f'ERROR POST {self.path}: {e}', file=sys.stderr)
            self._send_json(500, {'error': 'internal error'})

    def do_PATCH(self):
        if not self._check_origin():
            return
        path = urlsplit(self.path).path
        try:
            if path.startswith('/api/life/'):
                self._handle_patch_life(path[len('/api/life/'):])
            else:
                self._send_json(404, {'error': 'Not found'})
        except BadRequest as e:
            self._send_json(e.status, {'error': e.message})
        except Exception as e:
            print(f'ERROR PATCH {self.path}: {e}', file=sys.stderr)
            self._send_json(500, {'error': 'internal error'})

    # ---- handlers -------------------------------------------------------------------------

    def _handle_write_queue(self):
        """POST /api/queue — body is the full queue doc {_meta, items}, replacing queue.json.

        The dashboard posts the whole document after any star/done/archive/reorder action.
        items holds tasks AND ideas/decisions, so anything that would drop rows is refused.
        """
        body = self._read_body()
        if not isinstance(body, dict) or not isinstance(body.get('items'), list):
            return self._send_json(400, {'error': 'expected {_meta, items} queue doc'})
        if body.get('_meta') is None:
            return self._send_json(400, {'error': 'queue doc missing _meta — refusing to strip it'})
        # Shrink guard. No dashboard action removes rows in bulk — a "kill" keeps the row with
        # status=killed. So a replace that halves the file is a stale client posting an old
        # snapshot, which is how rows silently disappear.
        if os.path.exists(QUEUE_PATH):
            try:
                existing = len(load_json(QUEUE_PATH).get('items', []))
            except (json.JSONDecodeError, OSError):
                existing = 0
            if existing and len(body['items']) < existing * 0.5:
                return self._send_json(409, {
                    'error': f'refusing to shrink queue from {existing} to {len(body["items"])} rows'
                             ' — this looks like a stale client. Reload the dashboard.'
                })
        # Keep _meta.count honest. The dashboard does not know this field exists.
        body['_meta']['count'] = len(body['items'])
        save_json(QUEUE_PATH, body)
        self._send_json(200, {'ok': True, 'count': len(body['items'])})

    def _handle_write_project(self):
        """POST /api/projects — body { id, status }. Updates status and last_updated."""
        body = self._read_body()
        project_id = body.get('id')
        new_status = body.get('status')
        if not project_id or not new_status:
            return self._send_json(400, {'error': 'id and status required'})
        valid = {'active', 'queue', 'paused', 'done'}
        if new_status not in valid:
            return self._send_json(400, {'error': f'status must be one of {sorted(valid)}'})
        projects = load_json(PROJECTS_PATH, [])
        for i, p in enumerate(projects):
            if p.get('id') == project_id:
                projects[i]['status'] = new_status
                projects[i]['last_updated'] = date.today().isoformat()
                save_json(PROJECTS_PATH, projects)
                return self._send_json(200, {'ok': True})
        self._send_json(404, {'error': f'Project {project_id!r} not found'})

    def _handle_archive_project(self):
        """POST /api/archive-project — body { id }. Sets archived=true."""
        body = self._read_body()
        project_id = body.get('id')
        if not project_id:
            return self._send_json(400, {'error': 'id required'})
        projects = load_json(PROJECTS_PATH, [])
        for i, p in enumerate(projects):
            if p.get('id') == project_id:
                projects[i]['archived'] = True
                projects[i]['last_updated'] = date.today().isoformat()
                save_json(PROJECTS_PATH, projects)
                return self._send_json(200, {'ok': True})
        self._send_json(404, {'error': f'Project {project_id!r} not found'})

    def _handle_write_build_order(self):
        """POST /api/build-order — body is an ordered array of project ids."""
        body = self._read_body()
        if not isinstance(body, list):
            return self._send_json(400, {'error': 'expected array of project ids'})
        save_json(BUILD_ORDER_PATH, body)
        self._send_json(200, {'ok': True, 'count': len(body)})

    def _handle_post_life(self):
        """POST /api/life — two shapes.

        { parentId, item }  append item to that parent's children (parentId null = root)
        [ ... ]             replace the whole tree (used by drag-to-reorder)
        """
        body = self._read_body()

        if isinstance(body, list):
            save_json(LIFE_PATH, body)
            return self._send_json(200, {'ok': True, 'count': len(body)})

        if not isinstance(body, dict):
            return self._send_json(400, {'error': 'expected an object or an array'})

        data = load_json(LIFE_PATH, [])
        parent_id = body.get('parentId') or body.get('parent_id')
        item = body.get('item', body)

        def append_to_parent(nodes, pid, new_item):
            for node in nodes:
                if node.get('id') == pid:
                    node.setdefault('children', []).append(new_item)
                    return True
                if append_to_parent(node.get('children', []), pid, new_item):
                    return True
            return False

        if parent_id:
            if not append_to_parent(data, parent_id, item):
                return self._send_json(404, {'error': f'Parent {parent_id!r} not found'})
        else:
            data.append(item)

        save_json(LIFE_PATH, data)
        self._send_json(200, {'ok': True})

    def _handle_patch_life(self, item_id):
        """PATCH /api/life/:id — merge the body into one node, found anywhere in the tree."""
        body = self._read_body()
        if not isinstance(body, dict):
            return self._send_json(400, {'error': 'expected an object of fields to update'})
        data = load_json(LIFE_PATH, [])

        def update_node(nodes, target_id, updates):
            for i, node in enumerate(nodes):
                if node.get('id') == target_id:
                    nodes[i].update(updates)
                    return True
                if update_node(node.get('children', []), target_id, updates):
                    return True
            return False

        if not update_node(data, item_id, body):
            return self._send_json(404, {'error': f'Item {item_id!r} not found'})

        save_json(LIFE_PATH, data)
        self._send_json(200, {'ok': True})


if __name__ == '__main__':
    if not os.path.isdir(STATIC_DIR):
        sys.exit(f'No dashboard/ directory next to serve.py (looked in {STATIC_DIR}).')
    os.chdir(ROOT)
    # ThreadingHTTPServer, not HTTPServer: the dashboard fires several concurrent fetches on
    # load and polls every 15s; a single-threaded server head-of-line-blocks them.
    ThreadingHTTPServer.allow_reuse_address = True
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f'Dashboard  ->  http://{HOST}:{PORT}/')
    print('Serving    ->  dashboard/  (localhost only - no other machine can reach it)')
    print('Data       ->  dashboard/data/  +  brain/queue.json (via /api/queue only)')
    print('Press Ctrl+C to stop.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nStopped.')
