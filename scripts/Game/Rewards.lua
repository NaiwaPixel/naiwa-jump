local Collection=require("Game.Collection")
local Blindbox=require("Game.Blindbox")
local Skins=require("Game.Skins")
---@class NaiwaRewards
---@field run NaiwaRun
---@field collection NaiwaCollection
---@field box NaiwaBlindbox
---@field save fun():boolean
---@field page integer
---@field focus string
---@field returnPhase string
---@field error string
---@field dirty boolean
---@field retryTime number
---@field suspended boolean
local Rewards={}
Rewards.__index=Rewards
---@return NaiwaRewards
function Rewards.new(run,saved,save)
 ---@type NaiwaRewards
 local self=setmetatable({},Rewards)
 self.run,self.save=run,save
 self.collection=Collection.new(saved,os.time()%1000000000+1)
 self.box=Blindbox.new(self.collection.pending)
 self.page,self.focus,self.returnPhase=1,self.collection.selected,"menu"
 self.error,self.dirty,self.retryTime="",false,0.0
 self.suspended=false
 self.run.skinId=self.collection.selected
 return self
end
function Rewards:refresh() self.run.serial=self.run.serial+1 end
function Rewards:persist()
 local ok=self.save()
 self.error=ok and "" or "本机存档暂时写入失败，请稍后重试"
 self.dirty=not ok
 return ok
end
function Rewards:awardFall()
 self.collection:awardFall()
 self:persist()
end
function Rewards:openClaw()
 if self.run.phase~="menu" and self.run.phase~="over" then return false end
 self.returnPhase=self.run.phase
 self.box=Blindbox.new(self.collection.pending)
 if self.collection.pending then self.box.rarity=Skins.get(self.collection.pending).tier end
 self.run.phase="claw"; self:refresh(); return true
end
function Rewards:grab()
 if self.run.phase~="claw" or self.box.stage~="ready" then return false end
 local before=self.collection:export()
 local id=self.collection:reserve()
 if not id then return false end
 -- Save the ticket debit and reward together BEFORE any reveal animation.
 if not self:persist() then
  self.collection=Collection.new(before); self.dirty=true; self:refresh(); return false
 end
 self.box:grab(id,Skins.get(id).tier)
 self:refresh(); return true
end
function Rewards:finish(equip)
 if self.run.phase~="claw" or self.box.stage~="reveal" or not self.collection.pending then return false end
 local before=self.collection:export()
 self.collection:acknowledge(equip)
 if not self:persist() then self.collection=Collection.new(before); self:refresh(); return false end
 self.run.skinId=self.collection.selected
 self.box=Blindbox.new()
 self:refresh(); return true
end
function Rewards:close()
 if self.run.phase=="claw" then
  if self.box.stage~="ready" then return false end
 elseif self.run.phase~="wardrobe" then return false end
 self.run.phase=self.returnPhase
 self:refresh(); return true
end
function Rewards:wardrobe()
 if self.run.phase~="menu" and self.run.phase~="over" and self.run.phase~="paused" then return false end
 self.returnPhase=self.run.phase
 self.focus=self.collection.selected
 self.run.phase="wardrobe"; self:refresh(); return true
end
function Rewards:select(id)
 if self.run.phase~="wardrobe" or not Skins.byId[id] then return end
 self.focus=id; self:refresh()
end
function Rewards:equip()
 local before=self.collection.selected
 if not self.collection:equip(self.focus) then return false end
 if not self:persist() then self.collection.selected=before; self:refresh(); return false end
 self.run.skinId=self.collection.selected; self:refresh(); return true
end
function Rewards:turnPage(delta)
 self.page=math.max(1,math.min(math.ceil(#Skins.list/6),self.page+delta)); self:refresh()
end
function Rewards:update(dt)
 if self.dirty then
  self.retryTime=self.retryTime+dt
  if self.retryTime>5 then self.retryTime=0; self:persist() end
 end
 if self.run.phase=="claw" and not self.suspended then self.box:update(dt) end
end
return Rewards
