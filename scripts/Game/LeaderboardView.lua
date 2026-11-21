local UI=require("urhox-libs/UI")
local Art=require("Game.UIArt")
local View={}
local function label(text,size,color,extra)
 local p={text=text,fontSize=size,fontColor=color or Art.cream,textAlign="center",whiteSpace="normal",pointerEvents="none"}
 for k,v in pairs(extra or {}) do p[k]=v end
 return UI.Label(p)
end
function View.build(board,actions)
 local rows={}
 if board.state=="offline" then
  rows[#rows+1]=label("在 TapTap 中登录后查看排行榜",19)
  rows[#rows+1]=label("当前可以继续单机游玩",15,Art.muted)
 elseif board.state=="loading" then rows[#rows+1]=label("正在读取排行榜……",18)
 elseif board.state=="error" then rows[#rows+1]=label("暂时连不上排行榜，请稍后刷新",17)
 elseif #board.rows==0 then rows[#rows+1]=label("还没有成绩，来跳出第一条纪录！",18)
 else
  for _,r in ipairs(board.rows) do
   rows[#rows+1]=UI.Panel {width="100%",minHeight=54,padding=9,gap=8,flexDirection="row",alignItems="center",
    backgroundColor=r.me and {69,94,53,255} or {33,50,37,255},children={
     label(tostring(r.rank),20,r.rank<=3 and Art.gold or Art.muted,{width=30}),
     label(r.name..(r.me and " · 我" or ""),16,Art.cream,{flexGrow=1,flexBasis=0,textAlign="left"}),
     label(tostring(r.score),20,Art.gold,{minWidth=45})}}
  end
 end
 local mine="登录 TapTap 后参与排名"
 if board.userId>0 then
  mine=board.myState=="loading" and "正在读取我的排名……" or
   (board.myState=="error" and "我的排名暂时无法读取" or
   (board.rank and "我的排名  "..tostring(board.rank).."  ·  最佳 "..board.cloudBest.." 分" or "我还未上榜"))
 end
 local sync=board.sync=="loading" and "正在同步本局成绩……" or
  (board.sync=="error" and "成绩暂未同步，联网后会重试" or "落水后自动同步最高分 · 显示 TapTap 昵称")
 return UI.Panel {width="100%",height="100%",padding=18,gap=12,backgroundColor=Art.surface,children={
  label("奶蛙排行榜",29,Art.gold,{fontFamily="pixel"}),label("最高分 · 前 20 名",15,Art.muted),
  UI.Panel {width="100%",padding=12,backgroundColor={66,84,48,255},children={label(mine,17)}},
  UI.ScrollView {width="100%",flexGrow=1,flexBasis=0,scrollY=true,children={UI.Panel {width="100%",gap=6,children=rows}}},
  label(sync,13,Art.muted),
  Art.button("刷新排行",actions.refreshBoard,true,board.loading),
  Art.button("返回",actions.closeBoard,true)}}
end
return View
