"""Genera los paquetes .gmod que usan los tests end-to-end de firma.

    python tools/generate_test_zips.py

Los fixtures se versionan en tests/data/ para que la batería no dependa de
tener Python con `cryptography` instalado.
"""

import zipfile, json, hashlib, base64, os
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa, utils

def make_zip(path, manifest_data, content_data, algorithm, tamper_content=False, extra_file=False):
    manifest = manifest_data.encode() if isinstance(manifest_data, str) else manifest_data
    content = content_data.encode() if isinstance(content_data, str) else content_data
    key = rsa.generate_private_key(65537, 2048)
    pub_pem = key.public_key().public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
    # Force Unix line endings (Windows cryptography lib may produce \r\n)
    pub_pem = pub_pem.replace(b"\r\n", b"\n")
    files = [
        {
            "path": "manifest.json",
            "sha256": hashlib.sha256(manifest).hexdigest(),
            "bytes": len(manifest),
        },
        {
            "path": "content.pck",
            "sha256": hashlib.sha256(content).hexdigest(),
            "bytes": len(content),
        },
    ]
    lines = sorted([f["sha256"] + "  " + f["path"] for f in files])
    payload_text = "\n".join(lines) + "\n"
    payload_hash = hashlib.sha256(payload_text.encode()).hexdigest()
    sig = {
        "signature_version": 1,
        "algorithm": algorithm,
        "hash": "sha256",
        "files": files,
        "payload_sha256": payload_hash,
    }
    if algorithm != "none":
        # La firma cubre payload_sha256 tal cual, sin volver a hashearlo.
        # Godot Crypto.verify() recibe el digest FINAL y no lo hashea de nuevo,
        # mientras que cryptography SÍ hashea salvo que se use Prehashed. Sin
        # Prehashed los dos lados firman cosas distintas y nada valida.
        signature = key.sign(
            bytes.fromhex(payload_hash),
            padding.PKCS1v15(),
            utils.Prehashed(hashes.SHA256()),
        )
        sig["signature"] = base64.b64encode(signature).decode()
        sig["public_key"] = pub_pem.decode()
        sig["signed_at"] = "2026-07-29T00:00:00Z"
        sig["key_id"] = hashlib.sha256(
            key.public_key().public_bytes(
                serialization.Encoding.DER,
                serialization.PublicFormat.SubjectPublicKeyInfo,
            )
        ).hexdigest()[:16]

    # El contenido se altera DESPUÉS de firmar: así el paquete reproduce el
    # caso real de "un byte cambiado tras la firma" y debe caer en el paso de
    # integridad, no en el de firma.
    if tamper_content:
        content = content[:-1] + bytes([(content[-1] + 1) % 256])

    with zipfile.ZipFile(path, "w") as z:
        z.writestr("manifest.json", manifest)
        z.writestr("content.pck", content)
        if extra_file:
            z.writestr("malicious.gd", b"evil")
        z.writestr("signature.json", json.dumps(sig))

base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests", "data")
os.makedirs(base, exist_ok=True)
# Valid signed package
make_zip(os.path.join(base, "e2e_valid.gmod"), '{"format_version": 1}', "test data", "rsa2048-pkcs1v15-sha256")
# Tampered content (1 byte changed)
make_zip(os.path.join(base, "e2e_tampered.gmod"), '{"format_version": 1}', "test data", "rsa2048-pkcs1v15-sha256", tamper_content=True)
# Extra file not in signature
make_zip(os.path.join(base, "e2e_extra.gmod"), '{"format_version": 1}', "test data", "rsa2048-pkcs1v15-sha256", extra_file=True)
# Valid with algorithm=none (integrity only)
make_zip(os.path.join(base, "e2e_none.gmod"), '{"format_version": 1}', "test data", "none")
print("ZIPs created")
