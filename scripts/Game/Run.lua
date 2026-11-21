-- Deterministic single-player jump rules. No engine calls in this module.
local Platforms=require("Game.PlatformStyle")
---@class NaiwaPlatform
---@field x number
---@field y number
---@field r number
---@field index integer
---@field kind string
---@field baseX number
---@field baseY number
---@field driftPhase number
---@field standTime number

---@class NaiwaRun
---@field phase string
---@field resumePhase string
---@field pointer string|nil
---@field platforms NaiwaPlatform[]
---@field current NaiwaPlatform
---@field target NaiwaPlatform
---@field events string[]
---@field ripples {x:number,y:number,age:number,success:boolean}[]
---@field hero {x:number,y:number}
---@field flight {x:number,y:number,tx:number,ty:number,duration:number,height:number,startDip:number}
---@field best integer
---@field sound boolean
---@field tutorialSeen boolean
---@field skinId string
---@field rewardGranted boolean
---@field clock number
---@field serial integer
---@field seed integer
---@field score integer
---@field steps integer
---@field combo integer
---@field maxCombo integer
---@field hold number
---@field phaseTime number
---@field hopHeight number
---@field cameraX number
---@field cameraY number
---@field notice string
---@field noticeTime number
---@field reason string
local Run = {}
Run.__index = Run
Run.MAX_HOLD = 1.35
Run.MIN_JUMP = 65
Run.POWER = 270
Run.SINK_SECONDS = 3.6
Run.SPRING_POWER = 1.25

-- Introduce one new obstacle at a time before combining them.
---@type string[]
local COURSE = {"leaf","leaf","stream","leaf","sink","leaf","spring","leaf","stream","sink","leaf","spring"}

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function length(x, y) return math.sqrt(x*x + y*y) end

---@return NaiwaRun
function Run.new(seed)
    ---@type NaiwaRun
    local self = setmetatable({}, Run)
    self.seed = seed or 6247
    self.best = 0
    self.sound = true
    self.tutorialSeen = false
    self.skinId = "original"
    self.clock = 0.0
    self.serial = 0
    self:reset(true)
    return self
end

function Run:random()
    self.seed = (self.seed * 48271) % 2147483647
    return self.seed / 2147483647
end

