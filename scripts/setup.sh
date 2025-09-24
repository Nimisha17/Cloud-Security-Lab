#!/bin/bash
set -e

echo "[*] Packaging Cloud Function..."
cd cloud-function
zip -r ../function.zip main.py requirements.txt >/dev/null
cd ..

echo "[*] Done. function.zip is ready."
