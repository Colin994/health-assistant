var p=pixso.getNodeById('16:1');
var f=null;for(const c of p.children){if(c.name==='04 今日')f=c;}
var log={};
for(const n of f.children){
  if(n.name==='cbr'){ n.y+=150; log.cbr=n.y; }
  if(n.name==='scnum'){ n.resize(110,40); log.scnum='w=110'; }
}
return log;
