from pathlib import Path
import zipfile,hashlib,json
root=Path(__file__).resolve().parents[1]
release=root/'downloads/HolyLightEclipse-0.9.5.zip'
with zipfile.ZipFile(release) as z:
    assert z.testzip() is None
    assert all(n.startswith('HolyLightEclipse/') for n in z.namelist())
    for name in z.namelist():
        assert z.read(name)==(root/name).read_bytes(),name
    assert b'## Version: 0.9.5' in z.read('HolyLightEclipse/HolyLightEclipse.toc')
expected=(root/'downloads/SHA256SUMS-0.9.5.txt').read_text().split()[0]
assert hashlib.sha256(release.read_bytes()).hexdigest()==expected
for item in json.loads((root/'docs/screenshots/MANIFEST.json').read_text()):
    assert hashlib.sha256((root/'docs/screenshots'/item['file']).read_bytes()).hexdigest()==item['sha256']
print('Verified complete ZIP/source equality, version, SHA-256 and screenshot hashes.')
