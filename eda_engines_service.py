"""
eda-engines — the EDA engines WORKER of polari-eda-tools (the Polari engines pattern, as cnt-engines /
msci-engines / cad-engines): every tool the compute ladder (polari-framework/modules/computelod, tensormath's
FPGA kernel) shells out to, behind one JSON API, so the compute runs on WHATEVER device the topology assigns
(`pol allocate computelod.engines <instance>`) while the core keeps the rows. The backend resolves through
computelod/custom/eda_engines.py — ladder: EDA_ENGINES_URL knob wins; else a local binary; else the local image;
else the topology's provider; else an honest refusal.

  GET  /capability            {engines: {name: {available, version, note}}, pdk: {present, version}}
  GET  /system-info           res-1 shape (cpu/mem) like the other workers
  POST /run                   {"engine": name, "args": [..], "files": {name: text}, "files_b64": {name: b64},
                               "env": {..}, "timeout": s, "stdin": text?}
                               -> {ok, returncode, stdout, stderr, files, files_b64}
                              ARGV ONLY — no shell. `engine` must be in ENGINES; paths in args are basenames
                              inside the job workdir (a path with '..' or another absolute root is refused;
                              /pdk/… and /usr/share/… — the image's own read-only data — are allowed).
"""
import base64
import json
import os
import shutil
import subprocess
import tempfile

import falcon

#: engine name → binary. Nothing outside this table can be run.
ENGINES = {
    'riscv-gcc': 'riscv64-unknown-elf-gcc', 'riscv-objdump': 'riscv64-unknown-elf-objdump',
    'yosys': 'yosys', 'iverilog': 'iverilog', 'vvp': 'vvp', 'verilator': 'verilator',
    'nextpnr-ice40': 'nextpnr-ice40', 'icepack': 'icepack', 'icetime': 'icetime',
    'sta': 'sta', 'magic': 'magic', 'netgen': 'netgen-lvs',
}
VERSION_ARGS = {'riscv-gcc': ['--version'], 'riscv-objdump': ['--version'], 'yosys': ['-V'], 'iverilog': ['-V'], 'vvp': ['-V'], 'verilator': ['--version'],
                'nextpnr-ice40': ['--version'], 'icepack': [], 'icetime': [], 'sta': ['-version'], 'magic': ['--version'], 'netgen': ['-batch', 'quit']}
PDK_ROOT = os.environ.get('PDK_ROOT', '/pdk')
MAX_FILE_BYTES = 64 * 1024 * 1024
TAIL = 20000
TEXT_EXT = ('.v', '.sv', '.c', '.s', '.S', '.o.txt', '.json', '.log', '.lib', '.lef', '.spice', '.sp', '.tcl', '.txt', '.out', '.asc', '.ext', '.mag', '.rpt', '.md', '.dat', '.sh', '.lst')


def _which(engine):
    return shutil.which(ENGINES.get(engine, ''))


def _version(engine):
    b = _which(engine)
    if not b:
        return ''
    try:
        r = subprocess.run([b] + VERSION_ARGS.get(engine, ['--version']), capture_output=True, text=True, timeout=20)
        return ((r.stdout or '') + (r.stderr or '')).strip().splitlines()[0][:120] if (r.stdout or r.stderr) else 'present'
    except Exception:
        return 'present'


def _pdk():
    tech = os.path.join(PDK_ROOT, 'sky130A', 'libs.tech', 'magic', 'sky130A.tech')
    vp = os.path.join(PDK_ROOT, '.polari-pdk-version')
    return {'present': os.path.exists(tech), 'root': PDK_ROOT, 'version': open(vp).read().strip() if os.path.exists(vp) else ''}


def _capability():
    return {'worker': 'eda-engines', 'engines': {e: {'available': bool(_which(e)), 'version': _version(e), 'binary': ENGINES[e]} for e in ENGINES}, 'pdk': _pdk(),
            'protocol': 'POST /run {engine, args, files, files_b64, env, timeout} — argv only, files round-trip'}


def _bad(resp, msg, status=falcon.HTTP_400):
    resp.status = status; resp.media = {'ok': False, 'error': msg}


