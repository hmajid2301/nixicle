# get gnupg socket dir based on homedir
# https://github.com/gpg/gnupg/blob/c6702d77d936b3e9d91b34d8fdee9599ab94ee1b/common/homedir.c#L672-L681
import hashlib
import base64
import sys

def base32_to_zbase32(s):
    # Translation table https://en.wikipedia.org/wiki/Base32#z-base-32
    return s.lower().translate({ord(p): r for p, r in zip('abcdefghijklmnopqrstuvwxyz234567', 'ybndrfg8ejkmcpqxot1uwisza345h769')})

if len(sys.argv) < 2:
    sys.exit('usage: gnupgdir.py <homedir>')

m = hashlib.sha1()
homedir = sys.argv[1]
m.update(homedir.encode('utf-8'))
print('d.' + base32_to_zbase32(base64.b32encode(m.digest()[0:15]).decode('utf-8')), end='')

