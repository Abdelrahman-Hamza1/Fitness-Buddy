"""Approximation of fb_text normalizeKey, only to avoid duplicate-name
clashes while proposing entries. The catalog validator is the authority."""
import re
import unicodedata

_AR = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ئ': 'ي',
       'ؤ': 'و', 'ک': 'ك', 'ی': 'ي', 'ھ': 'ه'}


def norm_key(s):
    s = s.replace("'", '').replace('’', '')
    s = ''.join(c for c in unicodedata.normalize('NFKD', s)
                if not unicodedata.combining(c))
    s = re.sub('[ً-ٰٟـ]', '', s)
    s = ''.join(_AR.get(c, c) for c in s).lower()
    s = re.sub(r'[^a-z0-9ء-ي ]', ' ', s)
    s = re.sub(r'([a-z])\1+', r'\1', s)
    s = re.sub(r'([اوي])\1+', r'\1', s)
    s = re.sub(r'([ء-ي])\1{2,}', r'\1', s)
    return ' '.join(s.split())
