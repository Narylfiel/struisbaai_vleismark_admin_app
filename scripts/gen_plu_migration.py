# Generate 042_plu_list_import.sql with decimal plu_code (PostgreSQL treats leading-zero integers as octal)
import re
import os

base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
path = os.path.join(os.path.expanduser('~'), 'Downloads', 'plu_list_import.sql')
if not os.path.isfile(path):
    path = os.path.join(base, 'admin_app', 'supabase', 'seed_data', 'plu_list_import.sql')
out_path = os.path.join(base, 'admin_app', 'supabase', 'migrations', '042_plu_list_import.sql')

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

inserts = []
for line in lines:
    line = line.strip()
    if not line.startswith('INSERT'):
        continue
    m = re.match(
        r"INSERT INTO inventory_items \(plu_code, name, category, sell_price, is_active\) VALUES \((\d+), (.*)\);",
        line,
    )
    if not m:
        continue
    plu_str, rest = m.group(1), m.group(2)
    plu_decimal = int(plu_str)
    inserts.append("(%s, %s)" % (plu_decimal, rest))

header = """-- Migration 042: PLU list import (504 items). ON CONFLICT (plu_code) DO NOTHING.
INSERT INTO inventory_items (plu_code, name, category, sell_price, is_active)
VALUES
"""
body = ",\n".join(inserts)
footer = """
ON CONFLICT (plu_code) DO NOTHING;
"""
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(header + body + footer)
print("Wrote %d rows to %s" % (len(inserts), out_path))
