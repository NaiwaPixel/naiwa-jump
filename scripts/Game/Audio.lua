local Soundscape={}
---@type Scene|nil
local scene_
---@type SoundSource|nil
local source_
---@type SoundSource|nil
local music_
---@type table<string, Sound>
local sounds_={}
local enabled_=true
local quiet_=false
function Soundscape.init()
    scene_=Scene()
    source_=scene_:CreateComponent("SoundSource")
    music_=scene_:CreateComponent("SoundSource")
    music_:SetSoundType(SOUND_MUSIC)
    for _,name in ipairs({"jump","land","perfect","splash","pond","claw","open","suspense","reveal","peel","rise","boxland"}) do
        sounds_[name]=cache:GetResource("Sound","audio/"..name..".wav")
    end
    if sounds_.pond then sounds_.pond.looped=true end
end
function Soundscape.enable(enabled)
    enabled_=enabled
    audio:SetMasterGain(SOUND_EFFECT,enabled and 0.5 or 0)
    audio:SetMasterGain(SOUND_MUSIC,enabled and (quiet_ and .045 or .16) or 0)
end
function Soundscape.presentation(stage)
    local quiet=stage=="opening" or stage=="unfolding" or stage=="rising" or stage=="silhouette" or stage=="burst"
    if quiet~=quiet_ then quiet_=quiet;Soundscape.enable(enabled_) end
end
function Soundscape.begin()
    if sounds_.pond and music_ and not music_.playing then music_:Play(sounds_.pond,0,1) end
end
function Soundscape.play(kind)
    if kind=="spring" then kind="perfect" end
    if sounds_[kind] and source_ then source_:Play(sounds_[kind],0,0.7) end
end
function Soundscape.stop()
    if source_ then source_:Stop() end
    if music_ then music_:Stop() end
    scene_,source_,music_=nil,nil,nil
end
return Soundscape
