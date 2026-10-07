from pathlib import Path
import hashlib, tarfile, json, datetime, subprocess

base = Path('/tmp/pr15-web-controls')
author = Path('/workspace/pr15-web-artifacts/843f55c3bc618706d1ddc7aa18d01223927233fc/ambush-loop-site.tar')
site = Path('/workspace/sites/ambush-loop-html-game')
commit = '63642faff970fc8b01e4d54e624fa6ec129c929f'
expected = '9b789a57b14fa36e794a9fcf1f34c000588f706d9a5f6b211bfe3ba8f26051a4'

class HashSink:
    def __init__(self):
        self.h = hashlib.sha256()
        self.n = 0
    def write(self, data):
        self.h.update(data)
        self.n += len(data)
        return len(data)
    def tell(self):
        return self.n
    def flush(self):
        pass

result = {'start': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'site_commit': commit,
          'author_archive': str(author), 'author_bytes': author.stat().st_size,
          'author_sha256': hashlib.sha256(author.read_bytes()).hexdigest(),
          'server_metadata_bytes': 48476160, 'server_metadata_sha256': expected,
          'method': 'Re-serialize only the same 13 regular files, preserving order/names/exact payload bytes, using Python tarfile PAX_FORMAT and default TarInfo metadata. Omit directory members and Git global PAX comment. Hash output in memory; no source modification or deployment.',
          'files': []}
try:
    with tarfile.open(author) as old:
        members = old.getmembers()
        result['author_directory_members'] = [m.name for m in members if m.isdir()]
        result['author_global_pax'] = old.pax_headers
        files = [m for m in members if m.isfile()]
        assert len(files) == 13
        sink = HashSink()
        with tarfile.open(fileobj=sink, mode='w', format=tarfile.PAX_FORMAT) as new:
            for original in files:
                payload = old.extractfile(original).read()
                git = subprocess.run(['git', 'show', commit + ':' + original.name], cwd=site,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                assert git.returncode == 0 and git.stdout == payload
                result['files'].append({'name': original.name, 'bytes': len(payload),
                                        'sha256': hashlib.sha256(payload).hexdigest(), 'git_show_exit': git.returncode,
                                        'exact_site_commit_bytes': True})
                item = tarfile.TarInfo(original.name)
                item.size = original.size
                new.addfile(item, old.extractfile(original))
        result.update({'reproduced_bytes': sink.n, 'reproduced_sha256': sink.h.hexdigest(),
                       'exact_server_archive_hash_reproduced': sink.n == 48476160 and sink.h.hexdigest() == expected})
        assert result['exact_server_archive_hash_reproduced']
    result['actual_exit'] = 0
except Exception as error:
    result.update({'actual_exit': 1, 'error': str(error)})
finally:
    result['end'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    (base / 'site-v1-archive-reproduction.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k:v for k,v in result.items() if k != 'files'}, indent=2))
raise SystemExit(result['actual_exit'])
