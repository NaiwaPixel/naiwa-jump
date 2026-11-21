local UI=require("urhox-libs/UI")
local Skins=require("Game.Skins")
local Sprite=require("Game.SkinSprite")
local Art=require("Game.UIArt")
local FigureBox=require("Game.FigureBox")
local RewardView={}
local ink,cream,gold=Art.ink,Art.cream,Art.gold
local function fill(vg,c) nvgFillColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255)) end
local function rect(vg,x,y,w,h,c)
 nvgBeginPath(vg); nvgRect(vg,x,y,w,h); fill(vg,c); nvgFill(vg)
end
local function line(vg,x,y,xx,yy,c,width)
 nvgBeginPath(vg); nvgMoveTo(vg,x,y); nvgLineTo(vg,xx,yy)
 nvgStrokeColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255)); nvgStrokeWidth(vg,width or 3); nvgStroke(vg)
end
local function circle(vg,x,y,r,c)
 nvgBeginPath(vg); nvgCircle(vg,x,y,r); fill(vg,c); nvgFill(vg)
end
local function star(vg,x,y,r,c)
 rect(vg,x-r,y-2,r*2,4,c); rect(vg,x-2,y-r,4,r*2,c)
 rect(vg,x-4,y-4,8,8,c)
end
local function ease(p) return 1-(1-math.max(0,math.min(1,p)))^3 end
local function ring(vg,x,y,r,c,width)
 nvgBeginPath(vg);nvgCircle(vg,x,y,r)
 nvgStrokeColor(vg,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgStrokeWidth(vg,width);nvgStroke(vg)
end

local Stage=UI.Widget:Extend("NaiwaClawStage")
function Stage:Init(props) UI.Widget.Init(self,props); self.rewards=props.rewards end
function Stage:Render(vg)
 local l=self:GetAbsoluteLayout()
 if l.w<=0 or l.h<=0 then return end
 local model=self.rewards.box
 local s=math.min(l.w/360,l.h/330)
 nvgSave(vg); nvgIntersectScissor(vg,l.x,l.y,l.w,l.h)
 nvgTranslate(vg,l.x+(l.w-360*s)/2,l.y+(l.h-330*s)/2); nvgScale(vg,s,s)
 local stage,p,t=model.stage,model:progress(),model.clock
 local machine=stage=="ready" or stage=="align" or stage=="lower" or stage=="grip" or stage=="lift" or stage=="deliver"
 if machine then
  rect(vg,14,5,332,315,{26,63,58}); rect(vg,20,11,320,303,{92,144,116})
  rect(vg,29,49,302,213,{15,58,58}); rect(vg,36,57,288,198,{179,219,194})
  rect(vg,40,60,280,9,{209,239,209}); rect(vg,49,79,5,160,{215,242,216,85})
  for k=0,9 do
   local lit=math.floor(t*5+k)%3==0
   circle(vg,47+k*29,29,5,lit and cream or {197,169,96})
  end
  rect(vg,39,275,187,25,{35,86,72}); rect(vg,47,281,122,9,{238,204,119})
  rect(vg,244,269,77,40,{22,55,49}); rect(vg,251,277,62,27,{10,33,31})
  local lockedX=.15+(model.slot-1)*.175
  local clawX=model.x
  if stage=="align" then clawX=model.fromX+(lockedX-model.fromX)*ease(p)
  elseif stage~="ready" then clawX=lockedX end
  local clawY=100.0
  if stage=="lower" then clawY=100+94*(p*p*(3-2*p))
  elseif stage=="grip" then clawY=194
  elseif stage=="lift" then clawY=194-94*ease(p)
  elseif stage=="deliver" then clawX=lockedX+(.79-lockedX)*ease(p/.65) end
  for k=1,5 do
   if k~=model.slot or stage=="ready" or stage=="align" or stage=="lower" or stage=="grip" then
    FigureBox.closed(vg,(.15+(k-1)*.175)*360,238,.55,0,0)
   end
  end
  if stage=="lift" then FigureBox.closed(vg,clawX*360,clawY+44,.55,0,math.sin(p*math.pi*2)*.025)
  elseif stage=="deliver" then
   local drop=math.max(0,(p-.65)/.35)
   FigureBox.closed(vg,clawX*360,clawY+44+145*drop*drop,.55,0,0)
  end
  line(vg,clawX*360,66,clawX*360,clawY,{225,222,179},4)
  rect(vg,clawX*360-13,clawY-6,26,12,{239,203,124})
  local closed=stage=="grip" and p or ((stage=="lift" or stage=="deliver") and 1 or 0)
  if stage=="deliver" and p>.65 then closed=1-math.min(1,(p-.65)/.15) end
  local spread=28-closed*6
  line(vg,clawX*360-7,clawY+5,clawX*360-spread,clawY+23,cream,5)
  line(vg,clawX*360-spread,clawY+23,clawX*360-(22-closed*2),clawY+36,cream,5)
  line(vg,clawX*360+7,clawY+5,clawX*360+spread,clawY+23,cream,5)
  line(vg,clawX*360+spread,clawY+23,clawX*360+(22-closed*2),clawY+36,cream,5)
 else
  local rarity=Skins.tiers[model.rarity] or Skins.tiers[1]
  local revealed=model:showsCostume()
  local tint=revealed and rarity.color or gold
  local glow=nvgRadialGradient(vg,180,160,10,155,nvgRGBA(tint[1],tint[2],tint[3],100),nvgRGBA(30,65,54,0))
  nvgBeginPath(vg); nvgCircle(vg,180,160,155); nvgFillPaint(vg,glow); nvgFill(vg)
  -- A quiet, fixed stage makes the box and figure movement legible.
  line(vg,62,292,298,292,{116,133,82,95},2)
  if stage=="sealed" or stage=="opening" then
   local settle=stage=="sealed" and -12*math.exp(-model.t*9)*math.sin(model.t*17) or 0
   local tilt=stage=="opening" and math.sin(p*math.pi*4)*.018*(1-p) or 0
   FigureBox.closed(vg,180,240+settle,1.65,stage=="opening" and ease(p) or 0,tilt)
   for k=1,4 do star(vg,180+math.cos(k*1.57+.4)*117,160+math.sin(k*1.57+.4)*95,3,cream) end
  elseif stage=="unfolding" then
   FigureBox.back(vg,180,240,1.65,ease(p),0)
   FigureBox.front(vg,180,240,1.65,0)
  else
   local rising=stage=="rising"
   local rise=rising and ease(p) or 1
   local boxY=240+124*rise+(stage=="silhouette" and 75*ease(p/.35) or (revealed and 75 or 0))
   local boxScale=1.65-.6*rise
   local feet=360-126*rise
   if not revealed then FigureBox.back(vg,180,boxY,boxScale,1,0) end
   if revealed then
    local burst=stage=="burst" and ease(p) or 1
    local rays=10+model.rarity*3
    for k=1,rays do
     local angle=k*math.pi*2/rays+.2
     local r1=65+burst*35
     local r2=r1+14+model.rarity*5
     line(vg,180+math.cos(angle)*r1,155+math.sin(angle)*r1,180+math.cos(angle)*r2,155+math.sin(angle)*r2,
      {tint[1],tint[2],tint[3],stage=="burst" and math.floor(180*(1-p)) or 22},3)
     if stage=="burst" then
      star(vg,180+math.cos(angle)*(38+burst*112),150+math.sin(angle)*(30+burst*95)+p*p*25,
       2+k%3,{tint[1],tint[2],tint[3],math.floor(255*(1-p*.85))})
     end
    end
    if stage=="burst" then
     ring(vg,180,152,28+ease(p)*122,{tint[1],tint[2],tint[3],math.floor(230*(1-p))},5*(1-p)+1)
    end
   end
   FigureBox.stand(vg,180,feet+8,124,tint)
   if model:showsSilhouette() then
    -- Same frame, scale and anchor as the reveal: no shape morph or premature colours.
    Sprite.draw(vg,model.skinId,180,feet,170,1,-1,true)
    if stage=="silhouette" then
     for k=1,4 do star(vg,180+math.cos(k*1.57+.4)*(105-14*p),150+math.sin(k*1.57+.4)*(80-14*p),3,cream) end
    end
   elseif revealed then
    local frame=stage=="reveal" and (math.floor(model.t*3)%4+1) or 1
    local scalePop=stage=="burst" and 1+.045*math.sin(p*math.pi) or 1
    Sprite.draw(vg,model.skinId,180,feet,170*scalePop,frame,-1,false)
    -- One brief local flash, never repeated full-screen flashing.
    if stage=="burst" and p<.2 then
     circle(vg,180,151,105*(1-p/.2),{255,247,207,math.floor(190*(1-p/.2))})
    end
   end
   if not revealed then FigureBox.front(vg,180,boxY,boxScale,0) end
  end
 end
 nvgRestore(vg)
end

local function label(text,size,c,extra)
 local props={text=text,fontSize=size,fontColor=c or cream,textAlign="center",whiteSpace="normal",pointerEvents="none"}
 for k,v in pairs(extra or {}) do props[k]=v end
 return UI.Label(props)
end
local function button(text,fn,secondary,disabled)
 return Art.button(text,fn,secondary,disabled,{height=48,fontSize=18,padding=6})
end
local function shell(children)
 return UI.Panel {width="100%",height="100%",padding=18,gap=10,backgroundColor=Art.surface,children=children}
end

function RewardView.claw(rewards,actions)
 local c,b=rewards.collection,rewards.box
 local stage=b.stage
 local title,subtitle="奶蛙手办盲盒","每次落水 +1 次，次数可以攒着用"
 local controls={}
 if stage=="ready" then
  local full=c:count()>=#Skins.list
  subtitle=full and "时装已全部集齐，谢谢你的收集！" or "盲盒必得一套未拥有的时装"
  controls={label("剩余 "..c.tickets.." 次  ·  已收集 "..(c:count()-1).." / "..(#Skins.list-1),16),
   button(full and "全部集齐啦" or "抓一个盲盒",actions.grab,false,not c:canDraw()),
   button("继续冒险",actions.clawExit,true)}
 elseif stage=="sealed" then
  title,subtitle="你的盲盒到了","这次会拆出哪一套奶蛙？"
  controls={label("每个盒子，都藏着一套新时装",16),button("拆开盲盒",actions.openBox)}
 elseif stage=="opening" then
  title,subtitle="撕开封条……","惊喜还藏在盒子里"
  controls={label("",18)}
 elseif stage=="unfolding" then
  title,subtitle="打开盒盖","准备好了吗？"
  controls={label("",18)}
 elseif stage=="rising" then
  title,subtitle="慢慢升起来了","好像看到它了……"
  controls={label("",18)}
 elseif stage=="silhouette" then
  title,subtitle="会是谁呢……","先看一眼它的轮廓"
  controls={label("惊喜马上揭晓",18)}
 elseif stage=="burst" then
  title,subtitle="惊喜揭晓！",""
  controls={label("",18)}
 elseif stage=="reveal" then
  local skin=Skins.get(b.skinId)
  title,subtitle=skin.name,Skins.tierInfo(skin).name.."时装  ·  首次获得"
  controls={label(skin.detail,16),button("穿上它",actions.equipReward),button("收进衣柜",actions.storeReward,true)}
 else
  subtitle=stage=="lower" and "爪子慢慢落下……" or (stage=="lift" and "抓到啦，稳稳带回来！" or "小心护送你的盲盒")
  controls={label("盲盒里藏着一件新衣服",16),button("跳过抓取动画",actions.skipClaw,true)}
 end
 if rewards.error~="" then controls[#controls+1]=label(rewards.error,14,{255,189,148,255}) end
 local contents={label(title,28),label(subtitle,15,{203,224,185,255}),
  Stage {width="100%",flexGrow=1,flexBasis=0,minHeight=160,pointerEvents="none",rewards=rewards},
  UI.Panel {width="100%",minHeight=158,gap=8,children=controls}}
 return shell(contents)
end

local Mystery=UI.Widget:Extend("NaiwaUnopenedCostume")
function Mystery:Render(vg)
 local l=self:GetAbsoluteLayout()
 if l.w<=0 or l.h<=0 then return end
 local size=math.min(l.w/112,l.h/118)
 FigureBox.closed(vg,l.x+l.w/2-5*size,l.y+l.h/2+30*size,size,0,0)
end
local function portrait(skinId,owned,width,height)
 if owned then return Sprite.Portrait {skinId=skinId,width=width,height=height,pointerEvents="none"} end
 -- The same sealed box for every lock. No costume texture or silhouette is loaded.
 return Mystery {width=width,height=height,pointerEvents="none"}
end

function RewardView.wardrobe(rewards,actions)
 local c=rewards.collection
 local selected=Skins.get(rewards.focus)
 local owned=c.owned[selected.id]==true
 local rows={}
 local first=(rewards.page-1)*6+1
 for row=0,2 do
  local cards={}
  for col=0,1 do
   local skin=Skins.list[first+row*2+col]
   if skin then
    local thisId=skin.id
    local unlocked=c.owned[skin.id]==true
    cards[#cards+1]=UI.Panel {flexGrow=1,flexBasis=0,height=132,padding=5,gap=2,
     backgroundColor=selected.id==skin.id and {65,110,87,255} or {36,81,67,255},
     borderWidth=2,borderColor=Skins.tierInfo(skin).color,
     onClick=function() rewards:select(thisId) end,
     children={portrait(skin.id,unlocked,"100%",75),
      label(unlocked and skin.name or "未开启的盲盒",15),label((c.selected==skin.id and "穿着中" or (unlocked and "已拥有" or "未解锁")).." · "..Skins.tierInfo(skin).name,12)}}
   end
  end
  if #cards>0 then rows[#rows+1]=UI.Panel {width="100%",flexDirection="row",gap=8,children=cards} end
 end
 local pages=math.ceil(#Skins.list/6)
 local odds=c:odds()
 local chance=string.format("当前盲盒：日常 %.0f%% · 稀有 %.0f%% · 史诗 %.0f%% · 传说 %.0f%%",odds[1]*100,odds[2]*100,odds[3]*100,odds[4]*100)
 local body={UI.Panel {width="100%",flexDirection="row",gap=12,children={
   portrait(selected.id,owned,90,117),
   UI.Panel {flexGrow=1,flexBasis=0,gap=5,justifyContent="center",children={
    label(owned and selected.name or "未解锁时装",22),label(Skins.tierInfo(selected).name.." · "..(owned and selected.detail or "抓取盲盒后揭晓"),14),
    button(c.selected==selected.id and "正在穿着" or (owned and "换上这套" or "抓盲盒解锁"),actions.equipSkin,false,not owned or c.selected==selected.id)}}}},
  label("时装只改变外观，跳跃能力完全相同",13,{203,224,185,255})}
 for _,row in ipairs(rows) do body[#body+1]=row end
 body[#body+1]=label(chance,12,{203,224,185,255})
 body[#body+1]=label("集齐前不重复；某等级集齐后，其余等级按权重分配概率。",12,{203,224,185,255})
 if rewards.error~="" then body[#body+1]=label(rewards.error,13,{255,189,148,255}) end
 return shell({label("奶蛙衣柜",28),label("已收集 "..(c:count()-1).." / "..(#Skins.list-1).." 套时装",14),
  UI.ScrollView {width="100%",flexGrow=1,flexBasis=0,scrollY=true,children={UI.Panel {width="100%",gap=8,children=body}}},
  UI.Panel {width="100%",flexDirection="row",gap=8,children={
   UI.Panel {flexGrow=1,flexBasis=0,children={button("上一页",actions.prevSkin,true,rewards.page==1)}},
   label(rewards.page.." / "..pages,16,cream,{width=50,alignSelf="center"}),
   UI.Panel {flexGrow=1,flexBasis=0,children={button("下一页",actions.nextSkin,true,rewards.page==pages)}}}},
  button("返回",actions.closeRewards,true)})
end
return RewardView
