-- Pure Lua gameplay checks. Also reusable by the official Runtime harness.
local Run=require("Game.Run")
local Platforms=require("Game.PlatformStyle")
local Rules={}

local function advance(run,seconds)
 while seconds>0.000001 do
  local dt=math.min(seconds,1/120)
  run:update(dt); seconds=seconds-dt
 end
end
local function fresh(seed)
 local run=Run.new(seed or 732); run:reset(false); return run
end
local function copy(value,seen)
 if type(value)~="table" then return value end
 seen=seen or {}
 if seen[value] then return seen[value] end
 local result={}; seen[value]=result
 for k,v in pairs(value) do result[k]=copy(v,seen) end
 return setmetatable(result,getmetatable(value))
end
local function jump(run,hold)
 run:press("test"); advance(run,hold); run:release("test"); advance(run,1.35)
end

-- Search user-achievable timings against the real model, never snap to a leaf.
local function viableHold(run)
 local expected=run:neededHold()
 local best,bestError
 for delta=-8,8 do
  local hold=expected+delta*0.025
  if hold>=0 and hold<=Run.MAX_HOLD then
   local trial=copy(run)
   jump(trial,hold)
   if trial.steps==run.steps+1 and trial.phase=="ready" then
    local dx,dy=trial.hero.x-trial.current.x,trial.hero.y-trial.current.y
    local error=dx*dx+dy*dy
    if not bestError or error<bestError then best,bestError=hold,error end
   end
  end
 end
 return best
end

