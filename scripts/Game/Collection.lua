-- Pure cosmetic collection. Its RNG is separate from the jumping course.
local Skins=require("Game.Skins")
---@class NaiwaCollection
---@field tickets integer
---@field selected string
---@field owned table<string,boolean>
---@field pending string|nil
---@field seed integer
---@field draws integer
---@field falls integer
local Collection={}
Collection.__index=Collection
local function integer(value,fallback)
 if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then return fallback end
 return math.max(0,math.min(1000000000,math.floor(value)))
end
---@return NaiwaCollection
function Collection.new(data,seed)
 data=type(data)=="table" and data or {}
 ---@type NaiwaCollection
 local self=setmetatable({},Collection)
 self.tickets=integer(data.tickets,0)
 self.draws=integer(data.draws,0)
 self.falls=integer(data.falls,0)
 self.seed=math.max(1,integer(data.seed,seed or 7919))
 ---@type table<string,boolean>
 local owned={original=true}
 self.owned=owned
 if type(data.owned)=="table" then
  for id,value in pairs(data.owned) do if value==true and Skins.byId[id] then self.owned[id]=true end end
 end
 self.selected=type(data.selected)=="string" and self.owned[data.selected] and data.selected or "original"
 self.pending=type(data.pending)=="string" and Skins.byId[data.pending] and data.pending~="original" and data.pending or nil
 -- A reserved draw is already owned, even if the app closed during its animation.
 if self.pending then self.owned[self.pending]=true end
 return self
end
function Collection:export()
 local owned={}
 for id,value in pairs(self.owned) do owned[id]=value end
 return {tickets=self.tickets,selected=self.selected,owned=owned,pending=self.pending,
  seed=self.seed,draws=self.draws,falls=self.falls}
end
function Collection:random()
 self.seed=(self.seed*48271)%2147483647
 return self.seed/2147483647
end
function Collection:awardFall()
 self.tickets=self.tickets+1; self.falls=self.falls+1
end
function Collection:count()
 local count=0
 for _,skin in ipairs(Skins.list) do if self.owned[skin.id] then count=count+1 end end
 return count
end
function Collection:odds()
 ---@type number[]
 local weights={0,0,0,0}
 local total=0
 for _,skin in ipairs(Skins.list) do
  if skin.tier>0 and not self.owned[skin.id] then weights[skin.tier]=Skins.tiers[skin.tier].weight end
 end
 for _,weight in ipairs(weights) do total=total+weight end
 if total>0 then for i,weight in ipairs(weights) do weights[i]=weight/total end end
 return weights
end
function Collection:canDraw()
 return self.tickets>0 and not self.pending and self:count()<#Skins.list
end
function Collection:reserve()
 if not self:canDraw() then return nil end
 local odds=self:odds()
 local roll,total,tier=self:random(),0,1
 for i,weight in ipairs(odds) do total=total+weight; if roll<total then tier=i; break end end
 local pool={}
 for _,skin in ipairs(Skins.list) do
  if skin.tier==tier and not self.owned[skin.id] then pool[#pool+1]=skin.id end
 end
 local id=pool[math.min(#pool,math.floor(self:random()*#pool)+1)]
 if not id then return nil end
 self.tickets=self.tickets-1
 self.draws=self.draws+1
 self.pending=id
 self.owned[id]=true
 return id
end
function Collection:acknowledge(equip)
 if not self.pending then return false end
 if equip then self.selected=self.pending end
 self.pending=nil
 return true
end
function Collection:equip(id)
 if not self.owned[id] or not Skins.byId[id] then return false end
 self.selected=id; return true
end
return Collection
