#!/usr/bin/env python3
"""Read-only checks for maintained UI surfaces, not a visual/a11y certification."""
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PACKAGES=['feature_home','feature_profile','feature_settings','feature_onboarding','feature_stretch']
files=[p for package in PACKAGES for p in (ROOT/package/'lib').rglob('*.dart')]
files += [ROOT/'feature_game/lib/src'/name for name in ['game_screen.dart','game_play_area.dart','game_result_overlay.dart']]
files += list((ROOT/'feature_game/lib/src/garden').glob('*.dart'))
# This is a definition file, not an exemption for the whole game.
DEFINITIONS={'feature_game/lib/src/garden/garden_ui_theme.dart'}
RULES={
 'raw-ui-color':r'Color\(0x|Colors\.(?:black|white)\b',
 'truncated-ui-label':r'TextOverflow\.ellipsis|withClampedTextScaling|FittedBox\(',
 'decorative-button-text':r'foregroundColor:\s*context\.tokens\.primary\b',
}
violations=[]
for path in files:
 rel=str(path.relative_to(ROOT))
 if rel in DEFINITIONS or path.name.endswith(('.g.dart','.freezed.dart')):continue
 for i,line in enumerate(path.read_text().splitlines(),1):
  if line.lstrip().startswith('//'):continue
  for name,pattern in RULES.items():
   if re.search(pattern,line):violations.append(f'{rel}:{i}: {name}: {line.strip()}')
for hit in violations:print(hit)
print(f'{"FAIL" if violations else "PASS"}: {len(files)} UI files, {len(violations)} rule hits; painters and assets require separate review')
raise SystemExit(bool(violations))
