"""Build a local HTML viewer of unchanged costume PNGs and their atlas frames."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
atlas = json.loads((root / 'art/costume-atlas.json').read_text(encoding='utf-8'))
items = [
 ('toilet','马桶大王','传说','圈是披肩，皮搋子是王冠。'),
 ('socks','臭袜战神','史诗','旧袜当围巾，路过都得屏住呼吸。'),
 ('trash','垃圾桶隐士','稀有','桶盖一扣，今天谁也别想找到我。'),
 ('saltfish','咸鱼上班','史诗','领带打好了，鱼还没醒。'),
]
data = [dict(id=i,name=n,tier=t,detail=d,**atlas[i]) for i,n,t,d in items]
html = r'''<!doctype html>
<html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>奶蛙 · 四套搞怪服装动作预览</title>
<style>
:root{color-scheme:light;--bg:#f6f0df;--ink:#314332;--card:#fffdf5;--stage:#e4ede1;--line:#d4d8c5}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 system-ui,'Microsoft YaHei',sans-serif}main{max-width:1320px;margin:auto;padding:36px 22px 70px}h1{font-size:30px;margin:0 0 6px}p{margin:0 0 18px}.bar{display:flex;flex-wrap:wrap;gap:10px;margin:22px 0}button,select,a.link{border:1px solid var(--line);border-radius:9px;padding:9px 13px;background:var(--card);color:var(--ink);font:inherit;cursor:pointer;text-decoration:none}button:focus-visible,select:focus-visible,a:focus-visible{outline:3px solid #b37c23;outline-offset:2px}button.active{background:#355943;color:#fff}#cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px}.card{border:1px solid var(--line);border-radius:16px;background:var(--card);overflow:hidden}.title{padding:16px 16px 8px}.title h2{margin:0;font-size:22px}.tag{display:inline-block;font-size:13px;border-radius:6px;padding:2px 7px;background:#ede4cd;margin-top:6px}.stage{background:var(--stage);height:320px;display:grid;place-items:center}.stage canvas{max-width:100%;height:320px;width:280px;image-rendering:pixelated}.controls{padding:14px}.detail{font-size:14px;min-height:45px;margin:0 0 10px}input[type=range]{width:100%;accent-color:#355943}.frame{font-size:13px;display:block;margin:4px 0 8px}.links{display:flex;gap:6px}.links>*{font-size:13px!important;padding:6px 8px!important}.note{margin-top:24px;color:#647360;font-size:14px}body.dark{--bg:#192c29;--ink:#f1ead9;--card:#263b35;--stage:#132521;--line:#4a5c4f}body.dark .tag{background:#4a4935}body.dark .note{color:#c0cdbd}@media(max-width:1000px){#cards{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:520px){#cards{grid-template-columns:1fr}main{padding:22px 14px}}
</style>
<main><h1>奶蛙 · 四套搞怪服装</h1><p>保留奶蛙原形象。每套 16 帧，点击下方滑条可逐帧查看衣服和手脚。</p>
<div class="bar" aria-label="动作选择"><button data-row="0" class="active">待机</button><button data-row="1">走路</button><button data-row="2">大笑</button><button data-row="3">跳跃动作</button><button id="play">暂停播放</button><button id="theme">深色背景</button><label>速度 <select id="speed"><option value=".5">0.5 倍</option><option value="1" selected>正常</option><option value="1.5">1.5 倍</option></select></label></div>
<section id="cards"></section><p class="note">这是服装动作素材预览；实际跳跃的位移、滞空和落地由游戏控制。原 PNG 保留透明背景，不经过重绘或调色。所有衣服只改变外观。</p></main>
<script>
const data=__COSTUME_DATA__;
const state={row:0,playing:true,time:0,last:0,speed:1};
const cards=data.map(item=>{
 const card=document.createElement('article');card.className='card';
 card.innerHTML='<div class="title"><h2>'+item.name+'</h2><span class="tag">'+item.tier+'</span></div><div class="stage"><canvas width="560" height="640" role="img" aria-label="'+item.name+'动作"></canvas></div><div class="controls"><p class="detail">'+item.detail+'</p><input type="range" min="1" max="16" value="1" aria-label="'+item.name+'帧数"><span class="frame">第 1 / 16 帧</span><div class="links"><a class="link" target="_blank" href="../assets/'+item.file+'">查看 16 帧原图</a></div></div>';
 document.querySelector('#cards').append(card);
 const canvas=card.querySelector('canvas'),ctx=canvas.getContext('2d'),slider=card.querySelector('input'),label=card.querySelector('.frame');
 const img=new Image(); const model={item,canvas,ctx,slider,label,img,index:0,ready:false};
 img.onload=()=>{model.ready=true;draw(model)};img.onerror=()=>{label.textContent='素材读取失败，请保留交付文件夹与 assets 的相对位置。'};img.src='../assets/'+item.file;
 slider.addEventListener('input',()=>{state.playing=false;document.querySelector('#play').textContent='继续播放';model.index=+slider.value-1;draw(model)});
 return model;
});
function draw(c){if(!c.ready)return;const [x,y,w,h]=c.item.frames[c.index],ctx=c.ctx;ctx.clearRect(0,0,560,640);ctx.imageSmoothingEnabled=false;const scale=Math.min(490/c.item.frames[0][3],500/Math.max(...c.item.frames.map(f=>f[2])));ctx.drawImage(c.img,x,y,w,h,Math.round(280-w*scale/2),Math.round(596-h*scale),Math.round(w*scale),Math.round(h*scale));c.slider.value=c.index+1;c.label.textContent='第 '+(c.index+1)+' / 16 帧'}
document.querySelectorAll('[data-row]').forEach(button=>button.onclick=()=>{state.row=+button.dataset.row;state.time=0;cards.forEach(c=>{c.index=state.row*4;draw(c)});document.querySelectorAll('[data-row]').forEach(b=>b.classList.toggle('active',b===button))});
document.querySelector('#play').onclick=()=>{state.playing=!state.playing;document.querySelector('#play').textContent=state.playing?'暂停播放':'继续播放'};
document.querySelector('#theme').onclick=()=>{const dark=document.body.classList.toggle('dark');document.querySelector('#theme').textContent=dark?'浅色背景':'深色背景'};
document.querySelector('#speed').onchange=e=>state.speed=+e.target.value;
const durations=[[280,280,280,360],[150,150,150,150],[160,160,180,360],[250,240,200,450]];
function loop(t){const dt=Math.min(100,t-(state.last||t));state.last=t;if(state.playing){state.time+=dt*state.speed;const times=durations[state.row],total=times.reduce((a,b)=>a+b,0);let pos=state.time%total,k=0;while(k<3&&pos>=times[k]){pos-=times[k];k++}cards.forEach(c=>{const index=state.row*4+k;if(c.index!==index){c.index=index;draw(c)}})}requestAnimationFrame(loop)}requestAnimationFrame(loop);
</script></html>'''
target=root/'交付/搞怪服装动作预览.html'
target.write_text(html.replace('__COSTUME_DATA__',json.dumps(data,ensure_ascii=False)),encoding='utf-8')
print(target)
