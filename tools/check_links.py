#!/usr/bin/env python3
"""يفحص كل الروابط الموجودة في lib/data/directory.dart وlib/services/live_data.dart.

الاستخدام (يعمل في Termux أيضاً):
    python3 tools/check_links.py

- يعتبر الرابط سليماً إذا رجع 2xx أو 3xx.
- 401/403/405/429 تُعتبر تحذيراً فقط (مواقع كثيرة تمنع الأدوات الآلية).
- 404/410 وأخطاء الاتصال أو DNS تُعتبر أخطاء ويخرج السكربت بالرمز 1.
"""
import re
import ssl
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = [
    ROOT / "lib/data/directory.dart",
    ROOT / "lib/data/hotels.dart",
    ROOT / "lib/services/live_data.dart",
]
URL_RE = re.compile(r"https?://[^\s'\"$]+")
# روابط قوالب أو خدمات لا تُفحص بهذه الطريقة
SKIP_PREFIXES = (
    "https://play.google.com/store/apps/details?id=",
    "https://play.google.com/store/search",
    "https://www.google.com/maps/search",
    "https://tile.openstreetmap.org",
    "https://api.open-meteo.com",
    "https://api.oilpriceapi.com",
)
SOFT = {401, 403, 405, 429, 999}
HEADERS = {"User-Agent": "Mozilla/5.0 (LibyaHub link checker)", "Accept-Language": "ar,en"}


def collect():
    urls = {}
    for f in FILES:
        if not f.exists():
            continue
        for lineno, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for m in URL_RE.finditer(line):
                u = m.group(0).rstrip(",);")
                if u.startswith(SKIP_PREFIXES) or "{" in u:
                    continue
                urls.setdefault(u, f"{f.name}:{lineno}")
    return urls


def check(url):
    ctx = ssl.create_default_context()
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers=HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=20, context=ctx) as r:
                return url, r.status, None
        except urllib.error.HTTPError as e:
            if method == "HEAD" and e.code in SOFT | {400, 404, 501}:
                continue  # بعض الخوادم لا تدعم HEAD، جرّب GET
            return url, e.code, None
        except Exception as e:  # DNS, timeout, SSL
            if method == "HEAD":
                continue
            return url, None, str(e)
    return url, None, "unknown"


def main():
    urls = collect()
    print(f"فحص {len(urls)} رابطاً...\n")
    bad, warn = [], []
    with ThreadPoolExecutor(max_workers=8) as ex:
        for url, status, err in ex.map(check, urls):
            where = urls[url]
            if status is not None and 200 <= status < 400:
                print(f"  OK   {status}  {url}")
            elif status in SOFT:
                warn.append((url, status, where))
                print(f"  WARN {status}  {url}   ({where})")
            else:
                bad.append((url, status or err, where))
                print(f"  FAIL {status or err}  {url}   ({where})")
    print(f"\nسليم: {len(urls) - len(bad) - len(warn)} | تحذير: {len(warn)} | معطوب: {len(bad)}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
