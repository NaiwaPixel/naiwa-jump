local Storage={}
local SAVE_FILE="naiwa-pond-adventure-v1.json"
local function read(path)
    if not fileSystem:FileExists(path) then return nil end
    local file=File(path,FILE_READ)
    if not file or not file:IsOpen() then return nil end
    local ok,data=pcall(cjson.decode,file:ReadString()); file:Close()
    if not ok or type(data)~="table" then return nil end
    return data
end
function Storage.load()
    local a,b=read(SAVE_FILE),read(SAVE_FILE..".backup")
    local data=a or b or {}
    if a and b and (tonumber(b.revision) or 0)>(tonumber(a.revision) or 0) then data=b end
    Storage.revision=math.max(0,tonumber(data.revision) or 0)
    return {best=type(data.best)=="number" and math.max(0,math.floor(data.best)) or 0,
        sound=data.sound~=false,tutorialSeen=data.tutorialSeen==true,collection=data.collection}
end
function Storage.save(run,collection)
    local revision=(Storage.revision or 0)+1
    local path=revision%2==1 and SAVE_FILE..".backup" or SAVE_FILE
    local ok,payload=pcall(cjson.encode,{version=2,revision=revision,best=run.best,sound=run.sound,
        tutorialSeen=run.tutorialSeen==true,collection=collection and collection:export() or nil})
    if not ok then return false end
    local file=File(path,FILE_WRITE)
    if not file or not file:IsOpen() then return false end
    file:WriteString(payload); file:Close()
    local checked=read(path)
    if not checked or checked.revision~=revision then return false end
    Storage.revision=revision
    return true
end
return Storage
