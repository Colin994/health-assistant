// v7 信息架构（2026-11-10）：提醒设置 移入「我的」。
// 07 我的：删指路页脚 sethint，新增「提醒节奏」区块（标题 + 提醒设置行）。
// 09 设置：删「提醒设置」行（row1/rt1/chev1），隐私/关于两行上移 72。
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',text:'#28332F',white:'#FFFFFF',sec:'#949997',ter:'#BFC2C1'};
function paint(c,o){return [{type:'SOLID',color:hex(c),opacity:(o==null?1:o)}];}
var F_CN='HarmonyOS Sans SC';
var STYLE={'Regular':'Regular','Medium':'Medium','Semi Bold':'Bold'};
var FONTS=[F_CN+'|Regular',F_CN+'|Medium',F_CN+'|Bold'];
for(var fi=0;fi<FONTS.length;fi++){var ff=FONTS[fi].split('|');try{await pixso.loadFontAsync({family:ff[0],style:ff[1]});}catch(e){}}
var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
function node(f,name){for(const n of f.children){if(n.name===name)return n;}return null;}
function rm(f,names){var removed=[];for(const n of Array.from(f.children)){if(names.indexOf(n.name)>=0){removed.push(n.name);n.remove();}}return removed;}
function rect(f,name,w,h,x,y,c,rad){var r=pixso.createRectangle();r.name=name;r.resize(w,h);r.x=x;r.y=y;r.fills=paint(c);if(rad)r.cornerRadius=rad;f.appendChild(r);return r;}
function txt(f,name,str,size,style,c,x,y,w,lh){var t=pixso.createText();t.name=name;t.characters=str;
 try{t.fontName={family:F_CN,style:STYLE[style]||'Regular'};}catch(e){}
 t.fontSize=size;t.fills=paint(c);
 var lines=String(str).split('\n').length;var lineH=lh||Math.round(size*1.4);
 t.resize(w,lineH*lines);t.x=x;t.y=y;t.textAlignHorizontal='LEFT';
 try{t.lineHeight={value:lineH,unit:'PIXELS'};}catch(e){}
 f.appendChild(t);return t;}
var log={};

// ---- 07 我的 ----
var f07=frameByName('07 我的');
log.removed07=rm(f07,['sethint']);
txt(f07,'sec2','提醒节奏',13,'Semi Bold',C.sec,32,272,120,18);
rect(f07,'rrow',326,60,32,296,C.white,16);
txt(f07,'rt','提醒设置',15,'Medium',C.text,52,306,150,20);
txt(f07,'rs','久坐 · 喝水 · 护眼 · 静音时段',11,'Regular',C.sec,52,330,240,16);
txt(f07,'rchev','›',16,'Medium',C.ter,332,308,20,20);
log.f07='页脚已删,提醒节奏区块已加';

// ---- 09 设置 ----
var f09=frameByName('09 设置');
log.removed09=rm(f09,['row1','rt1','chev1']);
['row2','rt2','chev2','row3','rt3','chev3'].forEach(function(nm){
  var n=node(f09,nm); if(n){ n.y-=72; }
});
log.f09='提醒设置行已删,隐私/关于上移72';

return log;
