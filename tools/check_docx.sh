#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "Extracting document.xml..."
unzip -p build/output/dissertation.docx word/document.xml > /tmp/doc.xml

python3 - <<'PY'
import xml.etree.ElementTree as ET
try:
    ET.parse('/tmp/doc.xml')
    print('document.xml: OK')
except Exception as e:
    print('document.xml: ERROR', e)
PY

echo '--- head ---'
head -n 20 /tmp/doc.xml || true

echo '--- tail ---'
tail -n 20 /tmp/doc.xml || true

unzip -p build/output/dissertation.docx word/_rels/document.xml.rels > /tmp/rels.xml || true

echo '--- rels ---'
cat /tmp/rels.xml || true

unzip -p build/output/dissertation.docx "[Content_Types].xml" > /tmp/contenttypes.xml || true

echo '--- content types png lines ---'
grep -n "png\|jpg\|jpeg\|pdf" /tmp/contenttypes.xml || true
