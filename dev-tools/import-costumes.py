"""Copy approved PNGs unchanged and read alpha bounds into a Lua atlas descriptor.
No artwork is resized, recoloured, filtered or edited by this tool.
"""
from pathlib import Path
import json, re, shutil, hashlib, sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.test-runs/python'))
from PIL import Image
WORK=ROOT.parent
manifest=json.loads((ROOT/'art/costume-sources.json').read_text(encoding='utf-8'))
source=(WORK/'naiwa-binding/dist/costume-regions.js').read_text(encoding='utf-8')
old=json.loads(re.search(r'COSTUME_REGIONS=(\{.*\});',source).group(1))
dest=ROOT/'assets/image/skins'
dest.mkdir(parents=True,exist_ok=True)
assets=[('original',ROOT/'assets/image/naiwa.png',None)]
for name in manifest['existingIds']:
    target=dest/(name+'.png')
    shutil.copyfile(WORK/'costume-previews-20261107/sprites'/target.name,target)
    assets.append((name,target,old['costume-'+name+'-v1.png']))
absurd_path=ROOT/'art/absurd-costume-prompts.json'
absurd=json.loads(absurd_path.read_text(encoding='utf-8'))['costumes'] if absurd_path.exists() else []
for item in manifest['newAssets']+absurd:
    target=dest/(item['id']+'.png')
    shutil.copyfile(item['source'],target)
    assets.append((item['id'],target,None))

def grid_bounds(im):
    # Find transparent valleys near the expected four-by-four grid.
    alpha=im.getchannel('A').point(lambda x:255 if x>=64 else 0)
    w,h=im.size
    boundaries=[0]
    for n in (1,2,3):
        ideal=w*n/4
        samples=[]
        for x in range(round(ideal-38),round(ideal+38)):
            count=sum(alpha.crop((x,0,x+1,h)).getdata())
            samples.append((count,abs(x-ideal),x))
        boundaries.append(min(samples)[2])
    boundaries.append(w)
    columns=[]
    for c in range(4):
        left,right=boundaries[c:c+2]
        cuts=[0]
        for n in (1,2,3):
            ideal=h*n/4
            samples=[]
            for y in range(round(ideal-45),round(ideal+45)):
                count=sum(alpha.crop((left,y,right,y+1)).getdata())
                samples.append((count,abs(y-ideal),y))
            cuts.append(min(samples)[2])
        cuts.append(h)
        columns.append(cuts)
    return [[boundaries[c],columns[c][r],boundaries[c+1]-boundaries[c],columns[c][r+1]-columns[c][r]] for r in range(4) for c in range(4)]

atlas={}
report=[]
for name,path,known in assets:
    with Image.open(path) as src:
        im=src.convert('RGBA')
        assert im.getchannel('A').getextrema()[0]==0,(name,'no transparency')
        bounds=known or grid_bounds(im)
        frames=[]
        for x,y,w,h in bounds:
            bbox=im.getchannel('A').crop((x,y,x+w,y+h)).point(lambda a:255 if a>=64 else 0).getbbox()
            assert bbox,(name,'empty frame')
            l,t,r,b=bbox
            frames.append([x+l,y+t,r-l,b-t])
        assert len(frames)==16
        atlas[name]={'file':path.relative_to(ROOT/'assets').as_posix(),'frames':frames}
        report.append({'id':name,'size':im.size,'frames':len(frames),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

lines=['-- Generated atlas bounds; PNG artwork is copied unchanged.','return {']
for name,data in atlas.items():
    values=','.join('{'+','.join(map(str,f))+'}' for f in data['frames'])
    lines.append(f' ["{name}"]={{file="{data["file"]}",frames={{{values}}}}},')
lines.append('}')
(ROOT/'scripts/Game/SkinFrames.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(ROOT/'art/costume-atlas.json').write_text(json.dumps(atlas,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'art/import-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'images':len(report),'total_frames':len(report)*16,'artwork':'unchanged'},ensure_ascii=False))
