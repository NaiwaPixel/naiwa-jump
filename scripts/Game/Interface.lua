local UI=require("urhox-libs/UI")
local Pond=require("Game.Pond")
local Run=require("Game.Run")
local RewardView=require("Game.RewardView")
local TutorialView=require("Game.TutorialView")
local LeaderboardView=require("Game.LeaderboardView")
local Art=require("Game.UIArt")
---@class NaiwaInterface
---@field run NaiwaRun
---@field actions table<string, function>
---@field view string
---@field serial integer
---@field score Label
---@field best Label
---@field notice Label
---@field hint Label
---@field help Label
---@field rewards NaiwaRewards
---@field boxStage string
---@field board NaiwaLeaderboard
---@field boardSerial integer
local Interface={}
local ink,cream,muted,gold=Art.ink,Art.cream,Art.muted,Art.gold

local Meter=UI.Widget:Extend("NaiwaChargeMeter")
function Meter:Init(props) UI.Widget.Init(self,props); self.run=props.run end
function Meter:Render(vg)
 local l=self:GetAbsoluteLayout(); local run=self.run
 local p=run.phase=="charge" and run.hold/Run.MAX_HOLD or 0
 nvgBeginPath(vg); nvgRect(vg,l.x,l.y,l.w,l.h); nvgFillColor(vg,nvgRGBA(12,57,51,230)); nvgFill(vg)
 if p>0 then
  nvgBeginPath(vg); nvgRect(vg,l.x+3,l.y+3,(l.w-6)*p,l.h-6)
  nvgFillColor(vg,nvgRGBA(251,205,98,240)); nvgFill(vg)
 end
 for i=1,9 do
  nvgBeginPath(vg); nvgRect(vg,l.x+l.w*i/10,l.y+3,2,l.h-6)
  nvgFillColor(vg,nvgRGBA(20,63,54,90)); nvgFill(vg)
 end
end

local function label(text,size,c,extra)
 local p={text=text,fontSize=size,fontColor=c or cream,textAlign="center",pointerEvents="none"}
 for k,v in pairs(extra or {}) do p[k]=v end
 return UI.Label(p)
end
local function button(text,action,secondary)
 return Art.button(text,action,secondary)
end

---@param run NaiwaRun
---@param actions table<string, function>
---@return NaiwaInterface
function Interface.init(run,actions,rewards,board)
 UI.Init({theme=UI.Theme.ExtendTheme(UI.Theme.defaultTheme,{
  fonts={{family="sans",weights={normal="Fonts/MiSans-Regular.ttf",bold="Fonts/MiSans-Regular.ttf"}},
   {family="pixel",weights={normal="Fonts/FusionPixel.ttf",bold="Fonts/FusionPixel.ttf"}}},
  colors={primary=gold,background=ink,text=cream,textSecondary=muted},
  componentDefaults={borderRadius=0},
  components={Button={boxShadow=false}}
 }),scale=UI.Scale.DEFAULT})
 ---@type NaiwaInterface
 local self=setmetatable({},Interface)
 self.run,self.actions,self.view,self.serial=run,actions,"",-1
 self.rewards,self.boxStage=rewards,""
 self.board,self.boardSerial=board,-1
 Interface.__index=Interface
 self:rebuild()
 return self
end

function Interface:kind()
 local p=self.run.phase
 if p=="menu" or p=="over" or p=="paused" or p=="tutorial" or p=="claw" or p=="wardrobe" or p=="leaderboard" then return p end
 return "playing"
end

