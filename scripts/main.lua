-- Adapted from TapTap Maker templates/scaffold-2d.lua.
-- Native UrhoX Lua entry: no H5 host or SDK from another platform.
local UI=require("urhox-libs/UI")
local Run=require("Game.Run")
local Storage=require("Game.Storage")
local Soundscape=require("Game.Audio")
local Interface=require("Game.Interface")
local Rewards=require("Game.Rewards")
local Leaderboard=require("Game.Leaderboard")
---@type NaiwaLeaderboard
local board_
local runUser_=0
local boardReturn_="menu"
local run_=Run.new(6247)
---@type NaiwaInterface
local interface_
---@type NaiwaRewards
local rewards_
---@type number[]
local listeners_={}
local tutorialReturn_="menu"
local tutorialStartsRun_=false
NaiwaJump={}

local function save()
 local ok=Storage.save(run_,rewards_ and rewards_.collection)
 if not ok then print("[NaiwaJump] Local progress could not be saved") end
 return ok
end
local function startRun()
 runUser_=board_ and board_:account() or 0
 run_:reset(false)
 Soundscape.begin()
end
local function openTutorial(startAfter)
 tutorialStartsRun_=startAfter==true
 tutorialReturn_=run_.phase
 run_.phase="tutorial"
end
local function finishTutorial()
 run_.tutorialSeen=true
 save()
 if tutorialStartsRun_ then startRun() else run_.phase=tutorialReturn_ end
end
local function requestStart()
 if run_.tutorialSeen then startRun() else openTutorial(true) end
end
local function overUI(event)
 local s=UI.GetScale()
 return UI.FindWidgetAt(event.x/s,event.y/s)~=nil
end

function Start()
 graphics.windowTitle="像素奶蛙跳一跳 | NaiwaPixel"
 input.mouseVisible=true
 input.mouseMode=MM_FREE
 run_=Run.new(os.time()%2147483646+1)
 local saved=Storage.load()
 run_.best=saved.best or 0
 run_.sound=saved.sound~=false
 run_.tutorialSeen=saved.tutorialSeen==true
 rewards_=Rewards.new(run_,saved.collection,save)
 board_=Leaderboard.new(rawget(_G,"clientCloud"),rawget(_G,"GetUserNickname"))
 Soundscape.init()
 Soundscape.enable(run_.sound)
 interface_=Interface.init(run_,{
  start=requestStart,
  tutorial=function() openTutorial(false) end,
  finishTutorial=finishTutorial,
  leaderboard=function()
   if run_.phase~="menu" and run_.phase~="over" then return end
   boardReturn_=run_.phase;run_.phase="leaderboard";board_:load()
  end,
  refreshBoard=function() board_:load() end,
  closeBoard=function() run_.phase=boardReturn_ end,
  claw=function() rewards_:openClaw() end,
  grab=function() rewards_:grab() end,
  openBox=function() rewards_.box:open() end,
  skipClaw=function() rewards_.box:skip() end,
  equipReward=function() rewards_:finish(true) end,
  storeReward=function() rewards_:finish(false) end,
  clawExit=function() if rewards_:close() then requestStart() end end,
  wardrobe=function() rewards_:wardrobe() end,
  equipSkin=function() rewards_:equip() end,
  prevSkin=function() rewards_:turnPage(-1) end,
  nextSkin=function() rewards_:turnPage(1) end,
  closeRewards=function() rewards_:close() end,
  pause=function() run_:pause() end,
  resume=function() run_:resume() end,
  home=function() run_:reset(true) end,
  sound=function()
   run_.sound=not run_.sound; Soundscape.enable(run_.sound); save(); interface_:rebuild()
  end
 },rewards_,board_)
 listeners_[1]=UI.Input.On("PointerDown",function(event)
  if event.pointerType=="mouse" and event.button~=MOUSEB_LEFT and event.button~=0 then return end
  if overUI(event) then return end
  run_:press("pointer:"..event.pointerId)
 end)
 listeners_[2]=UI.Input.On("PointerUp",function(event) run_:release("pointer:"..event.pointerId) end)
 listeners_[3]=UI.Input.On("PointerCancel",function(event)
  if run_.pointer=="pointer:"..event.pointerId then run_:cancel() end
 end)
 SubscribeToEvent("Update","HandleUpdate")
 SubscribeToEvent("KeyDown","HandleKeyDown")
 SubscribeToEvent("KeyUp","HandleKeyUp")
 SubscribeToEvent("InputFocus","HandleFocus")
 NaiwaJump={run=run_,interface=interface_,start=startRun,pause=function() run_:pause() end,
  resume=function() run_:resume() end,save=save,
  requestStart=requestStart,openTutorial=openTutorial,finishTutorial=finishTutorial,rewards=rewards_,board=board_}
 if rewards_.collection.pending then rewards_:openClaw() end
 print("[NaiwaJump] Ready: figure blindboxes + animal platforms; version 0.4.0")
end

function HandleUpdate(eventType,eventData)
 local dt=eventData["TimeStep"]:GetFloat()
 run_:update(dt)
 for _,event in ipairs(run_.events) do
  if event=="fallReward" then rewards_:awardFall();board_:record(run_.score,runUser_)
  elseif event=="save" then save() else Soundscape.play(event) end
 end
 run_.events={}
 rewards_:update(dt)
 board_:update(dt)
 Soundscape.presentation(run_.phase=="claw" and rewards_.box.stage or "")
 for _,event in ipairs(rewards_.box.events) do
  if event=="grip" then Soundscape.play("claw")
  elseif event=="sealed" then Soundscape.play("boxland")
  elseif event=="opening" then Soundscape.play("peel")
  elseif event=="unfolding" then Soundscape.play("open")
  elseif event=="rising" then Soundscape.play("rise")
  elseif event=="silhouette" then Soundscape.play("suspense")
  elseif event=="burst" then Soundscape.play("reveal") end
 end
 rewards_.box.events={}
 interface_:update()
end
function HandleKeyDown(eventType,eventData)
 if eventData["Repeat"]:GetBool() then return end
 local key=eventData["Key"]:GetInt()
 if key==KEY_SPACE then
  if run_.phase=="menu" or run_.phase=="over" then requestStart()
  elseif run_.phase=="tutorial" then finishTutorial()
  elseif run_.phase=="claw" then
   if rewards_.box.stage=="ready" then rewards_:grab()
   elseif rewards_.box.stage=="sealed" then rewards_.box:open() end
  elseif run_.phase=="paused" then run_:resume()
  else run_:press("keyboard") end
 elseif key==KEY_ESCAPE then
  if run_.phase=="leaderboard" then run_.phase=boardReturn_
  elseif run_.phase=="claw" or run_.phase=="wardrobe" then rewards_:close()
  elseif run_.phase=="tutorial" then finishTutorial()
  elseif run_.phase=="paused" then run_:resume() else run_:pause() end
 end
end
function HandleKeyUp(eventType,eventData)
 if eventData["Key"]:GetInt()==KEY_SPACE then run_:release("keyboard") end
end
function HandleFocus(eventType,eventData)
 local focused=eventData["Focus"]:GetBool()
 rewards_.suspended=not focused
 if not focused then run_:pause() end
end
function Stop()
 if run_ then save() end
 for i,name in ipairs({"PointerDown","PointerUp","PointerCancel"}) do
  if listeners_[i] then UI.Input.Off(name,listeners_[i]) end
 end
 Soundscape.stop()
 UI.Shutdown()
end
