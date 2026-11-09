var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
var out={};
for(const name of ['04 今日','07 我的','09 设置']){
  var f=frameByName(name);
  var items=[];
  for(const n of f.children){
    if(n.name.indexOf('tab')===0 || n.name==='tabbar'){
      items.push({n:n.name, x:Math.round(n.x), chars:(n.type==='TEXT'?n.characters:null)});
    }
  }
  out[name]=items;
}
return out;
