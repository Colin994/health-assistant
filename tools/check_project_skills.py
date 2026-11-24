#!/usr/bin/env python3
"""Validate this project's simple skill headers, links and reference inventory."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[1];skills=ROOT/'.agents/skills'
errors=[]
for entry in sorted(skills.glob('*/SKILL.md')):
 text=entry.read_text();header=text.split('---',2)
 if len(header)<3:errors.append(f'{entry}: unclosed metadata');continue
 name=re.search(r'^name:\s*([a-z0-9-]+)\s*$',header[1],re.M)
 desc=re.search(r'^description:\s*(.+)',header[1],re.M)
 if not name or name[1]!=entry.parent.name or not desc:errors.append(f'{entry}: invalid name/description')
 for link in re.findall(r'\]\(([^)]+)\)',text):
  if '://' not in link and not (entry.parent/link.split('#')[0]).is_file():errors.append(f'{entry}: missing {link}')
# Runtime source verification is possible on this local checkout; CI cannot depend
# on the ignored historical source directory or docs directory.
manifest=ROOT/'docs/skills-install-manifest.json'
if manifest.exists():
 data=json.loads(manifest.read_text())
 for rel,expected in data.get('installedFileHashes',{}).items():
  p=ROOT/rel
  if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=expected:errors.append(f'{rel}: installed snapshot changed; review and refresh manifest')
 for rel,expected in data.get('sourceFileHashes',{}).items():
  p=ROOT/rel
  if p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()!=expected:errors.append(f'{rel}: source changed, re-audit before syncing')
for error in errors:print(error)
print(f'{"FAIL" if errors else "PASS"}: project skill headers, routing references and available source hashes')
raise SystemExit(bool(errors))