function Interface:rebuild()
 local run,actions=self.run,self.actions
 self.view,self.serial=self:kind(),run.serial
 self.boxStage=self.rewards.box.stage
 self.boardSerial=self.board.serial
 local pond=Pond {id="pond",position="absolute",left=0,top=0,width="100%",height="100%",
  pointerEvents="none",run=run}
 self.pond=pond
 local content={}
 if self.view=="menu" then
  content[#content+1]=UI.Panel {position="absolute",left=20,right=20,top="8.5%",gap=9,pointerEvents="none",children={
   label("NAIWAPIXEL",12,muted,{letterSpacing=3}),
   label("像素奶蛙跳一跳",36,gold,{fontFamily="pixel",textShadow={offsetX=2,offsetY=3,blur=0,color=ink}}),
   label("跳过动物浮台，收集下一件怪衣服。",15,muted)}}
  local stats={{"最高分",tostring(run.best)},{"时装收集",(self.rewards.collection:count()-1).." / 25"},{"盲盒机会",tostring(self.rewards.collection.tickets)}}
  local statCards={}
  for _,stat in ipairs(stats) do
   statCards[#statCards+1]=UI.Panel {flexGrow=1,flexBasis=0,padding=9,gap=3,backgroundColor={47,65,43,235},
    borderWidth=1,borderColor={92,107,61,180},children={label(stat[2],23,gold),label(stat[1],12,muted)}}
  end
  content[#content+1]=UI.Panel {position="absolute",left="9%",right="9%",top="23%",flexDirection="row",gap=8,pointerEvents="none",children=statCards}
  content[#content+1]=UI.Panel {position="absolute",left=20,right=20,top="65%",gap=4,pointerEvents="none",children={
   label("每一跳，都有新惊喜",19,gold),label("落水攒盲盒 · 开盒换时装",14,muted)}}
  content[#content+1]=UI.Panel {position="absolute",left="14%",right="14%",bottom="5%",gap=9,children={
   label("按住蓄力 · 松手起跳",17),
   button("开始跳跃",actions.start),
   UI.Panel {width="100%",flexDirection="row",gap=8,children={
    UI.Panel {flexGrow=1,flexBasis=0,children={button("衣柜",actions.wardrobe,true)}},
    UI.Panel {flexGrow=1,flexBasis=0,children={button("手办盲盒",actions.claw,true)}}}},
   UI.Panel {width="100%",flexDirection="row",gap=8,children={
    UI.Panel {flexGrow=1,flexBasis=0,children={button("教程",actions.tutorial,true)}},
    UI.Panel {flexGrow=1,flexBasis=0,children={button("排行榜",actions.leaderboard,true)}}}},
   label("NaiwaPixel · 轻点开跳",12,muted)}}
 elseif self.view=="leaderboard" then
  content[#content+1]=LeaderboardView.build(self.board,actions)
 elseif self.view=="claw" then
  content[#content+1]=RewardView.claw(self.rewards,actions)
 elseif self.view=="wardrobe" then
  content[#content+1]=RewardView.wardrobe(self.rewards,actions)
 elseif self.view=="tutorial" then
  content[#content+1]=TutorialView.build(button("知道了，继续",actions.finishTutorial))
 elseif self.view=="playing" then
  self.score=label(tostring(run.score),48,cream)
  self.best=label("最佳  "..run.best,14,muted)
  self.notice=label("",23,gold,{position="absolute",top="24%",left=8,right=8,
   textShadow={offsetX=2,offsetY=2,blur=0,color=ink}})
  content[#content+1]=UI.Panel {position="absolute",left=20,top=16,pointerEvents="none",children={self.score,self.best}}
  content[#content+1]=UI.Panel {position="absolute",right=20,top=22,width=65,children={button("暂停",actions.pause,true)}}
  content[#content+1]=self.notice
  self.hint=label("按住屏幕蓄力，松手起跳",19)
  self.help=label("按得越久，跳得越远",13,muted)
  content[#content+1]=UI.Panel {position="absolute",left="13%",right="13%",bottom=32,height=120,gap=13,pointerEvents="none",children={
   self.hint,Meter {width="100%",height=21,run=run,pointerEvents="none"},self.help}}
 else
  local paused=self.view=="paused"
  ---@type Widget[]
  local options={
   label(paused and "歇一会儿" or "扑通，落水啦",27,ink),
   label(paused and "奶蛙等你回来" or tostring(run.score).." 分",paused and 16 or 40,ink),
   label(paused and "继续后不会自动起跳" or run.reason,15,{86,111,77,255},{whiteSpace="normal"}),
   label("本机最佳 "..run.best,14,{86,111,77,255})}
  if not paused then
   options[#options+1]=label("+1 抓取机会 · 共 "..self.rewards.collection.tickets.." 次",16,ink)
   options[#options+1]=button("去抓盲盒",actions.claw)
  end
  options[#options+1]=button(paused and "继续跳跃" or "再来一次",paused and actions.resume or actions.start,true)
  if not paused then options[#options+1]=button("排行榜",actions.leaderboard,true) end
  options[#options+1]=UI.Panel {width="100%",flexDirection="row",gap=8,children={
   UI.Panel {flexGrow=1,flexBasis=0,children={button("衣柜",actions.wardrobe,true)}},
   UI.Panel {flexGrow=1,flexBasis=0,children={button("教程",actions.tutorial,true)}}}}
  options[#options+1]=button(run.sound and "声音：开" or "声音：关",actions.sound,true)
  options[#options+1]=button("返回首页",actions.home,true)
  content[#content+1]=UI.Panel {position="absolute",left=0,top=0,width="100%",height="100%",
   backgroundColor={9,39,35,125},justifyContent="center",alignItems="center",children={
    Art.card {width="88%",maxWidth=430,padding=20,gap=10,children=options}
   }}
 end
 if self.view=="menu" then
  content[#content+1]=UI.Panel {position="absolute",right=16,top=12,width=90,children={button(run.sound and "声音开" or "声音关",actions.sound,true)}}
 end
 local safe=UI.SafeAreaView {width="100%",height="100%",nativeMenuInset=true,
  pointerEvents="box-none",children={UI.Panel {width="100%",height="100%",pointerEvents="box-none",children=content}}}
 local root=UI.Panel {width="100%",height="100%",pointerEvents="box-none",children={pond,safe}}
 UI.SetRoot(root,true)
 pond:loadImage()
 self.root=root
end

function Interface:update()
 if self:kind()~=self.view or self.serial~=self.run.serial or (self.view=="claw" and self.boxStage~=self.rewards.box.stage)
  or (self.view=="leaderboard" and self.boardSerial~=self.board.serial) then self:rebuild() end
 if self.view=="playing" then
  local run=self.run
  self.score:SetText(tostring(run.score))
  self.best:SetText("最佳  "..run.best)
  self.notice:SetText(run.noticeTime>0 and run.notice or "")
  local onLeaf=run.phase=="ready" or run.phase=="charge" or run.phase=="land"
  local warning=onLeaf and run.current.kind=="sink" and run.current.standTime>Run.SINK_SECONDS-1.2
  self.hint:SetText(warning and "奶鼠浮台快沉啦，快跳！" or (run.phase=="charge" and
    (run.hold>=Run.MAX_HOLD and "蓄满啦，松手！" or "松手，跳！") or
    (run.phase=="flight" and "跳向下一个浮台" or (run.phase=="fall" and "扑通……" or "按住屏幕蓄力，松手起跳"))))
  local tip="按得越久，跳得越远  ·  空格键也能玩"
  if onLeaf and run.current.kind=="sink" then tip="奶鼠浮台承重后会下沉，别停太久"
  elseif onLeaf and run.current.kind=="spring" then tip="奶兔浮台更有劲，轻按也能跳远"
  elseif onLeaf and run.current.kind=="stream" then tip="奶龟带着你一起漂动"
  elseif run.target.kind=="stream" then tip="前面是奶龟，观察它的摆动"
  elseif run.target.kind=="sink" then tip="前面是奶鼠，落上后要及时起跳"
  elseif run.target.kind=="spring" then tip="前面是奶兔，下一跳更有弹力" end
  self.help:SetText(tip)
 end
end

return Interface
