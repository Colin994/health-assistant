var p=pixso.getNodeById('16:1');
var f=null;for(const c of p.children){if(c.name==='07 我的')f=c;}
var n=null;for(const c of f.children){if(c.name==='editbtn')n=c;}
if(n){n.x=310;n.resize(48,18);}
return {editbtn:'x=310 w=48 in-bounds'};
