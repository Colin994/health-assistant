var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
var out={};
// 03: desc box narrower + button lower; priv per-line height
var f03=frameByName('03 首启-权限引导');
for(const n of Array.from(f03.children)){
  if(n.name==='p2d'){ n.resize(126,36); try{n.lineHeight={value:18,unit:'PIXELS'};}catch(e){} }
  if(n.name==='btn-了解更多'){ n.y=350; }
  if(n.name==='bt-了解更多'){ n.y=350+(36-13*1.4)/2; }
  if(n.name==='priv'){ n.resize(326,36); try{n.lineHeight={value:18,unit:'PIXELS'};}catch(e){} }
}
out.f03='fixed';
// 08: auton per-line height
var f08=frameByName('08 提醒设置');
for(const n of Array.from(f08.children)){
  if(n.name==='auton'){ n.resize(326,36); try{n.lineHeight={value:18,unit:'PIXELS'};}catch(e){} }
}
out.f08='fixed';
return out;
