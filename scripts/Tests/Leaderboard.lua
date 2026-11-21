local Board=require("Game.Leaderboard")
local Tests={}
function Tests.run(check)
 -- Unit-test doubles only; runtime always uses the official global clientCloud.
 local api={userId=7,writes={},gets={}}
 function api:Get(key,events) self.gets[#self.gets+1]=events end
 function api:SetInt(key,value,events) self.writes[#self.writes+1]={key=key,value=value,events=events} end
 function api:GetRankList(key,start,count,events) self.list=events;self.count=count end
 function api:GetUserRank(id,key,events) self.mine=events end
 local names
 local b=Board.new(api,function(opts) names=opts end)
 check(not b:record(90,0) and #api.gets==0,"offline practice cannot be imported into a later TapTap login")
 check(b:record(12,7) and #api.gets==1 and #api.writes==0,"automatic submission first reads the account's cloud best")
 api.gets[1].ok({},{[Board.KEY]=30})
 check(#api.writes==0 and b.cloudBest==30,"a lower run cannot replace an existing cloud record")
 check(b:record(40,7),"a new best schedules synchronization")
 api.gets[2].error(-1,"offline")
 check(#api.writes==0 and b.sync=="error","failed cloud reads never overwrite data with a guessed default")
 b:update(16)
 check(#api.gets==3,"failed automatic upload retries after backoff")
 api.gets[3].ok({},{[Board.KEY]=30})
 check(api.writes[1].value==40,"retry submits the original earned score")
 b:record(50,7)
 api.writes[1].events.ok()
 check(#api.gets==4,"a newer earned score during upload is retained")
 api.gets[4].ok({},{[Board.KEY]=40})
 api.writes[2].events.ok()
 check(b.cloudBest==50 and b.sync=="saved","highest pending earned score is acknowledged")
 check(not b:record(1.3,7) and not b:record(2147483648,7),"fractional and overflow scores are rejected before SetInt")
 b:load()
 check(api.count==20 and b.loading,"only the top twenty real records are requested")
 api.list.ok({{userId=9,iscore={[Board.KEY]=66}},{userId=7,iscore={[Board.KEY]=50}}})
 api.mine.ok(2,50)
 names.onSuccess({{userId=7,nickname="测试奶蛙"},{userId=9,nickname="大奶蛙"}})
 check(b.rows[1].name=="大奶蛙" and b.rows[2].me and b.rank==2,"official nickname results attach to their user IDs, not list position")
 check(not b:load(),"refresh taps are throttled without duplicate requests")
 b:update(6);b:load();api.list.timeout();api.mine.error(-1,"offline")
 check(b.state=="error" and b.myState=="error" and not b.loading,"both list and personal-rank errors stop loading")
 local before=b.rows[1].name
 api.list.ok({{userId=19,iscore={[Board.KEY]=80}}})
 check(b.rows[1].name==before,"late callbacks after timeout cannot overwrite a finished request")
 b:record(70,7)
 local stale=api.gets[#api.gets]
 api.userId=8;b:update(.1)
 local written=#api.writes
 stale.ok({},{[Board.KEY]=0})
 check(#api.writes==written and b.wanted==0 and b.userId==8,"account switching cancels old callbacks and pending scores")
 check(not b:record(80,7),"a run started by another account cannot be submitted")
 api.userId=0;b:load()
 check(b.state=="offline" and #b.rows==0,"signed-out leaderboard shows offline state without fabricated ranks")
 local missing=Board.new(nil,nil)
 check(not missing:load() and not missing:record(20,0),"native standalone without cloud identity remains playable")
end
return Tests
