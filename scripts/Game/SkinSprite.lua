local UI=require("urhox-libs/UI")
local frames=require("Game.SkinFrames")
local Sprite={}
---@type table<string,{handle:integer,w:number,h:number}>
local loaded={}
function Sprite.draw(vg,id,x,y,height,frame,face,silhouette,alpha)
 local entry=frames[id] or frames.original
 local path=entry.file
 local asset=loaded[path]
 if not asset then
  local handle=nvgCreateImage(vg,path,NVG_IMAGE_NEAREST)
  if handle<=0 then error("Costume could not load: "..path) end
  local w,h=nvgImageSize(vg,handle)
  asset={handle=handle,w=w,h=h}; loaded[path]=asset
 end
 local f=entry.frames[frame or 1] or entry.frames[1]
 local scale=height/entry.frames[1][4]
 local w,h=f[3]*scale,f[4]*scale
 nvgSave(vg); nvgTranslate(vg,math.floor(x),math.floor(y))
 if face and face>0 then nvgScale(vg,-1,1) end
 nvgIntersectScissor(vg,-w/2,-h,w,h)
 ---@type NVGpaint
 local paint
 if silhouette then
  paint=nvgImagePatternTinted(vg,-w/2-f[1]*scale,-h-f[2]*scale,asset.w*scale,asset.h*scale,0,asset.handle,nvgRGBA(0,0,0,255))
 else
  paint=nvgImagePattern(vg,-w/2-f[1]*scale,-h-f[2]*scale,asset.w*scale,asset.h*scale,0,asset.handle,alpha or 1)
 end
 nvgBeginPath(vg); nvgRect(vg,-w/2,-h,w,h); nvgFillPaint(vg,paint); nvgFill(vg)
 nvgRestore(vg)
end
Sprite.Portrait=UI.Widget:Extend("NaiwaSkinPortrait")
function Sprite.Portrait:Init(props)
 UI.Widget.Init(self,props)
 self.skinId=props.skinId or "original"
 self.silhouette=props.silhouette==true
end
function Sprite.Portrait:Render(vg)
 local l=self:GetAbsoluteLayout()
 if l.w>0 and l.h>0 then Sprite.draw(vg,self.skinId,l.x+l.w/2,l.y+l.h-4,math.min(l.h-8,l.w*1.2),1,-1,self.silhouette) end
end
return Sprite