def _safe_arg(a):
    """A job argument: a basename/relative path inside the job, or read-only data the image itself ships (the PDK
    volume, a tool's share dir such as yosys's simlib.v). Never '..', never another absolute path."""
    a = str(a)
    if a.startswith('/pdk/') or a.startswith('/usr/share/'):
        return '..' not in a
    return '..' not in a and not a.startswith('/')


class CapabilityResource:
    def on_get(self, req, resp):
        resp.media = _capability()


class SystemInfoResource:
    def on_get(self, req, resp):
        import platform
        info = {}
        try:
            for line in open('/proc/meminfo'):
                parts = line.split()
                if parts and parts[0].rstrip(':') in ('MemTotal', 'MemAvailable'):
                    info[parts[0].rstrip(':')] = int(parts[1]) * 1024
        except Exception:
            pass
        resp.media = {'ok': True, 'worker': 'eda-engines', 'cpus': os.cpu_count(), 'memTotalBytes': info.get('MemTotal', 0), 'memAvailableBytes': info.get('MemAvailable', 0), 'platform': platform.platform()}


class RunResource:
    def on_post(self, req, resp):
        body = json.load(req.bounded_stream)
        engine = str(body.get('engine', ''))
        if engine not in ENGINES:
            return _bad(resp, 'unknown engine %r — one of %s' % (engine, sorted(ENGINES)))
        binary = _which(engine)
        if not binary:
            return _bad(resp, '%s absent in this worker' % engine, falcon.HTTP_503)
        args = [str(a) for a in (body.get('args') or [])]
        if not all(_safe_arg(a) for a in args):
            return _bad(resp, 'args must be basenames inside the job (or /pdk/…): %s' % args)
        timeout = min(float(body.get('timeout', 900) or 900), 3600.0)
        work = tempfile.mkdtemp(prefix='eda-')
        try:
            for name, text in (body.get('files') or {}).items():
                fn = os.path.basename(name)
                with open(os.path.join(work, fn), 'w') as fh:
                    fh.write(text)
            for name, b64 in (body.get('files_b64') or {}).items():
                with open(os.path.join(work, os.path.basename(name)), 'wb') as fh:
                    fh.write(base64.b64decode(b64))
            env = dict(os.environ, HOME=work, PDK_ROOT=PDK_ROOT)
            for k, v in (body.get('env') or {}).items():
                if str(k).isidentifier():
                    env[str(k)] = str(v)
            try:
                run = subprocess.run([binary] + args, capture_output=True, text=True, timeout=timeout, cwd=work, env=env, input=body.get('stdin'))
            except subprocess.TimeoutExpired:
                return _bad(resp, '%s exceeded %.0fs' % (engine, timeout), falcon.HTTP_504)
            files, files_b64, total = {}, {}, 0
            sent = set(os.path.basename(n) for n in list((body.get('files') or {}).keys()) + list((body.get('files_b64') or {}).keys()))
            for root, _, names in os.walk(work):
                for fn in sorted(names):
                    fp = os.path.join(root, fn); rel = os.path.relpath(fp, work)
                    if rel in sent:
                        continue
                    size = os.path.getsize(fp); total += size
                    if total > MAX_FILE_BYTES:
                        return _bad(resp, 'outputs exceed the 64 MB cap', falcon.HTTP_413)
                    if rel.endswith(TEXT_EXT) or size < 2_000_000 and _is_text(fp):
                        files[rel] = open(fp, errors='replace').read()
                    else:
                        files_b64[rel] = base64.b64encode(open(fp, 'rb').read()).decode()
            resp.media = {'ok': True, 'engine': engine, 'returncode': run.returncode, 'stdout': run.stdout[-TAIL:], 'stderr': run.stderr[-TAIL:], 'files': files, 'files_b64': files_b64}
        finally:
            shutil.rmtree(work, ignore_errors=True)


def _is_text(fp):
    try:
        with open(fp, 'rb') as fh:
            chunk = fh.read(4096)
        return b'\0' not in chunk
    except Exception:
        return False


app = falcon.App()
app.add_route('/capability', CapabilityResource())
app.add_route('/system-info', SystemInfoResource())
app.add_route('/run', RunResource())
