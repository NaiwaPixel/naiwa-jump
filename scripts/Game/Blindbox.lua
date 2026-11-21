-- Animation state only. Ticket consumption/reward reservation happens once in Collection.
---@class NaiwaBlindbox
---@field stage string
---@field t number
---@field clock number
---@field x number
---@field fromX number
---@field slot integer
---@field skinId string|nil
---@field rarity integer
---@field events string[]
local Blindbox={}
Blindbox.__index=Blindbox
Blindbox.sequence={"align","lower","grip","lift","deliver","sealed","opening","unfolding","rising","silhouette","burst","reveal"}
Blindbox.durations={align=.3,lower=.75,grip=.35,lift=.75,deliver=.85,opening=.8,unfolding=.65,rising=.95,silhouette=1.0,burst=.7}
---@return NaiwaBlindbox
function Blindbox.new(pending)
 ---@type NaiwaBlindbox
 local self=setmetatable({},Blindbox)
 self.stage=pending and "sealed" or "ready"
 self.t,self.clock,self.x,self.fromX=0.0,0.0,.5,.5
 self.slot,self.rarity=3,1
 self.skinId=pending
 self.events={}
 return self
end
function Blindbox:setStage(stage)
 self.stage,self.t=stage,0.0
 self.events[#self.events+1]=stage
end
function Blindbox:grab(id,rarity)
 if self.stage~="ready" or not id then return false end
 self.skinId,self.rarity=id,rarity
 self.fromX=self.x
 self.slot=math.max(1,math.min(5,math.floor((self.x-.15)/.175+1.5)))
 self:setStage("align")
 return true
end
function Blindbox:open()
 if self.stage~="sealed" then return false end
 self:setStage("opening"); return true
end
function Blindbox:skip()
 if not self.skinId or self.stage=="ready" or self.stage=="sealed" or self.stage=="reveal" then return false end
 -- Never skip the silhouette on the first reveal; this only shortens claw transport.
 if self.stage=="align" or self.stage=="lower" or self.stage=="grip" or self.stage=="lift" or self.stage=="deliver" then
  self:setStage("sealed"); return true
 end
 return false
end
function Blindbox:progress()
 return math.min(1,self.t/(Blindbox.durations[self.stage] or 1))
end
function Blindbox:showsCostume()
 return self.stage=="burst" or self.stage=="reveal"
end
function Blindbox:showsSilhouette()
 return self.stage=="rising" or self.stage=="silhouette"
end
function Blindbox:update(dt)
 dt=math.max(0,math.min(dt,.05))
 self.clock=self.clock+dt
 if self.stage=="ready" then
  self.x=.15+(.5-.5*math.cos(self.clock*1.65))*.7
  return
 end
 self.t=self.t+dt
 local duration=Blindbox.durations[self.stage]
 if duration and self.t>=duration then
  for i,stage in ipairs(Blindbox.sequence) do
   if stage==self.stage then self:setStage(Blindbox.sequence[i+1]); break end
  end
 end
end
return Blindbox
