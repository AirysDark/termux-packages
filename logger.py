from config import LOG_FILE

def log(msg, versions=None):
    """
    Logs a message to stdout and the log file.

    Args:
        msg (str): The log message.
        versions (list, optional): List of package versions to include in the log.
    """
    if versions:
        version_str = ", ".join([v.get("version", "UNKNOWN") for v in versions])
        msg = f"{msg} | Versions: {version_str}"

    # Print to console
    print(msg)

    # Append to log file
    try:
        with open(LOG_FILE, "a") as f:
            f.write(msg + "\n")
    except Exception as e:
        print(f"⚠ Failed to write log: {e}")