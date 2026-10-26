#!/usr/bin/env python3
"""Validate local Markdown links, illustrative SVG files, and forbidden binary extensions."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
bad = []
files = list(root.rglob("*"))
for path in files:
    if not path.is_file() or ".git" in path.parts:
        continue
    if path.suffix.lower() in {".pbix", ".pbit", ".xlsx", ".pdf", ".csv", ".parquet", ".zip"}:
        bad.append(f"forbidden file: {path.relative_to(root)}")
    if path.suffix.lower() == ".md":
        text = path.read_text(encoding="utf-8")
        links = re.findall(r"!?(?:\[[^\]]*\])\(([^)]+)\)", text)
        for dest in links:
            if dest.startswith(("http:", "https:", "#", "mailto:")):
                continue
            ref = (path.parent / dest.split("#", 1)[0]).resolve()
            if not ref.is_relative_to(root):
                bad.append(f"link escapes root: {path.relative_to(root)}: {dest}")
            elif not ref.exists():
                bad.append(f"broken link: {path.relative_to(root)}: {dest}")
    if path.suffix.lower() == ".svg":
        raw=path.read_text(encoding="utf-8")
        if "<svg" not in raw or "</svg>" not in raw:
            bad.append(f"invalid SVG wrapper: {path.relative_to(root)}")
if bad:
    print("\n".join(bad))
    sys.exit(1)
print(f"PASS: {len(files)} files scanned; local Markdown links and privacy guardrails validated.")
