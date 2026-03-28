import sys
from pathlib import Path
from config import PACKAGE_DIRS
from logger import log

# Import per-folder cache functions
from cache import load_cache, save_cache

# Import the package manager functions
from package_manager import update_package_cache, verify_cache, write_build_sh

# Import the GUI
import tkinter as tk
from package_scanner_gui import TermuxPackageGUI

# --- Original console fixer logic ---
def run_fixer_console():
    """
    CLI mode: scans all package folders in each PACKAGE_DIR and updates caches.
    """
    for pkg_dir in PACKAGE_DIRS:
        if not pkg_dir.exists():
            log(f"⚠ Package directory {pkg_dir} does not exist, skipping.")
            continue

        # Load folder-specific cache
        cache = load_cache(pkg_dir)

        # Pass 1: Gather sources for all packages in this folder
        for folder in pkg_dir.iterdir():
            if folder.is_dir():
                update_package_cache(folder, cache)

        # Pass 2: Verify all cached versions for this folder
        verify_cache(cache)

        # Pass 3: Write build.sh for every verified version in this folder
        write_build_sh(cache)

        # Save live cache
        save_cache(pkg_dir, cache)

    log("✅ All packages processed, all verified versions written.")


# --- Main entry ---
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--cli":
        # Run original console CLI mode
        run_fixer_console()
    else:
        # Launch GUI by default
        root = tk.Tk()
        app = TermuxPackageGUI(root)
        root.mainloop()