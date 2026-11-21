local UI=require("urhox-libs/UI")
local Run=require("Game.Run")
local Pond=require("Game.Pond")
local Sprite=require("Game.SkinSprite")
local Art=require("Game.UIArt")
local TutorialView={}
local ink=Art.ink

-- Each example has an isolated run. Tutorial animation never advances the real
-- course, consumes a sinking leaf, changes the player's score, or earns tickets.
local Sample=UI.Widget:Extend("NaiwaTutorialPlatform")
function Sample:Init(props)
 UI.Widget.Init(self,props)
 self.demo=Run.new(1)
 self.demo.phase="ready"
 self.demo.current.kind=props.kind or "leaf"
 self.demo.current.r=50
 self.clock=0.0
end
function Sample:Update(dt)
 self.clock=self.clock+math.min(dt,.05)
end
function Sample:Render(vg)
 local l=self:GetAbsoluteLayout()
 if l.w<=0 or l.h<=0 then return end
 local run=self.demo
 local p,t=run.current,self.clock
 local x,y=80.0,77.0
 local frame,hop,alpha=1,0.0,1.0
 run.phase,run.hold="ready",0.0
 p.standTime=0.0
 if p.kind=="stream" then
  x=x+math.sin(t*.95)*23
 elseif p.kind=="sink" then
  p.standTime=math.min(Run.SINK_SECONDS,math.max(0,t%(Run.SINK_SECONDS+1.4)-.7))
  local progress=run:sinkProgress(p)
  alpha=math.min(1,(1-progress)/.25)
 elseif p.kind=="spring" then
  local cycle=t%3.6
  if cycle<1.2 then
   run.phase,run.hold="charge",cycle/1.2*Run.MAX_HOLD
   frame=13
  elseif cycle<2.3 then
   hop=math.sin((cycle-1.2)/1.1*math.pi)*33
   frame=14
  elseif cycle<2.5 then frame=15 end
 end
 local scale=math.min(l.w/160,l.h/118)
 nvgSave(vg); nvgIntersectScissor(vg,l.x,l.y,l.w,l.h)
 nvgTranslate(vg,l.x+(l.w-160*scale)/2,l.y+(l.h-118*scale)/2); nvgScale(vg,scale,scale)
 nvgBeginPath(vg); nvgRect(vg,0,0,160,118)
 nvgFillColor(vg,nvgRGBA(67,99,84,255)); nvgFill(vg)
 for k=1,3 do
  local xx=10+k*29+math.sin(t*.6+k)*5
  nvgBeginPath(vg); nvgRect(vg,xx,22+k*24,19,2)
  nvgFillColor(vg,nvgRGBA(188,220,179,80)); nvgFill(vg)
 end
 local bob=Pond.drawPlatform(vg,x,y,p,t,run)
 if alpha>0 then
  Sprite.draw(vg,"original",x,y+bob+run:surfaceDip(p)-hop,52,frame,-1,false,alpha)
 end
 nvgRestore(vg)
end

local function label(text,size,extra)
 local props={text=text,fontSize=size,fontColor=ink,textAlign="center",whiteSpace="normal",width="100%",pointerEvents="none"}
 for k,v in pairs(extra or {}) do props[k]=v end
 return UI.Label(props)
end
local function card(kind,title,description,tint)
 return UI.Panel {flexGrow=1,flexBasis=0,minWidth=0,padding=9,gap=5,backgroundColor=tint,pointerEvents="none",children={
  label(title,18),
  Sample {width="100%",height=118,kind=kind,pointerEvents="none"},
  label(description,15,{minHeight=55})}}
end
function TutorialView.build(finishButton)
 return UI.Panel {position="absolute",left=0,top=0,width="100%",height="100%",
  backgroundColor={9,39,35,210},justifyContent="center",alignItems="center",children={
   Art.card {width="94%",height="88%",maxWidth=490,padding=16,gap=10,children={
     label("先认一认动物浮台",25),
     label("按住蓄力，松手起跳；按得越久跳得越远。",16),
     label("浮台有大有小，踩到动物实体就能站住。",14,{fontColor={84,99,60,255}}),
     UI.ScrollView {width="100%",flexGrow=1,flexBasis=0,children={
      UI.Panel {width="100%",gap=10,children={
       UI.Panel {width="100%",flexDirection="row",gap=10,children={
        card("leaf","奶猫 · 站稳","可一直停留\n站稳后再起跳",{223,226,189,255}),
        card("stream","奶龟 · 漂动","会来回漂动\n奶蛙也跟着移动",{206,221,189,255})}},
       UI.Panel {width="100%",flexDirection="row",gap=10,children={
        card("sink","奶鼠 · 下沉","踩上约 3.6 秒下沉\n别停太久",{229,216,172,255}),
        card("spring","奶兔 · 弹跳","下一跳更远\n可以少蓄一点力",{224,226,187,255})}}
      }}}},
     label("落地得分，连续跳中平台中央有加分。",14),
     label("只有落水才结束，并获得 1 次抓盲盒机会。",14),
     finishButton
    }}
  }}
end
return TutorialView
