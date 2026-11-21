-- Explicit allowlist: the nine original costumes and new Naiwa-only designs.
-- No costumes from third-party characters are imported from the other game.
---@alias NaiwaSkin {id:string,name:string,detail:string,tier:integer}
local Skins={}
Skins.tiers={
 {name="日常",weight=40,color={127,178,137,255}},
 {name="稀有",weight=32,color={101,169,222,255}},
 {name="史诗",weight=20,color={188,139,222,255}},
 {name="传说",weight=8,color={249,193,78,255}}
}
---@type NaiwaSkin[]
Skins.list={
 {id="original",name="经典奶蛙",detail="圆肚子，老朋友。初始拥有。",tier=0},
 {id="milkman",name="奶瓶街送奶员",detail="白蓝条纹衫，奶滴小帽。",tier=1},
 {id="safety",name="工厂安全员",detail="安全帽戴好，反光背心穿好。",tier=1},
 {id="gardener",name="荷塘园丁",detail="草帽和绿背带，照顾每一片荷叶。",tier=1},
 {id="baker",name="奶糖烘焙师",detail="奶油厨师帽，面包口袋小围裙。",tier=1},
 {id="sailor",name="晴日水手",detail="敞开小外套，清爽水手领。",tier=1},
 {id="lotusrain",name="荷叶雨衣",detail="一身荷叶，踩着红雨靴出门。",tier=2},
 {id="conductor",name="运输站列车员",detail="金边帽和小挎包，下一站是荷塘。",tier=2},
 {id="pajama",name="星星睡衣",detail="穿着星月睡衣，也能去冒险。",tier=2},
 {id="honey",name="蜂蜜信使",detail="蜜蜂小背心，甜甜的挎包。",tier=2},
 {id="mushroom",name="蘑菇旅人",detail="红蘑菇兜帽，苔绿短斗篷。",tier=2},
 {id="winter",name="冬日围炉",detail="软耳罩和围巾，把暖意带在身上。",tier=2},
 {id="bathrobe",name="泡泡下班啦",detail="浴袍一裹，头顶还留着泡泡。",tier=2},
 {id="magician",name="笑场魔术师",detail="迷你礼帽和燕尾服，笑场也优雅。",tier=3},
 {id="knight",name="瓶盖骑士",detail="瓶盖头盔，纸板铠甲，小小勇气。",tier=3},
 {id="newyear",name="新春唐装",detail="红绸金扣，开开心心迎新春。",tier=3},
 {id="firefly",name="萤火灯使",detail="深青斗篷，腰间挂着一盏暖灯。",tier=3},
 {id="box",name="纸箱潜行",detail="纸箱穿身上，假装没有被发现。",tier=3},
 {id="astronaut",name="宇航蛙",detail="鱼缸头盔和白色宇航服。",tier=4},
 {id="stargazer",name="星河观测员",detail="星星软帽，披一片紫色夜空。",tier=4},
 {id="lotuskeeper",name="莲心守护者",detail="莲花冠与花瓣披肩，守着一池温柔。",tier=4},
 {id="eggknight",name="煎蛋大侠",detail="煎蛋当披风，圆肚子也很威风。",tier=4},
 {id="trash",name="垃圾桶隐士",detail="桶盖一扣，今天谁也别想找到我。",tier=2},
 {id="socks",name="臭袜战神",detail="旧袜当围巾，路过都得屏住呼吸。",tier=3},
 {id="saltfish",name="咸鱼上班",detail="领带打好了，鱼还没醒。",tier=3},
 {id="toilet",name="马桶大王",detail="圈是披肩，皮搋子是王冠。",tier=4}
}
---@type table<string,NaiwaSkin>
Skins.byId={}
for _,skin in ipairs(Skins.list) do Skins.byId[skin.id]=skin end
---@return NaiwaSkin
function Skins.get(id) return Skins.byId[id] or Skins.list[1] end
function Skins.tierInfo(skin)
 return Skins.tiers[skin.tier] or {name="初始",weight=0,color={208,192,140,255}}
end
return Skins
