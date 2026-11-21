-- Collision and rendering share the exact visible animal cutout. The small
-- fixed foot allowance makes grazing the drawn edge forgiving at every size.
local Platforms={PROJECTION=0.62}
---@type table<string,{name:string,file:string,rect:number[],cx:number,cy:number,rx:number,ry:number,sizes:number[],step:number,rows:number[][]}>
Platforms.kinds=require("Game.PlatformMasks")
function Platforms.get(kind) return Platforms.kinds[kind] or Platforms.kinds.leaf end
function Platforms.depth(kind)
 local art=Platforms.get(kind)
 return art.ry/art.rx/Platforms.PROJECTION
end
function Platforms.contains(platform,dx,dy)
 local art=Platforms.get(platform.kind)
 local scale=platform.r/art.rx
 local x=art.cx+dx/scale-art.rect[1]
 local y=art.cy+dy*Platforms.PROJECTION/scale-art.rect[2]
 local pad=3/scale
 local first=math.max(1,math.floor((y-pad)/art.step)+1)
 local last=math.min(#art.rows,math.floor((y+pad)/art.step)+1)
 for row=first,last do
  local spans=art.rows[row]
  local top=(row-1)*art.step
  local ey=math.max(top-y,y-(top+art.step),0)
  for i=1,#spans,2 do
   local ex=math.max(spans[i]-x,x-spans[i+1],0)
   if ex*ex+ey*ey<=pad*pad then return true end
  end
 end
 return false
end
-- All kinds get genuinely different sizes; the first two landing targets stay
-- generous, then the seeded course mixes three sizes and eases down gradually.
function Platforms.radius(kind,index,steps,choice)
 if index<=3 then return index==2 and 80 or 74 end
 local art=Platforms.get(kind)
 local size=art.sizes[math.min(3,math.floor(choice*3)+1)]
 return math.max(50,size-math.min(8,math.floor(steps/10)*2))
end
return Platforms
