-- Layered collectible carton. All boxes share the classic mascot, never the prize.
local Art=require("Game.UIArt")
local Sprite=require("Game.SkinSprite")
local Box={}
local ink,cream,gold=Art.ink,Art.cream,Art.gold
local function rect(vg,x,y,w,h,c)
 nvgBeginPath(vg);nvgRect(vg,x,y,w,h)
 nvgFillColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgFill(vg)
end
local function poly(vg,points,c)
 nvgBeginPath(vg);nvgMoveTo(vg,points[1],points[2])
 for i=3,#points,2 do nvgLineTo(vg,points[i],points[i+1]) end
 nvgClosePath(vg);nvgFillColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgFill(vg)
 nvgStrokeColor(vg,nvgRGBA(ink[1],ink[2],ink[3],255));nvgStrokeWidth(vg,2);nvgStroke(vg)
end
local function transform(vg,x,y,s,tilt)
 nvgSave(vg);nvgTranslate(vg,x,y);nvgRotate(vg,tilt or 0);nvgScale(vg,s,s)
end
-- Back, cavity and hinged flaps are behind the rising prize.
function Box.back(vg,x,y,s,opening,tilt)
 transform(vg,x,y,s,tilt)
 local p=opening or 0
 poly(vg,{-42,-72,-23,-86,52,-86,32,-72},{37,47,32})
 poly(vg,{-23,-86,52,-86,52,-86-47*p,-23,-86-47*p},cream)
 if p>0 then
  rect(vg,-16,-87-39*p,59,3,gold)
  poly(vg,{-42,-72,-23,-86,-23-28*p,-86-14*p,-42-29*p,-72-10*p},{191,180,130})
  poly(vg,{32,-72,52,-86,52+28*p,-86-14*p,32+29*p,-72-10*p},{224,211,162})
 end
 nvgRestore(vg)
end
function Box.front(vg,x,y,s,tilt)
 transform(vg,x,y,s,tilt)
 poly(vg,{32,-72,52,-86,52,12,32,26},{138,151,101})
 poly(vg,{-42,-72,32,-72,32,26,-42,26},cream)
 rect(vg,-38,-68,66,12,gold)
 rect(vg,-38,-53,66,61,{55,76,47})
 rect(vg,-35,-50,60,55,{74,96,57})
 -- Printed classic Naiwa is identical on every box, including locked slots.
 Sprite.draw(vg,"original",-7,4,49,1,-1,false)
 rect(vg,18,-46,4,4,gold);rect(vg,15,-43,10,3,gold);rect(vg,18,-40,4,4,gold)
 rect(vg,-35,12,42,3,ink);rect(vg,-35,18,31,2,{134,143,102})
 rect(vg,16,12,10,10,gold);rect(vg,19,15,4,4,ink)
 for i=0,4 do
  poly(vg,{38,-54+i*12,45,-59+i*12,45,-56+i*12,38,-51+i*12},{213,214,172})
 end
 nvgRestore(vg)
end
function Box.closed(vg,x,y,s,tear,tilt)
 Box.front(vg,x,y,s,tilt)
 transform(vg,x,y,s,tilt)
 poly(vg,{-42,-72,-23,-86,52,-86,32,-72},{239,220,157})
 poly(vg,{-38,-74,-22,-83,46,-83,31,-74},gold)
 local p=tear or 0
 -- A seal peels away before any flap moves; the contents stay opaque.
 if p<1 then rect(vg,-8+36*p,-79-18*p,12*(1-p)+2,20,{255,248,211}) end
 if p>0 and p<1 then
  poly(vg,{-5+39*p,-78-17*p,7+39*p,-78-17*p,12+53*p,-89-34*p,1+53*p,-89-34*p},cream)
 end
 nvgRestore(vg)
end
function Box.stand(vg,x,y,width,tint)
 local w=width/2
 poly(vg,{x-w,y-5,x-w+13,y-12,x+w-13,y-12,x+w,y-5,x+w,y+5,x-w,y+5},{83,91,56})
 rect(vg,x-w+3,y-4,width-6,4,tint or gold)
 rect(vg,x-w+9,y+1,width-18,2,cream)
end
return Box
