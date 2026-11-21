local UI=require("urhox-libs/UI")
local Art={}
Art.ink={47,52,30,255}
Art.cream={247,237,201,255}
Art.muted={186,199,155,255}
Art.gold={238,192,54,255}
Art.surface={42,62,46,255}
---@type table<string,{handle:integer,w:number,h:number}>
local images={}
local function image(vg,path)
 local a=images[path]
 if not a then
  local handle=nvgCreateImage(vg,path,NVG_IMAGE_NEAREST)
  if handle<=0 then error("UI art could not load: "..path) end
  local w,h=nvgImageSize(vg,handle)
  a={handle=handle,w=w,h=h};images[path]=a
 end
 return a
end
-- Runtime UV crop only: the generated PNG and its alpha stay unchanged on disk.
function Art.region(vg,path,src,x,y,w,h,alpha)
 if w<=0 or h<=0 then return end
 local a=image(vg,path)
 local sx,sy=w/src[3],h/src[4]
 nvgSave(vg);nvgIntersectScissor(vg,x,y,w,h)
 local paint=nvgImagePattern(vg,x-src[1]*sx,y-src[2]*sy,a.w*sx,a.h*sy,0,a.handle,alpha or 1)
 nvgBeginPath(vg);nvgRect(vg,x,y,w,h);nvgFillPaint(vg,paint);nvgFill(vg)
 nvgRestore(vg)
end
local buttonFrames={{64,70,1128,219},{64,365,1128,221},{64,661,1128,223},{64,958,1128,222}}
local function slicedButton(vg,frame,l,alpha)
 local src=buttonFrames[frame]
 local insetX,insetY=72,32
 local dx,dy=math.min(13,l.w/4),math.min(8,l.h/4)
 local xs={src[1],src[1]+insetX,src[1]+src[3]-insetX,src[1]+src[3]}
 local ys={src[2],src[2]+insetY,src[2]+src[4]-insetY,src[2]+src[4]}
 local tx={l.x,l.x+dx,l.x+l.w-dx,l.x+l.w}
 local ty={l.y,l.y+dy,l.y+l.h-dy,l.y+l.h}
 for row=1,3 do for col=1,3 do
  Art.region(vg,"image/ui/naiwa-buttons.png",{xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]},
   tx[col],ty[row],tx[col+1]-tx[col],ty[row+1]-ty[row],alpha)
 end end
end
-- Inherit the official Button's layout, input, focus, disabled handling and text.
-- Only its background renderer is replaced by the generated four-state atlas.
local Button=UI.Button:Extend("NaiwaArtButton")
function Button:Init(props)
 UI.Button.Init(self,props)
 self.secondary=props.secondary==true
end
function Button:RenderFullBackground(vg)
 local frame=self.secondary and 3 or 1
 if self.state.pressed and not self.props.disabled then frame=frame+1 end
 slicedButton(vg,frame,self:GetAbsoluteLayout(),self.props.disabled and .42 or 1)
end
function Art.button(text,action,secondary,disabled,extra)
 local p={text=text,height=52,width="100%",fontSize=20,padding=8,
  pressedPadding={10,8,6,8},secondary=secondary==true,disabled=disabled==true,
  textColor=secondary and Art.cream or Art.ink,disabledTextColor={161,169,137,255},
  backgroundColor={0,0,0,0},borderWidth=0,boxShadow=false,onClick=action}
 for k,v in pairs(extra or {}) do p[k]=v end
 return Button(p)
end
function Art.card(props)
 local p={backgroundColor=Art.cream,borderWidth=2,borderColor=Art.ink,padding=18,gap=10}
 for k,v in pairs(props or {}) do p[k]=v end
 return UI.Panel(p)
end
return Art
