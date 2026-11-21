local UI=require("urhox-libs/UI")
local Sprite=require("Game.SkinSprite")
local Art=require("Game.UIArt")
local Platforms=require("Game.PlatformStyle")
local Pond=UI.Widget:Extend("NaiwaPlayfield")
local function rect(vg,x,y,w,h,c)
 nvgBeginPath(vg);nvgRect(vg,x,y,w,h);nvgFillColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgFill(vg)
end
local function ellipse(vg,x,y,rx,ry,c)
 nvgBeginPath(vg);nvgEllipse(vg,x,y,rx,ry);nvgFillColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgFill(vg)
end
local function line(vg,x,y,xx,yy,c,width)
 nvgBeginPath(vg);nvgMoveTo(vg,x,y);nvgLineTo(vg,xx,yy)
 nvgStrokeColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgStrokeWidth(vg,width or 2);nvgStroke(vg)
end
function Pond:Init(props)
 UI.Widget.Init(self,props);self.run=props.run
end
function Pond:loadImage() end -- textures load once inside the render context

-- Quiet water is still the fall hazard. No banks, leaves or dairy-product decor.
function Pond:water(vg,w,h,t)
 local menu=self.run.phase=="menu"
 rect(vg,0,0,w,h,menu and {36,51,39} or {67,99,84})
 for i=1,24 do
  local y=(i*103)%math.floor(h+80)-30
  local x=(i*137+math.sin(t*.45+i*2)*12)%math.floor(w+90)-50
  rect(vg,x,y,15+i%4*10,2,{173,195,147,menu and 12 or 26})
 end
end

-- Same renderer in the tutorial. Uniform scale and one shared alpha outline;
-- the source anchor matches the exact world-space landing point.
function Pond.drawPlatform(vg,x,y,p,t,run)
 local art=Platforms.get(p.kind)
 local sink=run:sinkProgress(p)
 local bob=math.sin(t*1.7+p.index)*1.4
 if p.kind=="stream" then
  for k=0,2 do
   local flow=(t*23+k*37)%115-57
   line(vg,x+flow-8,y+32+k*5,x+flow+4,y+32+k*5,{180,206,168,140},2)
  end
 end
 ellipse(vg,x,y+17,p.r*1.05,p.r*.30,{16,42,30,55})
 local scale=p.r/art.rx
 local topY=y+bob+run:surfaceDip(p)
 local f=art.rect
 local alpha=sink>.72 and math.max(0,(1-sink)/.28) or 1
 nvgSave(vg)
 -- Water covers its lower part as it sinks. Never morph the animal's proportions.
 if sink>0 then nvgIntersectScissor(vg,x-p.r*1.4,y-p.r*2,p.r*2.8,p.r*2+40-sink*50) end
 Art.region(vg,art.file,f,x+(f[1]-art.cx)*scale,topY+(f[2]-art.cy)*scale,f[3]*scale,f[4]*scale,alpha)
 nvgRestore(vg)
 if sink>.08 then
  for k=1,3 do
   local rise=(t*24+k*13)%30
   ellipse(vg,x+(k-2)*p.r*.57,y+20-rise,2.5,2.5,{202,221,179,145})
  end
 end
 return bob
end

function Pond:Render(vg)
 local l=self:GetAbsoluteLayout()
 if l.w<=0 or l.h<=0 then return end
 local run=self.run
 local s=math.min(l.w/480,l.h/740)
 local w,h=l.w/s,l.h/s
 nvgSave(vg);nvgIntersectScissor(vg,l.x,l.y,l.w,l.h)
 nvgTranslate(vg,l.x,l.y);nvgScale(vg,s,s)
 self:water(vg,w,h,run.clock)
 if run.phase=="menu" then
  local y=h*.53
  -- A compact display of the real platform family fills the home stage.
  -- These are decorative menu floats, never landing prediction markers.
  local left={kind="stream",index=2,r=44,standTime=0}
  local right={kind="spring",index=4,r=45,standTime=0}
  Pond.drawPlatform(vg,w/2-147+math.sin(run.clock*.7)*6,y+15,left,run.clock,run)
  Pond.drawPlatform(vg,w/2+145,y-22,right,run.clock,run)
  local center={kind="leaf",index=1,r=90,standTime=0}
  Pond.drawPlatform(vg,w/2,y,center,run.clock,run)
  Sprite.draw(vg,run.skinId,w/2,y+math.sin(run.clock*1.7+1)*1.4,170,1+math.floor(run.clock*2)%4,-1)
  nvgRestore(vg);return
 end
 local baseY=h*.61
 local function pos(x,y) return w/2+x-run.cameraX,baseY+(y-run.cameraY)*Platforms.PROJECTION end
 for i=#run.platforms,1,-1 do
  local p=run.platforms[i]
  local x,y=pos(p.x,p.y)
  if y>-120 and y<h+120 then Pond.drawPlatform(vg,x,y,p,run.clock,run) end
 end
 local x,y=pos(run.hero.x,run.hero.y)
 local face=run.target.x>run.hero.x and 1 or -1
 local phase=run.phase=="paused" and run.resumePhase or run.phase
 local frame=1+math.floor(run.clock*3)%4
 local height=123.0
 if phase=="charge" then frame=13;height=115-run.hold*5
 elseif phase=="flight" then frame=14
 elseif phase=="land" then frame=run.phaseTime<.16 and 15 or 1 end
 if phase~="over" and not(phase=="fall" and run.phaseTime>.33) then
  local alpha=phase=="fall" and math.max(0,1-run.phaseTime/.33) or 1
  local bob=phase=="flight" and 0 or math.sin(run.clock*1.7+run.current.index)*1.4
  local dip=run:surfaceDip(run.current)
  if phase=="flight" then dip=run.flight.startDip*(1-math.min(1,run.phaseTime/run.flight.duration)) end
  ellipse(vg,x,y+2,25-run.hopHeight*.05,9-run.hopHeight*.016,{18,40,26,65})
  Sprite.draw(vg,run.skinId,x,y+bob+dip-run.hopHeight,height,frame,face,false,alpha)
 end
 for _,r in ipairs(run.ripples) do
  local rx,ry=pos(r.x,r.y)
  local alpha=math.floor(150*(1-r.age/1.1))
  for k=1,2 do
   nvgBeginPath(vg);nvgEllipse(vg,rx,ry,14+r.age*65+k*7,7+r.age*25+k*4)
   nvgStrokeColor(vg,nvgRGBA(214,230,186,alpha));nvgStrokeWidth(vg,2);nvgStroke(vg)
  end
  if not r.success then
   for k=1,8 do
    local a=k*math.pi/4
    rect(vg,rx+math.cos(a)*r.age*70,ry+math.sin(a)*r.age*23-math.sin(math.min(1,r.age)*math.pi)*35,4,7,{207,225,185,alpha})
   end
  end
 end
 nvgRestore(vg)
end
return Pond
