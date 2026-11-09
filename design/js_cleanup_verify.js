var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
var f07=frameByName('07 我的');
var removed=[];
for(const n of Array.from(f07.children)){
  if(['tab1bg','tab2','tab2bg','tab1','tabbar','tab1t','tab2t','tab3t'].indexOf(n.name)>=0){removed.push(n.name);n.remove();}
}
// dump tab bar zone + body of 04/07/09 for verification
function dump(f){return f.children.map(c=>({n:c.name,x:Math.round(c.x),y:Math.round(c.y),w:Math.round(c.width),h:Math.round(c.height)}));}
var f04=frameByName('04 今日'), f09=frameByName('09 设置');
return {removed:removed,
  f04_tabbar: dump(f04).filter(i=>i.y>750||i.n.indexOf('tab')===0),
  f07_all: dump(f07),
  f09_all: dump(f09)};
