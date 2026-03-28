#!/usr/bin/env python3
import os
from pathlib import Path
import json
import threading
import tkinter as tk
from tkinter import ttk, messagebox
from config import PACKAGE_DIRS, get_cache_file, get_missing_file
from package_manager import update_package_cache, verify_cache

class TermuxPackageGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Termux Packages Scanner")
        self.root.geometry("950x550")
        self.scanning = False
        self.build_packages = {}

        # --- Control frame ---
        ctrl_frame = tk.Frame(root)
        ctrl_frame.pack(fill=tk.X, pady=5)

        # Dropdown to select package folder
        self.folder_var = tk.StringVar()
        self.combo_folders = ttk.Combobox(ctrl_frame, textvariable=self.folder_var, state="readonly", width=60)
        folder_names = [str(p) for p in PACKAGE_DIRS if p.exists()]
        self.combo_folders['values'] = folder_names
        if folder_names:
            self.combo_folders.current(0)
        self.combo_folders.pack(side=tk.LEFT, padx=5)
        self.combo_folders.bind("<<ComboboxSelected>>", lambda e: self.load_packages())

        # Scan buttons
        self.btn_start_selected = tk.Button(ctrl_frame, text="Start Scan Selected", command=self.start_selected_scan)
        self.btn_start_selected.pack(side=tk.LEFT, padx=5)

        self.btn_start_all = tk.Button(ctrl_frame, text="Start Scan All", command=self.start_all_scan)
        self.btn_start_all.pack(side=tk.LEFT, padx=5)

        self.btn_stop = tk.Button(ctrl_frame, text="Stop Scan", command=self.stop_scan, state=tk.DISABLED)
        self.btn_stop.pack(side=tk.LEFT, padx=5)

        # --- Treeview ---
        self.tree = ttk.Treeview(root, columns=("Name", "Verified", "Status"), show='headings', selectmode='extended')
        self.tree.heading("Name", text="Package Name")
        self.tree.heading("Verified", text="Verified Versions")
        self.tree.heading("Status", text="Status / Notes")
        self.tree.column("Name", width=300)
        self.tree.column("Verified", width=130, anchor='center')
        self.tree.column("Status", width=500)
        self.tree.pack(fill=tk.BOTH, expand=True)

        vsb = ttk.Scrollbar(root, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        vsb.pack(side='right', fill='y')

        # Double-click event
        self.tree.bind("<Double-1>", self.on_double_click)

        # Load initial packages
        self.load_packages()

    # --- Load packages from selected folder ---
    def load_packages(self):
        selected_folder = Path(self.folder_var.get())
        if not selected_folder.exists():
            return

        self.cache_file = get_cache_file(selected_folder)
        self.missing_file = get_missing_file(selected_folder)

        # Load cache safely
        self.cache = {}
        if self.cache_file.exists() and self.cache_file.stat().st_size > 0:
            try:
                self.cache = json.load(self.cache_file.open())
            except Exception:
                self.cache = {}

        # Load missing packages safely
        self.missing = []
        if self.missing_file.exists() and self.missing_file.stat().st_size > 0:
            try:
                self.missing = json.load(self.missing_file.open())
            except Exception:
                self.missing = []

        self.populate_tree_from_cache(selected_folder)

    # --- Populate tree from cache ---
    def populate_tree_from_cache(self, folder_path):
        self.tree.delete(*self.tree.get_children())
        self.package_rows = {}
        for folder in folder_path.iterdir():
            if folder.is_dir():
                pkg_name = folder.name
                versions = self.cache.get(pkg_name, {}).get("versions", [])
                verified = sum(1 for v in versions if v.get("verified"))
                total = len(versions)
                status = f"{verified}/{total} verified" if total else "No versions"

                if pkg_name in self.missing:
                    status += " (Missing sources)"

                row_id = self.tree.insert("", tk.END, values=(pkg_name, verified, status))
                self.package_rows[row_id] = folder

        # Color tags
        self.tree.tag_configure("missing", background="#fdd")
        self.tree.tag_configure("verified", background="#dfd")
        self.tree.tag_configure("partial", background="#ffd")

        # Apply coloring safely
        for row_id in self.tree.get_children():
            try:
                status = self.tree.item(row_id, "values")[2]
                if "Missing" in status:
                    self.tree.item(row_id, tags=("missing",))
                elif "No versions" in status:
                    self.tree.item(row_id, tags=("partial",))
                elif "/" in status:
                    verified_count, total_count = status.split("/")[0], status.split("/")[1].split()[0]
                    if verified_count.isdigit() and total_count.isdigit():
                        if int(verified_count) < int(total_count):
                            self.tree.item(row_id, tags=("partial",))
                        else:
                            self.tree.item(row_id, tags=("verified",))
                    else:
                        self.tree.item(row_id, tags=("partial",))
                else:
                    self.tree.item(row_id, tags=("partial",))
            except Exception:
                self.tree.item(row_id, tags=("partial",))

    # --- Scan packages dynamically ---
    def scan_packages(self, package_list):
        self.scanning = True
        self.btn_stop.config(state=tk.NORMAL)
        self.btn_start_selected.config(state=tk.DISABLED)
        self.btn_start_all.config(state=tk.DISABLED)

        allowed_names = [f.name for f in package_list if f]

        for folder in package_list:
            if not self.scanning or folder is None:
                continue
            try:
                update_package_cache(
                    folder,
                    self.cache,
                    stop_callback=lambda: not self.scanning,
                    allowed_packages=allowed_names
                )
                verify_cache(
                    self.cache,
                    stop_callback=lambda: not self.scanning,
                    allowed_packages=allowed_names
                )
            except Exception as e:
                print(f"Error scanning {folder}: {e}")

        self.scanning = False
        self.btn_stop.config(state=tk.DISABLED)
        self.btn_start_selected.config(state=tk.NORMAL)
        self.btn_start_all.config(state=tk.NORMAL)
        self.load_packages()

    def start_selected_scan(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showinfo("Info", "No packages selected")
            return
        folders = [self.package_rows[row_id] for row_id in selected]
        threading.Thread(target=self.scan_packages, args=(folders,), daemon=True).start()

    def start_all_scan(self):
        folders = list(self.package_rows.values())
        threading.Thread(target=self.scan_packages, args=(folders,), daemon=True).start()

    def stop_scan(self):
        self.scanning = False

    # --- Double-click open folder/build.sh ---
    def on_double_click(self, event):
        item = self.tree.identify_row(event.y)
        if not item:
            return
        folder = self.package_rows.get(item)
        if not folder or not folder.exists():
            return
        build_scripts = list(folder.glob("build_*.sh"))
        path_to_open = build_scripts[0] if build_scripts else folder
        try:
            if os.name == "nt":
                os.startfile(str(path_to_open))
            else:
                os.system(f'xdg-open "{path_to_open}"')
        except Exception as e:
            messagebox.showerror("Error", f"Cannot open {path_to_open}: {e}")


if __name__ == "__main__":
    root = tk.Tk()
    app = TermuxPackageGUI(root)
    root.mainloop()