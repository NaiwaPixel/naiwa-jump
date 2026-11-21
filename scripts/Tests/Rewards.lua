local Run=require("Game.Run")
local Collection=require("Game.Collection")
local Blindbox=require("Game.Blindbox")
local Rewards=require("Game.Rewards")
local Skins=require("Game.Skins")
local Tests={}
local function advance(model,seconds)
 for _=1,math.ceil(seconds*120) do model:update(1/120) end
end
function Tests.run(check)
 local c=Collection.new(nil,871)
 check(c.tickets==0 and c:count()==1 and c.selected=="original","new players have only the default costume and no free unearned tickets")
 check(c:reserve()==nil and not c:equip("astronaut"),"no negative ticket draw or locked costume equip")
 c:awardFall()
 local first=c:reserve()
 check(first~=nil and c.tickets==0 and rawget(c.owned,first or "")==true,"one fall buys exactly one owned costume")
 check(c:reserve()==nil,"double clicking cannot reserve two rewards")
 local restored=Collection.new(c:export(),999)
 check(restored.pending==first and restored.tickets==0 and restored.draws==1,"restarting mid-animation preserves the SAME reserved result and debit")
 restored:acknowledge(true)
 check(restored.pending==nil and restored.selected==first,"reveal can equip the saved costume")
 check(not restored:acknowledge(true),"repeated reward confirmation is idempotent")
 c=Collection.new({owned={gojo=true,unknown=true,original=false},selected="gojo",tickets=-15,pending="unknown",seed=0})
 check(c:count()==1 and c.selected=="original" and c.tickets==0 and not c.pending,"legacy/unknown IDs and bad save values cannot enter the original-only collection")
 local names={}
 for _,skin in ipairs(Skins.list) do
  check(not names[skin.id],"unique costume ID: "..skin.id); names[skin.id]=true
 end
 for _,seed in ipairs({1,77,921,867543}) do
  c=Collection.new(nil,seed)
  local seen={}
  for i=1,#Skins.list-1 do
   c:awardFall(); local id=c:reserve()
   check(id~=nil and not seen[id] and id~="original","collection draw is new, nondefault, seed "..seed.." / "..i)
   seen[id]=true; c:acknowledge(false)
   check(c.tickets==0 and c.draws==i,"one ticket debit per draw "..i)
  end
  c:awardFall()
  check(c:count()==#Skins.list and not c:canDraw() and c:reserve()==nil and c.tickets==1,"full collection stops drawing without consuming tickets")
 end
 c=Collection.new(nil,9)
 local odds=c:odds()
 check(odds[1]==.4 and odds[2]==.32 and odds[3]==.2 and odds[4]==.08,"initial rarity weights match disclosed probabilities")
 for _,skin in ipairs(Skins.list) do if skin.tier==1 then c.owned[skin.id]=true end end
 odds=c:odds()
 check(odds[1]==0 and math.abs(odds[2]+odds[3]+odds[4]-1)<1e-8,"collected tier removed and remaining rarity weights normalized")
 local b=Blindbox.new()
 check(not b:open() and not b:skip(),"cannot reveal a reward before a grab")
 b:update(.05); check(b.x>.15 and b.x<.85,"claw travels across reachable box slots")
 check(b:grab("milkman",1) and not b:grab("astronaut",4),"a second press cannot replace the reserved skin")
 advance(b,4)
 check(b.stage=="sealed" and b.skinId=="milkman","grab lifts and delivers a CLOSED box")
 advance(b,10); check(b.stage=="sealed","closed box waits for the player's open action")
 check(b:open() and not b:open(),"opening cannot be restarted by double click")
 advance(b,.85)
 check(b.stage=="unfolding" and not b:showsCostume() and not b:showsSilhouette(),"seal peels before flaps unfold; contents stay hidden")
 advance(b,.65)
 check(b.stage=="rising" and b:showsSilhouette() and not b:showsCostume(),"figure rises as black alpha only")
 check(not b:skip(),"rising prize cannot be skipped")
 advance(b,.95)
 check(b.stage=="silhouette","box opening leads to a black silhouette before any reveal")
 advance(b,.7); check(b.stage=="silhouette","silhouette has a readable anticipation hold")
 check(not b:skip(),"skip cannot bypass the required silhouette reveal")
 advance(b,.35); check(b.stage=="burst" and b:showsCostume(),"special effect follows a full one-second silhouette hold")
 advance(b,.8); check(b.stage=="reveal","full costume revealed only after burst")
 advance(b,10); check(b.stage=="reveal","result stays visible until the player confirms")
 b=Blindbox.new("winter"); check(b.stage=="sealed","crash recovery restores the sealed presentation without another draw")
 b=Blindbox.new(); b:grab("baker",1); b:skip()
 check(b.stage=="sealed","skip transport still requires opening the box")

 local run=Run.new(31); run:reset(false)
 run:fall("test"); run:fall("duplicate input"); advance(run,4)
 local awards=0
 for _,event in ipairs(run.events) do if event=="fallReward" then awards=awards+1 end end
 check(run.phase=="over" and awards==1,"one water death emits ONE reward even with duplicate callbacks")
 advance(run,15)
 local again=0
 for _,event in ipairs(run.events) do if event=="fallReward" then again=again+1 end end
 check(again==1 and run.phase=="over","waiting on game over cannot farm tickets or auto restart")
 run:reset(false); run.current.kind="sink"; advance(run,1)
 run.phase="tutorial"; local before=run.current.standTime; local clock=run.clock
 advance(run,10); run:pause()
 check(run.current.standTime==before and run.clock==clock and run.phase=="tutorial","tutorial freezes sinking and cannot be overwritten by focus-pause")
 run.phase="claw"; advance(run,5); check(run.clock==clock,"claw screen cannot run pond timers")
 run.phase="wardrobe"; advance(run,5); check(run.clock==clock,"wardrobe cannot run pond timers")
 run.phase="leaderboard";advance(run,5);run:pause()
 check(run.clock==clock and run.phase=="leaderboard","online leaderboard and focus loss do not advance or unfreeze gameplay")

 local saves=0
 run=Run.new(32)
 local ok=true
 local r=Rewards.new(run,nil,function() saves=saves+1; return ok end)
 r:awardFall(); r:openClaw()
 ok=false
 check(not r:grab() and r.collection.tickets==1 and not r.collection.pending and r.box.stage=="ready","failed save rolls back ticket/reward transaction before animation")
 ok=true
 check(r:grab() and r.collection.tickets==0 and r.collection.pending~=nil,"retry safely commits exactly one draw")
 check(not r:close() and not r:finish(true),"cannot dismiss an unopened reward or equip it early")
 r.box:skip(); r.box:open()
 r.suspended=true;advance(r,8)
 check(r.box.stage=="opening" and r.box.t==0,"focus loss freezes unboxing instead of skipping its reveal")
 r.suspended=false;advance(r,5)
 local id=r.collection.pending
 ok=false
 check(not r:finish(true) and r.collection.pending==id and r.collection.selected=="original","failed claim save keeps the existing reward available")
 ok=true
 check(r:finish(true) and r.collection.selected==id and run.skinId==id,"successful claim equips cosmetic on the actual player")
 check(not r:finish(true) and r.collection.draws==1,"repeat claim cannot grant another ticket or draw")
 r:close(); r:wardrobe(); r:select("original"); r:equip(); r:close()
 check(run.skinId=="original" and run.phase=="menu","wardrobe returns to exact previous screen with selected art")
 check(saves>0,"progress changes go through persistence")
end
return Tests
