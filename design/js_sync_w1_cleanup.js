// 2026-11-09 设计稿同步：W1 清理后三处对齐（验收报告结论）
// 1) 09 设置：删「W1 链路验证」行（实现已移除，开发者区块剩 2 项），剩余行上移
// 2) 07 我的：页脚改 master 口径「提醒设置等功能请见「设置」页」
// 3) 04 今日：补状态行「今日步数 · 实时更新中」+ 步数卡（App 端额外保留模块，交互文档 §4.1）
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',text:'#28332F',white:'#FFFFFF',fa:'#FAFAFA',p10:'#E9F9F7',p5:'#F4FCFB',sec:'#949997',ter:'#BFC2C1'};
function paint(c,o){return [{type:'SOLID',color:hex(c),opacity:(o==null?1:o)}];}
var F_CN='HarmonyOS Sans SC', F_EN='Poppins';
var STYLE={'Regular':'Regular','Medium':'Medium','Semi Bold':'Bold','Bold':'Bold'};
var FONTS=[F_CN+'|Regular',F_CN+'|Medium',F_CN+'|Bold',F_EN+'|Regular',F_EN+'|Medium',F_EN+'|Bold'];
for(var fi=0;fi<FONTS.length;fi++){var ff=FONTS[fi].split('|');try{await pixso.loadFontAsync({family:ff[0],style:ff[1]});}catch(e){}}
var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
function node(f,name){for(const c of f.children){if(c.name===name)return c;}return null;}
function rm(f,names){var removed=[];for(const n of Array.from(f.children)){if(names.indexOf(n.name)>=0){removed.push(n.name);n.remove();}}return removed;}
function rect(f,name,w,h,x,y,c,rad){var r=pixso.createRectangle();r.name=name;r.resize(w,h);r.x=x;r.y=y;r.fills=paint(c);if(rad)r.cornerRadius=rad;f.appendChild(r);return r;}
function txt(f,name,str,size,style,c,x,y,w,lh,fam){var t=pixso.createText();t.name=name;t.characters=str;
 try{t.fontName={family:fam||F_CN,style:STYLE[style]||'Regular'};}catch(e){}
 t.fontSize=size;t.fills=paint(c);
 var lines=String(str).split('\n').length;var lineH=lh||Math.round(size*1.4);
 t.resize(w,lineH*lines);t.x=x;t.y=y;t.textAlignHorizontal='LEFT';
 try{t.lineHeight={value:lineH,unit:'PIXELS'};}catch(e){}
 f.appendChild(t);return t;}
var log={};

// ---- 1) 09 设置：删 W1 链路验证行，剩余开发者行上移 72 并重排命名 ----
var f09=frameByName('09 设置');
log.removed09=rm(f09,['drow0','dt0','dd0','dchev0']);
['drow','dt','dd','dchev'].forEach(function(p){
  for(var i=2;i>=1;i--){
    var n=node(f09,p+i);
    if(n){ n.y-=72; n.name=p+(i-1); }
  }
});
var dh=node(f09,'devhint'); if(dh){ dh.y-=72; }
log.f09='W1行已删,剩余两行上移';

// ---- 2) 07 我的：页脚改 master 口径 ----
var f07=frameByName('07 我的');
var sh=node(f07,'sethint');
if(sh){
  try{ sh.characters='提醒设置等功能请见「设置」页'; log.f07=sh.characters; }
  catch(e){ log.f07Err=String(e); }
}

// ---- 3) 04 今日：补状态行 + 步数卡，后续模块下移 ----
var f04=frameByName('04 今日');
// 状态行（标题与 chips 之间）
txt(f04,'srcrow','今日步数 · 实时更新中',12,'Medium',C.sec,32,112,240,17);
txt(f04,'srcre','↻',14,'Medium',C.sec,330,110,20,16);
// chips 下移 22
['chip0','chip1','chip2'].forEach(function(nm){var n=node(f04,nm);if(n)n.y+=22;});
['chipt0','chipt1','chipt2'].forEach(function(nm){var n=node(f04,nm);if(n)n.y+=22;});
// 步数卡（chips 与计数卡之间）
rect(f04,'stepcard',326,112,32,186,C.white,16);
txt(f04,'scnum','1,234',36,'Semi Bold',C.text,52,204,150,40,F_EN);
txt(f04,'scunit','步 · 今日',12,'Regular',C.sec,170,232,80,17);
txt(f04,'schint','今日累计 · 应用运行期间记录',10,'Regular',C.ter,52,266,260,14);
// 计数卡及以下整体下移 150
['countcard','ccl','cnum','crl','crn','cbt','nel','nev','recent','rft'].forEach(function(nm){
  var n=node(f04,nm); if(n){ n.y+=150; }
});
log.f04='状态行+步数卡已加,下方模块下移150';

return log;
