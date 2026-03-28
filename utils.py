import hashlib
import time
import requests
from config import RETRY_COUNT, RETRY_DELAY
from logger import log

def get_sha256(url, retries=RETRY_COUNT, delay=RETRY_DELAY):
    """
    Compute SHA256 of a remote file with retries.
    Returns the SHA256 hash as a hex string, or None if all attempts fail.
    """
    for attempt in range(retries):
        try:
            r = requests.get(url, stream=True, timeout=30)
            r.raise_for_status()
            sha256 = hashlib.sha256()
            for chunk in r.iter_content(8192):
                sha256.update(chunk)
            return sha256.hexdigest()
        except Exception as e:
            log(f"⚠ Error downloading {url}: {e} (attempt {attempt+1}/{retries})")
            time.sleep(delay)
    return None

def get_multiple_sha256(urls):
    """
    Accepts a list of URLs and returns a list of (url, sha256) tuples.
    Computes SHA256 for each URL, skipping failures.
    """
    results = []
    for url in urls:
        sha = get_sha256(url)
        if sha:
            results.append((url, sha))
        else:
            log(f"❌ Failed to compute SHA256 for {url}")
    return results

def verify_sha256(url, expected_sha):
    """
    Verifies a single URL against its expected SHA256.
    Returns True if matches, False otherwise.
    """
    sha = get_sha256(url)
    if sha == expected_sha:
        return True
    else:
        log(f"❌ SHA256 mismatch for {url}: expected {expected_sha}, got {sha}")
        return False