// v8 信息架构二轮（2026-11-10）：
// 07 我的：提醒区上移、标签区下移、标签区加「编辑」按钮、删提醒节奏标题改「提醒」。
// 08 提醒设置：分「提醒内容」/「免打扰」两组，删页底汇总卡与发一条试试。
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',text:'#28332F',white:'#FFFFFF',sec:'#949997',ter:'#BFC2C1',p10:'#E9F9F7'};
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

// ---- 07 我的 v8 ----
var f07=frameByName('07 我的');
// 删旧区块（v7 的提醒节奏 + 标签行）
log.rm07=rm(f07,['sec1','sec2','tagcard','tghint','rrow','rt','rs','rchev']);
// 删旧标签胶囊（btn-/bt- 系列）
var tagBtns=[];for(const n of Array.from(f07.children)){if(n.name.indexOf('btn-')===0||n.name.indexOf('bt-')===0){tagBtns.push(n.name);n.remove();}}
log.rmTags=tagBtns.length;

// 提醒（置顶）
txt(f07,'sec1','提醒',13,'Semi Bold',C.sec,32,126,120,18);
rect(f07,'remrow',326,60,32,150,C.white,16);
txt(f07,'remt','提醒设置',15,'Medium',C.text,52,160,150,20);
txt(f07,'rems','久坐 · 喝水 · 护眼 · 免打扰',11,'Regular',C.sec,52,184,240,16);
txt(f07,'remchev','›',16,'Medium',C.ter,332,162,20,20);

// 健康标签（下移 + 编辑按钮）
txt(f07,'sec2','健康标签',13,'Semi Bold',C.sec,32,240,120,18);
txt(f07,'editbtn','编辑',12,'Medium',C.primary,580,240,40,16);
// 标签胶囊（3 个示例）
var tagX=32;
var tags=['颈椎不适','眼疲劳','常忘喝水'];
for(var ti=0;ti<tags.length;ti++){
  var tw=tags[ti].length*16+24;
  rect(f07,'btn-'+tags[ti],tw,32,tagX,264,C.p10,26);
  txt(f07,'bt-'+tags[ti],tags[ti],12,'Medium',C.primary,tagX+12,271,tw-24,17);
  tagX+=tw+8;
}
txt(f07,'tghint','修改后下次提醒生效',10,'Regular',C.ter,32,308,200,14);

log.f07='v8: 提醒上/标签下+编辑';

// ---- 08 提醒设置 v8 ----
var f08=frameByName('08 提醒设置');
// 删旧布局全部条目（保留标题栏 back + title + time）
var rm08=[];for(const n of Array.from(f08.children)){
  var nm=n.name;
  if(nm!=='time'&&nm!=='back'&&nm!=='title'&&nm!=='sig'&&nm!=='wifi1'&&nm!=='wifi2'&&nm!=='wifi3'&&nm!=='battery'&&nm!=='battfill'&&nm!=='home'&&nm!=='tabbar'&&nm!=='tabpill1'&&nm!=='tabt0'&&nm!=='tabt1'&&nm!=='tabt2'){
    rm08.push(nm);n.remove();
  }
}
log.rm08=rm08.length+' nodes';

// 提醒内容
txt(f08,'secA','提醒内容',13,'Semi Bold',C.sec,32,100,120,18);
// 久坐拉伸卡
rect(f08,'sedcard',326,100,32,124,C.white,16);
txt(f08,'sedt','久坐拉伸',15,'Medium',C.text,52,134,150,20);
// 三档
var dens=[['更严格','45 分钟',32],['标准','55 分钟',142],['更宽松','75 分钟',252]];
for(var di=0;di<dens.length;di++){
  var sel=dens[di][0]==='标准';
  rect(f08,'den'+di,90,48,dens[di][2],160,sel?C.p10:C.white,10);
  txt(f08,'dent'+di,dens[di][0],12,'Medium',sel?C.primary:C.text,dens[di][2]+6,168,78,16);
  txt(f08,'dens'+di,dens[di][1],10,'Regular',C.sec,dens[di][2]+6,186,78,14);
}
// 喝水
rect(f08,'watcard',326,60,32,240,C.white,16);
txt(f08,'watt','喝水提醒',15,'Medium',C.text,52,250,150,20);
txt(f08,'wats','每 45 分钟 · 一小杯就好',11,'Regular',C.sec,52,274,200,16);
txt(f08,'watsw','●',16,'Medium',C.primary,324,252,16,16);
// 护眼
rect(f08,'eyecard',326,60,32,312,C.white,16);
txt(f08,'eyet','护眼提醒',15,'Medium',C.text,52,322,150,20);
txt(f08,'eyes','20-20-20 · 每 20 分钟远眺 20 秒',11,'Regular',C.sec,52,346,200,16);
txt(f08,'eyesw','●',16,'Medium',C.primary,324,324,16,16);

// 免打扰
txt(f08,'secB','免打扰',13,'Semi Bold',C.sec,32,396,120,18);
// 静音时段
rect(f08,'mutecard',326,60,32,420,C.white,16);
txt(f08,'mutet','静音时段',15,'Medium',C.text,52,430,150,20);
txt(f08,'mutes','22:00 – 07:00 · 静音时倒计时暂停',11,'Regular',C.sec,52,454,240,16);
txt(f08,'mchev','›',16,'Medium',C.ter,332,432,20,20);
// 午休静音
rect(f08,'lunchcard',326,60,32,492,C.white,16);
txt(f08,'luncht','午休静音',15,'Medium',C.text,52,502,150,20);
txt(f08,'lunchs','12:30 – 13:30 不提醒',11,'Regular',C.sec,52,526,200,16);
txt(f08,'lunchsw','●',16,'Medium',C.primary,324,504,16,16);

log.f08='v8: 提醒内容+免打扰两组';

return log;