---@param check fun(condition:boolean,message:string)
function Rules.run(check)
 local run=fresh()
 check(run.phase=="ready" and run.score==0,"fresh run is ready with zero points")
 advance(run,30)
 check(run.phase=="ready","waiting on ordinary leaves cannot end a game")
 local hold=run:neededHold()
 jump(run,hold)
 check(run.steps==1 and run.score==2 and run.combo==1,"centre landing gives points and starts a combo")
 local held=run:press("finger1")
 check(held and not run:press("finger2"),"second finger cannot steal a held jump")
 check(not run:release("finger2"),"other finger cannot release the jump")
 run:pause(); run:resume()
 check(run.phase=="ready" and run.pointer==nil,"pause cancels charge without jumping on resume")

 run=fresh(); run.current.kind="stream"
 local offX,offY=run.hero.x-run.current.x,run.hero.y-run.current.y
 advance(run,.4)
 check(math.abs(run.current.x-run.current.baseX)>1,"water current moves a floating leaf")
 check(math.abs(run.hero.x-run.current.x-offX)<1e-7 and math.abs(run.hero.y-run.current.y-offY)<1e-7,
  "frog rides the floating leaf without sliding or teleporting")
 run:pause()
 local px,py,t=run.current.x,run.current.y,run.clock
 advance(run,10);run:resume();advance(run,1/120)
 check(math.abs(run.current.x-px)<.25 and math.abs(run.current.y-py)<.1 and run.clock-t<.01,
  "paused current freezes and resumes without a phase jump")

 run=fresh();run.current.kind="sink"
 advance(run,1);run:press("finger1");advance(run,.3);run:pause()
 local sinkTime=run.current.standTime
 advance(run,10)
 check(run.current.standTime==sinkTime,"pause freezes the sinking countdown")
 run:resume();advance(run,Run.SINK_SECONDS-sinkTime+.01)
 check(run.phase=="fall" and run.pointer==nil,"sinking leaf causes a water fall and clears held input")
 advance(run,1)
 local serial=run.serial
 check(run.phase=="over","only after falling does the round end")
 advance(run,20)
 check(run.phase=="over" and run.serial==serial,"water fall waits for restart instead of auto restarting")
 check(not run:release("finger1"),"old held pointer cannot launch after a sink")
 run:reset(false)
 check(run.phase=="ready" and run.current.standTime==0,"restart resets the sinking state")

 run=fresh();run.current.kind="sink";run.current.standTime=Run.SINK_SECONDS-.25
 run:press("escape");advance(run,.1);run:release("escape")
 advance(run,.2)
 check(run.phase=="flight","already airborne frog is not sunk by its old leaf")
 check(run.current.standTime==Run.SINK_SECONDS,"abandoned sinking leaf continues to submerge")

 local normal=fresh();local spring=fresh();spring.current.kind="spring"
 normal:press("n");spring:press("s");advance(normal,.4);advance(spring,.4)
 normal:release("n");spring:release("s")
 local function distance(r)
  return math.sqrt((r.flight.tx-r.flight.x)^2+(r.flight.ty-r.flight.y)^2)
 end
 check(math.abs(distance(spring)/distance(normal)-Run.SPRING_POWER)<1e-7,
  "spring leaf boosts the same held input by the advertised multiplier")
 check(spring.flight.height>normal.flight.height,"spring jump also has a higher visible arc")
 check(spring.flight.startDip>0,"compressed spring height is retained at takeoff")
 advance(spring,.1);spring:pause()
 local fx,fy=spring.hero.x,spring.hero.y
 advance(spring,3)
 check(spring.hero.x==fx and spring.hero.y==fy,"pause freezes an airborne spring jump")

 -- Collision must follow the moving leaf, not its original/base coordinates.
 run=fresh();run.target.kind="stream";advance(run,.6)
 run.hero.x,run.hero.y=run.target.x,run.target.y;run.phase="flight"
 run.flight={x=0,y=0,tx=run.hero.x,ty=run.hero.y,duration=.6,height=100,startDip=0}
 run:land()
 check(run.phase=="land" and run.score==2,"moving leaf's current centre is a perfect landing")
 run=fresh();run.hero.x,run.hero.y=run.target.x+run.target.r*.7,run.target.y
 run.phase="flight";run.flight={x=0,y=0,tx=run.hero.x,ty=run.hero.y,duration=.6,height=100,startDip=0}
 run:land()
 check(run.score==1 and run.combo==0,"safe edge landing scores without granting a centre combo")
 run=fresh();run:press("short");run:release("short");advance(run,2)
 check(run.phase=="over" and run.score==0,"short jump falls without granting points")
 run=fresh();run:press("long");advance(run,8)
 check(run.hold==Run.MAX_HOLD,"long holds are capped")
 run:release("long");advance(run,2)
 check(run.phase=="over","overshooting falls in the water")

 -- Varying platform sizes must change real support, not just the drawn scale.
 local function landingAt(kind,r,dx,dy)
  local sample=fresh(19)
  sample.target.kind,sample.target.r=kind,r
  sample.hero.x,sample.hero.y=sample.target.x+dx,sample.target.y+dy
  sample.phase="flight"
  sample.flight={x=0,y=0,tx=sample.hero.x,ty=sample.hero.y,duration=.6,height=100,startDip=0}
  sample:land()
  return sample.phase=="land"
 end
 check(landingAt("leaf",82,55,0),"large top supports a 55-unit lateral offset")
 check(not landingAt("leaf",50,55,0),"same offset correctly misses a small top")
 for _,kind in ipairs({"leaf","stream","sink","spring"}) do
  for _,radius in ipairs({50,84}) do
   local art=Platforms.get(kind)
   local topDepth=radius*art.ry/art.rx/Platforms.PROJECTION
   check(landingAt(kind,radius,0,topDepth*.84),kind.." supports front/back inside its flat top")
   check(landingAt(kind,radius,0,radius*.9),kind.." visible front face supports the frog instead of a hidden inner oval")
   check(not landingAt(kind,radius,radius*1.3,0),kind.." blank water outside the cutout is not landable")
  end
 end
 check(not landingAt("sink",84,0,(770-Platforms.get("sink").cy)*(84/Platforms.get("sink").rx)/Platforms.PROJECTION),
  "transparent space between mouse ears is not an invisible rectangular platform")
 local sizes={leaf={},stream={},sink={},spring={}}
 local a,b=fresh(913),fresh(913)
 local previousA,previousB=a.target,b.target
 local deterministic,bounded=true,true
 for i=4,120 do
  a.steps,b.steps=i,i
  local nextA,nextB=a:makeNext(previousA,i),b:makeNext(previousB,i)
  sizes[nextA.kind][nextA.r]=true
  deterministic=deterministic and nextA.r==nextB.r and nextA.x==nextB.x and nextA.y==nextB.y
  bounded=bounded and nextA.r>=50 and nextA.r<=84
  previousA,previousB=nextA,nextB
 end
 check(deterministic,"size mixing preserves seeded reproducibility")
 check(bounded,"all random platform radii remain playable bounds")
 for kind,seen in pairs(sizes) do
  local count=0;for _ in pairs(seen) do count=count+1 end
  check(count>=3,kind.." course actually contains multiple sizes")
 end
 check(fresh().target.r>=74,"opening landing is generous")

 -- Several routes cover all three mechanics and repeated generation cycles.
 local allKinds={}
 for _,seed in ipairs({7,732,991}) do
  run=fresh(seed)
  for step=1,40 do
   local timing=viableHold(run)
   check(timing~=nil,"route "..seed..", jump "..step.." has a reachable landing")
   if not timing then break end
   local previous=run.score
   jump(run,timing)
   allKinds[run.current.kind]=true
   check(run.phase=="ready" and run.steps==step and run.score>previous,
    "route "..seed..", jump "..step.." continues and awards points")
   check(#run.platforms<=7,"platform history remains bounded")
  end
  check(run.phase=="ready" and run.steps==40,"there is no level-end settlement after 40 jumps")
  local best=run.best;run:reset(false)
  check(run.best==best and run.score==0,"restart preserves the best score and clears current points")
 end
 check(allKinds.stream and allKinds.sink and allKinds.spring,"routes include all three obstacle mechanics")
end

return Rules
