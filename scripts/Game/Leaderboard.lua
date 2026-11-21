-- TapTap Maker clientCloud is the sole online backend. No local scores are
-- imported into another account, and a failed read never overwrites cloud data.
---@class NaiwaLeaderboard
---@field cloud ClientCloud|nil
---@field nicknames fun(options: GetUserNicknameOptions)|nil
---@field userId integer
---@field epoch integer
---@field request integer
---@field serial integer
---@field rows {rank:integer,userId:integer,score:integer,name:string,me:boolean}[]
---@field rank number|nil
---@field cloudBest integer
---@field wanted integer
---@field clock number
---@field retryAt number
---@field retries integer
---@field state string
---@field sync string
---@field myState string
---@field loading boolean
---@field writing boolean
---@field lastLoad number
local Board={}
Board.__index=Board
Board.KEY="naiwa_jump_best_v1"
local function integer(v)
 return type(v)=="number" and v==v and v>=0 and v<=2147483647 and v%1==0
end
---@return NaiwaLeaderboard
function Board.new(cloud,nicknames)
 ---@type NaiwaLeaderboard
 local self=setmetatable({cloud=cloud,nicknames=nicknames,userId=0,epoch=0,request=0,serial=0,
  rows={},rank=nil,cloudBest=0,wanted=0,clock=0,retryAt=0,retries=0,
  state="idle",sync="idle",myState="idle",loading=false,writing=false,lastLoad=-10},Board)
 return self
end
function Board:changed() self.serial=self.serial+1 end
function Board:account()
 local ok,id=pcall(function() return self.cloud and self.cloud.userId end)
 if not ok or not integer(id) or id<=0 then id=0 end
 if id~=self.userId then
  self.userId=id;self.epoch=self.epoch+1;self.request=self.request+1
  self.rows={};self.rank=nil;self.cloudBest=0;self.wanted=0
  self.loading=false;self.writing=false;self.retryAt=0;self.retries=0
  self.state="idle";self.sync="idle";self.myState="idle";self.lastLoad=-10
  self:changed()
 end
 return id
end
function Board:current(epoch,id)
 return self:account()==id and self.epoch==epoch
end
function Board:record(score,runUser)
 local id=self:account()
 -- A run started offline or under a different account cannot migrate to this ID.
 if id==0 or runUser~=id or not integer(score) or score<=0 then return false end
 self.wanted=math.max(self.wanted,score)
 self.retries=0
 self:upload()
 return true
end
function Board:upload()
 local id=self:account()
 if id==0 or self.writing or self.wanted<=self.cloudBest then return end
 local epoch=self.epoch
 self.writing=true;self.sync="loading";self.retryAt=0;self:changed()
 local done=false
 local function valid() return not done and self:current(epoch,id) end
 local function failed()
  if not valid() then return end
  done=true;self.writing=false;self.sync="error";self.retries=self.retries+1
  self.retryAt=self.retries<=2 and self.clock+15*self.retries or 0
  self:changed()
 end
 local readDone=false
 local ok=pcall(function() self.cloud:Get(Board.KEY,{
  ok=function(_,scores)
   if not valid() or readDone then return end
   readDone=true
   local old=(scores or {})[Board.KEY]
   if old~=nil and not integer(old) then failed();return end
   self.cloudBest=math.max(self.cloudBest,old or 0)
   local score=math.max(self.cloudBest,self.wanted)
   local function saved()
    if not valid() then return end
    done=true;self.writing=false;self.sync="saved";self.retries=0
    self.cloudBest=math.max(self.cloudBest,score);self:changed()
    if self.wanted>self.cloudBest then self:upload() end
   end
   if score==old then saved();return end
   local writeOk=pcall(function() self.cloud:SetInt(Board.KEY,score,{ok=saved,error=failed,timeout=failed}) end)
   if not writeOk then failed() end
  end,
  error=failed,timeout=failed
 }) end)
 if not ok then failed() end
end
function Board:load()
 local id=self:account()
 if id==0 then self.state="offline";self:changed();return false end
 if self.loading or self.clock-self.lastLoad<5 then return false end
 self.lastLoad=self.clock;self.request=self.request+1
 local request,epoch=self.request,self.epoch
 self.loading=true;self.state="loading";self.myState="loading";self:changed()
 local function valid() return self:current(epoch,id) and self.request==request end
 local listDone,myDone=false,false
 local function failList()
  if not valid() or listDone then return end
  listDone=true;self.loading=false;self.state="error";self:changed()
 end
 local function failMine()
  if not valid() or myDone then return end
  myDone=true;self.myState="error";self:changed()
 end
 local ok=pcall(function() self.cloud:GetRankList(Board.KEY,0,20,{
  ok=function(items)
   if not valid() or listDone then return end
   listDone=true;self.loading=false;self.state="ready";self.rows={}
   local ids={}
   for i,item in ipairs(items or {}) do
    local score=(item.iscore or {})[Board.KEY]
    if integer(item.userId) and integer(score) then
     self.rows[#self.rows+1]={rank=i,userId=item.userId,score=score,name="TapTap 玩家",me=item.userId==id}
     ids[#ids+1]=item.userId
    end
   end
   self:changed()
   if #ids==0 or type(self.nicknames)~="function" then return end
   -- Name lookup can fail independently; real ranks and scores remain usable.
   pcall(self.nicknames,{userIds=ids,onSuccess=function(names)
    if not valid() then return end
    local byId={}
    for _,info in ipairs(names or {}) do
     if type(info.nickname)=="string" and info.nickname~="" then
      byId[info.userId]=info.nickname:gsub("[%c]"," ")
     end
    end
    for _,row in ipairs(self.rows) do row.name=byId[row.userId] or row.name end
    self:changed()
   end,onError=function() end})
  end,error=failList,timeout=failList
 }) end)
 if not ok then failList() end
 ok=pcall(function() self.cloud:GetUserRank(id,Board.KEY,{
  ok=function(rank,score)
   if not valid() or myDone then return end
   myDone=true;self.rank=rank;self.myState="ready"
   if integer(score) then self.cloudBest=math.max(self.cloudBest,score) end
   self:changed()
  end,error=failMine,timeout=failMine
 }) end)
 if not ok then failMine() end
 if self.sync=="error" then self.retries=0;self:upload() end
 return true
end
function Board:update(dt)
 self.clock=self.clock+math.max(0,dt)
 self:account()
 if self.retryAt>0 and self.clock>=self.retryAt then self.retryAt=0;self:upload() end
end
return Board
