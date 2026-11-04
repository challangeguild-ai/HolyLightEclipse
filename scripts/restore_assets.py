from pathlib import Path
import base64,gzip,json,hashlib,zipfile
root=Path(__file__).resolve().parents[1]
encoded="".join(p.read_text(encoding="ascii").strip() for p in sorted((root/"release-assets").glob("part-*.txt")))
for item in json.loads(gzip.decompress(base64.b64decode(encoded))):
    relative=Path(item["path"])
    if relative.is_absolute() or ".." in relative.parts: raise ValueError("Invalid asset path")
    path=root/relative
    data=base64.b64decode(item["data"],validate=True)
    if hashlib.sha256(data).hexdigest()!=item["sha256"]: raise ValueError("Asset checksum mismatch")
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(data)
release=root/"downloads/HolyLightEclipse-0.8.3.zip"
with zipfile.ZipFile(release) as z:
    assert z.testzip() is None
    assert all(n.startswith("HolyLightEclipse/") for n in z.namelist())
    for name in z.namelist():
        if name.lower().endswith((".lua",".xml",".toc",".tga")):
            assert z.read(name)==(root/name).read_bytes(),name
expected=(root/"downloads/SHA256SUMS.txt").read_text().split()[0]
assert hashlib.sha256(release.read_bytes()).hexdigest()==expected
print("Verified every release runtime file and SHA-256.")
