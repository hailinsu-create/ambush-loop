import hashlib
import struct
def entries(path):
    b = path.read_bytes()
    assert b[:4] == b'GDPC' and struct.unpack_from('<I', b, 4)[0] == 4
    file_base = struct.unpack_from('<Q', b, 24)[0]
    directory = struct.unpack_from('<Q', b, 32)[0]
    count = struct.unpack_from('<I', b, directory)[0]
    p = directory + 4
    out = {}
    for _ in range(count):
        size = struct.unpack_from('<I', b, p)[0]
        p += 4
        name = b[p:p + size].rstrip(b'\x00').decode()
        p += size
        offset, nbytes = struct.unpack_from('<QQ', b, p)
        p += 16
        md5 = b[p:p + 16]
        p += 16
        flags = struct.unpack_from('<I', b, p)[0]
        p += 4
        assert flags == 0, (name, flags)
        payload = b[file_base + offset:file_base + offset + nbytes]
        assert len(payload) == nbytes and hashlib.md5(payload).digest() == md5, (name, offset, nbytes)
        assert name not in out
        out[name] = {'bytes': nbytes, 'sha256': hashlib.sha256(payload).hexdigest()}
    return out
