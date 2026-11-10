var p=pixso.getNodeById('16:1');
var f=null;for(const c of p.children){if(c.name==='08 提醒设置')f=c;}
var n=null;for(const c of f.children){if(c.name==='eyes')n=c;}
if(n){n.characters='每 20 分钟 · 看 6 米外远处 20 秒';}
return {eyes:'fixed'};
