"""Read-only PNG analysis -> collision metadata. Never edits/saves an image.

The largest opaque component is the visible platform. Tiny isolated alpha specks
are excluded. Runtime support uses these row spans, not a guessed inner ellipse.
"""
from pathlib import Path
from collections import deque
import json, sys, hashlib
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.test-runs/python'))
from PIL import Image

atlas = json.loads((ROOT / 'art/platform-atlas.json').read_text(encoding='utf-8'))
step = 4
lines = ['-- Generated from original PNG alpha by dev-tools/read-platform-masks.py.', 'return {']
report = {}
for kind, item in atlas.items():
    path = ROOT / 'assets' / item['file']
    x,y,w,h = item['rect']
    with Image.open(path) as im:
        alpha = im.convert('RGBA').getchannel('A').crop((x,y,x+w,y+h)).tobytes()
    opaque = bytearray(a >= 160 for a in alpha)
    visited = bytearray(w*h)
    largest = []
    for pos in range(w*h):
        if not opaque[pos] or visited[pos]:
            continue
        queue, component = deque([pos]), []
        visited[pos] = 1
        while queue:
            p = queue.popleft()
            component.append(p)
            px,py = p%w,p//w
            for q in ((p-1 if px else -1),(p+1 if px+1<w else -1),
                      (p-w if py else -1),(p+w if py+1<h else -1)):
                if q >= 0 and opaque[q] and not visited[q]:
                    visited[q] = 1
                    queue.append(q)
        if len(component) > len(largest):
            largest = component
    solid = bytearray(w*h)
    for p in largest:
        solid[p] = 1
    rows = []
    for start in range(0,h,step):
        yy = min(h-1,start+step//2)
        runs = []
        xx = 0
        while xx < w:
            if solid[yy*w+xx]:
                begin = xx
                while xx < w and solid[yy*w+xx]:
                    xx += 1
                runs.extend([begin,xx])
            else:
                xx += 1
        rows.append(runs)
    lines.append(' '+kind+'={')
    for key,value in item.items():
        if isinstance(value,str):
            text = json.dumps(value,ensure_ascii=False)
        elif isinstance(value,list):
            text = '{'+','.join(str(n) for n in value)+'}'
        else:
            text = str(value)
        lines.append('  '+key+'='+text+',')
    lines.append('  step='+str(step)+', rows={')
    lines.extend('   {'+','.join(str(n) for n in row)+'},' for row in rows)
    lines.extend(['  }',' },'])
    report[kind] = {'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                    'opaque_component_pixels':len(largest),'rows':len(rows),'sample_step':step}
lines.append('}')
(ROOT / 'scripts/Game/PlatformMasks.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(ROOT / 'art/platform-mask-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
