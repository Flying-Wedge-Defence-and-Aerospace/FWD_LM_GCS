#!/usr/bin/env python3
"""Seal a Google OAuth refresh token for embedding in GoogleDriveManager.

The resulting fragments and key are NOT encrypted secrets — they are a
lightweight obfuscation to defeat casual extraction from the shipped binary.
Anyone with root/executable debugging can recover the token.
"""
import argparse, base64, os, random, sys

def chunk_and_xor(token, key):
    n = len(token)
    pad = key * (n // len(key) + 1)
    xored = bytes(token[i] ^ pad[i] for i in range(n))
    half = (n + 1) // 2
    part_a = xored[:half]
    part_b = xored[half:]
    return part_a, part_b

def emit(part_a, part_b, key, name):
    def b64_enc(b): return base64.b64encode(b).decode()
    def hex_bytes(b): return ', '.join(f'0x{v:02x}' for v in b)
    out = []
    out.append(f'static const char* {name}_A = "{b64_enc(part_a)}";')
    out.append(f'static const char* {name}_B = "{b64_enc(part_b)}";')
    out.append(f'static const unsigned char {name}_Key[32] = {{ {hex_bytes(key)} }};')
    out.append('')
    out.append('// Usage inside src/Vehicle/GoogleDriveManager.cc (after imports):')
    out.append('//   static const char* kPayloadPartA = ' + name + '_A;')
    out.append('//   static const char* kPayloadPartB = ' + name + '_B;')
    out.append('//   static const quint8 kPayloadKey[32] = ' + name + '_Key;')
    return '\n'.join(out) + '\n'

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('token', help='plaintext refresh token')
    ap.add_argument('--key', help='32-byte hex key (generates one if absent)')
    args = ap.parse_args()
    token = args.token.encode()
    if args.key:
        key = bytes.fromhex(args.key)
        if len(key) != 32:
            sys.exit('key must be 32 bytes (64 hex)')
    else:
        key = os.urandom(32)
    part_a, part_b = chunk_and_xor(token, key)
    print(emit(part_a, part_b, key, 'PAYLOAD'))
    print('# key-hex (save this separately – the binary unseals with it):')
    print(key.hex())

if __name__ == '__main__':
    main()
