"""Extract verified 7z payloads from a Qt Installer Framework executable."""

import struct
import sys
import zlib
from pathlib import Path

# The .run file is an ELF QtIFW installer with 7z archives appended inside it.
source = Path(sys.argv[1]).read_bytes()
destination = Path(sys.argv[2])
expected_count = int(sys.argv[3])
destination.mkdir(parents=True, exist_ok=True)

signature = b"7z\xbc\xaf\x27\x1c"
position = 0
count = 0

while (position := source.find(signature, position)) != -1:
    if position + 32 > len(source):
        break

    # A 7z signature may also occur in payload data. Validate the 32-byte
    # start header before treating this position as an archive boundary.
    header_crc = struct.unpack_from("<I", source, position + 8)[0]
    # The start header stores the next header offset, size, and CRC32;
    # its end gives the complete embedded archive length.
    next_offset, next_size, next_crc = struct.unpack_from("<QQI", source, position + 12)
    end = position + 32 + next_offset + next_size

    if (
        end <= len(source)
        and zlib.crc32(source[position + 12 : position + 32]) == header_crc
        and zlib.crc32(source[position + 32 + next_offset : end]) == next_crc
    ):
        (destination / f"{count:02}.7z").write_bytes(source[position:end])
        count += 1
        # Skip archive contents so their bytes cannot become new candidates.
        position = end
    else:
        position += len(signature)

# Fail if upstream changes the installer layout or an archive was missed.
if count != expected_count:
    raise RuntimeError(f"Expected {expected_count} 7z payloads, found {count}")