---@param previous NaiwaPlatform
---@param index integer
---@return NaiwaPlatform
function Run:makeNext(previous, index)
    local sign = self:random() > 0.5 and 1 or -1
    if previous.baseX > 165 then sign = -1 end
    if previous.baseX < -165 then sign = 1 end
    local distance = index == 2 and 220 or (190 + self:random()*88 + math.min(self.steps, 30)*0.7)
    local dx = sign * distance * (0.57 + self:random()*0.16)
    local dy = -math.sqrt(distance*distance - dx*dx)
    local x,y=previous.baseX+dx,previous.baseY+dy
    local kind=COURSE[(index-1)%#COURSE+1] or "leaf"
    local radius=Platforms.radius(kind,index,self.steps,self:random())
    return { x=x, y=y, baseX=x, baseY=y, standTime=0.0, driftPhase=index*1.71,
        r=radius, index=index, kind=kind }
end

function Run:reset(menu)
    self.serial = self.serial + 1
    self.phase = menu and "menu" or "ready"
    self.score, self.steps, self.combo, self.maxCombo = 0, 0, 0, 0
    self.hold, self.phaseTime, self.hopHeight = 0.0, 0.0, 0.0
    self.pointer = nil
    self.rewardGranted = false
    self.notice, self.noticeTime = "", 0.0
    self.reason = ""
    self.hero = {x=0.0, y=0.0}
    self.platforms = {{x=0, y=0, baseX=0, baseY=0, driftPhase=0, standTime=0.0, r=76, index=1, kind="leaf"}}
    self.current = self.platforms[1]
    self.target = self:makeNext(self.current, 2)
    table.insert(self.platforms, self.target)
    table.insert(self.platforms, self:makeNext(self.target, 3))
    self:movePlatforms()
    self.cameraX = (self.hero.x+self.target.x)*0.5
    self.cameraY = self.hero.y
    self.events = {}
    self.ripples = {}
end

function Run:emit(kind) self.events[#self.events+1] = kind end
function Run:powerScale() return self.current.kind=="spring" and Run.SPRING_POWER or 1 end
function Run:distance() return (Run.MIN_JUMP + math.min(self.hold, Run.MAX_HOLD)*Run.POWER)*self:powerScale() end
function Run:neededHold()
    return (length(self.target.x-self.hero.x, self.target.y-self.hero.y)/self:powerScale()-Run.MIN_JUMP)/Run.POWER
end
function Run:sinkProgress(platform)
    return platform.kind=="sink" and math.min(1,platform.standTime/Run.SINK_SECONDS) or 0
end
function Run:surfaceDip(platform)
    if platform.kind=="sink" then return self:sinkProgress(platform)*16 end
    if platform==self.current and platform.kind=="spring" and self.phase=="charge" then
        return math.min(1,self.hold/Run.MAX_HOLD)*7
    end
    return 0
end

function Run:movePlatforms()
    local carry=self.phase=="ready" or self.phase=="charge" or self.phase=="land"
    for _,p in ipairs(self.platforms) do
        if p.kind=="stream" then
            local x=p.baseX+math.sin(self.clock*0.95+p.driftPhase)*25
            local y=p.baseY+math.cos(self.clock*0.95+p.driftPhase)*7
            if p==self.current and carry then
                self.hero.x,self.hero.y=self.hero.x+x-p.x,self.hero.y+y-p.y
            end
            p.x,p.y=x,y
        end
    end
end
function Run:projection()
    local dx, dy = self.target.x-self.hero.x, self.target.y-self.hero.y
    local len = length(dx,dy)
    local d = self:distance()
    return self.hero.x+dx/len*d, self.hero.y+dy/len*d
end

function Run:press(id)
    if self.phase ~= "ready" or self.pointer ~= nil then return false end
    self.pointer, self.hold, self.phase = id, 0.0, "charge"
    self:emit("charge")
    return true
end

function Run:cancel()
    self.pointer, self.hold = nil, 0.0
    if self.phase == "charge" then self.phase = "ready" end
end

function Run:release(id)
    if self.phase ~= "charge" or self.pointer ~= id then return false end
    local x, y = self:projection()
    self.flight = {x=self.hero.x, y=self.hero.y, tx=x, ty=y,
        duration=0.52+self:distance()/1600, height=94+self.hold*42+(self.current.kind=="spring" and 32 or 0),
        startDip=self:surfaceDip(self.current)}
    self.phase, self.phaseTime, self.pointer = "flight", 0.0, nil
    self:emit(self.current.kind=="spring" and "spring" or "jump")
    return true
end

function Run:pause()
    if self.phase=="menu" or self.phase=="over" or self.phase=="paused" or self.phase=="tutorial" or self.phase=="claw" or self.phase=="wardrobe" or self.phase=="leaderboard" then return end
    self:cancel()
    self.resumePhase, self.phase = self.phase, "paused"
end
function Run:resume()
    if self.phase=="paused" then self.phase=self.resumePhase or "ready" end
end

function Run:fall(reason)
    if self.phase=="fall" or self.phase=="over" then return end
    self.pointer,self.hold,self.hopHeight=nil,0.0,0.0
    self.phase,self.phaseTime="fall",0.0
    self.reason=reason
    self.ripples[#self.ripples+1]={x=self.hero.x,y=self.hero.y,age=0.0,success=false}
    self:emit("splash")
end

function Run:land()
    local dx, dy = self.hero.x-self.target.x, self.hero.y-self.target.y
    local errorDistance = length(dx,dy/Platforms.depth(self.target.kind))
    -- Support follows the visible animal's actual alpha silhouette, including
    -- face and ears. No smaller invisible oval hidden inside the picture.
    if Platforms.contains(self.target,dx,dy) then
        local perfect = errorDistance <= self.target.r*0.27
        self.combo = perfect and self.combo+1 or 0
        self.maxCombo = math.max(self.maxCombo,self.combo)
        local gain = perfect and (1+math.min(self.combo,5)) or 1
        self.score, self.steps = self.score+gain, self.steps+1
        self.best = math.max(self.best,self.score)
        self.current = self.target
        self.current.standTime=0.0
        self.target = self.platforms[#self.platforms]
        self.platforms[#self.platforms+1] = self:makeNext(self.target,self.target.index+1)
        if #self.platforms > 7 then table.remove(self.platforms,1) end
        self.phase, self.phaseTime = "land",0.0
        self.notice = perfect and ("正中平台！ +"..gain) or "+1  稳稳落地"
        if self.combo>=2 then self.notice = self.combo.." 连中！ +"..gain end
        self.noticeTime = 1.1
        self.ripples[#self.ripples+1] = {x=self.hero.x,y=self.hero.y,age=0.0,success=true}
        self:emit(perfect and "perfect" or "land")
        self:emit("save")
    else
        local travelled = length(self.hero.x-self.flight.x,self.hero.y-self.flight.y)
        local needed = length(self.target.x-self.flight.x,self.target.y-self.flight.y)
        self:fall(travelled < needed and "差一点，下次多蓄一点力" or "跳远啦，下次早点松手")
    end
end

function Run:update(dt)
    dt=clamp(dt,0,0.05)
    if self.phase=="paused" or self.phase=="tutorial" or self.phase=="claw" or self.phase=="wardrobe" or self.phase=="leaderboard" then return end
    self.clock=self.clock+dt
    self:movePlatforms()
    self.noticeTime=math.max(0,self.noticeTime-dt)
    for i=#self.ripples,1,-1 do
        local r=self.ripples[i]; r.age=r.age+dt
        if r.age>1.1 then table.remove(self.ripples,i) end
    end
    local supported=self.phase=="ready" or self.phase=="charge" or self.phase=="land"
    for _,p in ipairs(self.platforms) do
        if p.kind=="sink" and (p.standTime>0 or (p==self.current and supported)) then
            p.standTime=math.min(Run.SINK_SECONDS,p.standTime+dt)
        end
    end
    if supported and self.current.kind=="sink" and self.current.standTime>=Run.SINK_SECONDS then
        self:fall("奶鼠浮台沉下去啦，下次早点起跳")
        return
    end
    if self.phase=="charge" then
        self.hold=math.min(Run.MAX_HOLD,self.hold+dt)
    elseif self.phase=="flight" then
        self.phaseTime=self.phaseTime+dt
        local t=math.min(1,self.phaseTime/self.flight.duration)
        self.hero.x=self.flight.x+(self.flight.tx-self.flight.x)*t
        self.hero.y=self.flight.y+(self.flight.ty-self.flight.y)*t
        self.hopHeight=4*t*(1-t)*self.flight.height
        if t>=1 then self.hopHeight=0; self:land() end
    elseif self.phase=="land" then
        self.phaseTime=self.phaseTime+dt
        local a=1-math.exp(-dt*9)
        self.cameraX=self.cameraX+((self.hero.x+self.target.x)*0.5-self.cameraX)*a
        self.cameraY=self.cameraY+(self.hero.y-self.cameraY)*a
        if self.phaseTime>=0.46 then
            self.cameraX=(self.hero.x+self.target.x)*0.5
            self.cameraY=self.hero.y
            self.phase,self.hold="ready",0.0
        end
    elseif self.phase=="fall" then
        self.phaseTime=self.phaseTime+dt
        if self.phaseTime>=0.85 then
            self.phase="over"
            if not self.rewardGranted then self.rewardGranted=true; self:emit("fallReward") end
            self:emit("save")
        end
    end
end

return Run
