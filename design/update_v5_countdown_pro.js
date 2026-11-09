// v5: hide watch-connect into Settings as Pro paid feature (not built yet);
//     add water & eye-care reminders on countdown core; adjust onboarding.
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',text:'#28332F',white:'#FFFFFF',fa:'#FAFAFA',p10:'#E9F9F7',p5:'#F4FCFB',sec:'#949997',ter:'#BFC2C1',danger:'#FF4747'};
function paint(c,o){return [{type:'SOLID',color:hex(c),opacity:(o==null?1:o)}];}
var F_CN='HarmonyOS Sans SC', F_EN='Poppins';
var STYLE={'Regular':'Regular','Medium':'Medium','Semi Bold':'Bold','Bold':'Bold'};
var FONTS=[F_CN+'|Regular',F_CN+'|Medium',F_CN+'|Bold',F_EN+'|Regular',F_EN+'|Medium',F_EN+'|Bold'];
for(var fi=0;fi<FONTS.length;fi++){var ff=FONTS[fi].split('|');try{await pixso.loadFontAsync({family:ff[0],style:ff[1]});}catch(e){}}
var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
function rm(f,names){var removed=[];for(const n of Array.from(f.children)){if(names.indexOf(n.name)>=0){removed.push(n.name);n.remove();}}return removed;}
function rmExcept(f,keep){var removed=[];for(const n of Array.from(f.children)){if(keep.indexOf(n.name)<0){removed.push(n.name);n.remove();}}return removed;}
function rect(f,name,w,h,x,y,c,o,rad){var r=pixso.createRectangle();r.name=name;r.resize(w,h);r.x=x;r.y=y;r.fills=c?paint(c,o):[];if(rad)r.cornerRadius=rad;f.appendChild(r);return r;}
function circ(f,name,d,x,y,c,o){var e=pixso.createEllipse();e.name=name;e.resize(d,d);e.x=x;e.y=y;e.fills=c?paint(c,o):[];f.appendChild(e);return e;}
function txt(f,name,str,size,style,c,x,y,w,lh,fam){var t=pixso.createText();t.name=name;t.characters=str;
 try{t.fontName={family:fam||F_CN,style:STYLE[style]||'Regular'};}catch(e){}
 t.fontSize=size;t.fills=paint(c);
 var lines=String(str).split('\n').length; var lineH=lh||Math.round(size*1.4);
 t.resize(w,lineH*lines);t.x=x;t.y=y;t.textAlignHorizontal='LEFT';
 try{t.lineHeight={value:lineH,unit:'PIXELS'};}catch(e){}
 f.appendChild(t);return t;}
function pillBtn(f,label,x,y,w,h,active,txtSize){
 var b=rect(f,'btn-'+label,w,h,x,y,active?C.primary:C.p10,1,100);
 txt(f,'bt-'+label,label,txtSize||14,active?'Semi Bold':'Medium',active?C.white:C.primary,x+16,y+(h-(txtSize||14)*1.4)/2,w-32,Math.round((txtSize||14)*1.4));
 return b;}
function navbar(f,title){
 txt(f,'back','‹',26,'Regular',C.text,28,64,30,30,F_EN);
 txt(f,'nav',title,16,'Semi Bold',C.text,68,70,220,22);
}
function tabbar3(f, active){
 var tb=rect(f,'tabbar',342,62,24,756,C.white,1,31);
 tb.strokes=[{type:'SOLID',color:hex(C.p5)}];try{tb.strokeWeight=1;}catch(e){}
 var labels=['今日','我的','设置'], xs=[28,142,256];
 for(var i=0;i<3;i++){
  if(i===active){rect(f,'tabpill'+i,106,54,xs[i],760,C.primary,1,26);}
  txt(f,'tabt'+i,labels[i],12,i===active?'Semi Bold':'Medium',i===active?C.white:C.sec,xs[i]+33,783,40,17);
 }
}
var KEEP=['time','sig','wifi1','wifi2','wifi3','battery','battfill','home'];
var log={};

// ---- 01 价值页：卖点改为倒计时/三类提醒 ----
var f01=frameByName('01 首启-价值');
for(const n of Array.from(f01.children)){
  if(n.name==='pd0') n.characters='倒计时到了才提醒，不打断心流';
  if(n.name==='pd2') n.characters='久坐、喝水、护眼，1 分钟微休息';
}
log.f01='points updated';

// ---- 03 权限引导：仅通知授权 + Pro 手表预告卡 ----
var f03=frameByName('03 首启-权限引导');
log.f03=rmExcept(f03, KEEP);
navbar(f03,'开启提醒');
txt(f03,'sub','开启通知，倒计时到了准时提醒你',13,'Regular',C.sec,32,104,280,18);
rect(f03,'perm1',326,120,32,144,C.fa,1,16);
circ(f03,'ic1',44,52,168,C.p10,1);txt(f03,'ic1t','◔',18,'Regular',C.primary,68,182,20,24,F_EN);
txt(f03,'p1t','通知',15,'Semi Bold',C.text,108,162,120,22);
txt(f03,'p1d','提醒的唯一通道，\n可随时在系统中关闭。',12,'Regular',C.sec,108,188,124,18);
pillBtn(f03,'去开启',240,168,102,36,true,13);
rect(f03,'perm2',326,132,32,280,C.fa,1,16);
circ(f03,'ic2',44,52,308,C.p10,1);txt(f03,'ic2t','◷',18,'Regular',C.primary,68,322,20,24,F_EN);
txt(f03,'p2t','连接智能手表',15,'Semi Bold',C.text,108,298,120,22);
rect(f03,'pro2',36,18,232,300,C.primary,1,100);
txt(f03,'pro2t','PRO',10,'Bold',C.white,240,303,26,14,F_EN);
txt(f03,'p2d','更准的久坐判定 · Pro\n付费功能，即将上线',12,'Regular',C.sec,108,324,150,18);
pillBtn(f03,'了解更多',240,344,102,36,false,13);
txt(f03,'priv','提醒由本地倒计时生成，不采集健康数据；\n连接手表（Pro）上线后才读取活动记录。',11,'Regular',C.ter,32,436,326,36);
pillBtn(f03,'进入应用',32,772,326,56,true,16);

// ---- 04 今日：隐藏手表数据源，加三类倒计时 chips ----
var f04=frameByName('04 今日');
log.f04=rm(f04,['wface','wicon','src']);
for(const n of Array.from(f04.children)){
  if(n.name==='nel') n.characters='下次提醒（倒计时）';
  if(n.name==='nev') n.characters='久坐 14:30 · 喝水 14:50 · 护眼 15:10';
}
var chips=[['久坐 · 55 分',32,96],['喝水 · 45 分',136,96],['护眼 · 20 分',240,92]];
for(var i=0;i<3;i++){
  rect(f04,'chip'+i,chips[i][2],28,chips[i][1],124,C.p10,1,100);
  txt(f04,'chipt'+i,chips[i][0],11,'Medium',C.primary,chips[i][1]+8,131,chips[i][2]-16,16);
}

// ---- 08 提醒设置：三类提醒（久坐/喝水/护眼）+ 静音 ----
var f08=frameByName('08 提醒设置');
log.f08=rmExcept(f08, KEEP);
navbar(f08,'提醒设置');
rect(f08,'denCard',326,110,32,112,C.white,1,16);
txt(f08,'dt','久坐拉伸',14,'Semi Bold',C.text,52,128,120,20);
var segs=[['更严格','45 分钟',false],['标准','55 分钟',true],['更宽松','75 分钟',false]];
for(var i=0;i<3;i++){var x=52+i*98, sel=segs[i][2];
 rect(f08,'seg'+i,90,48,x,154,sel?C.primary:C.fa,1,12);
 txt(f08,'sgt'+i,segs[i][0],12,sel?'Semi Bold':'Medium',sel?C.white:C.text,x+10,162,70,17);
 txt(f08,'sgd'+i,segs[i][1],10,'Regular',sel?C.white:C.ter,x+10,180,70,14);}
rect(f08,'waterCard',326,84,32,234,C.white,1,16);
txt(f08,'wt','喝水提醒',14,'Semi Bold',C.text,52,250,120,20);
txt(f08,'wd','每 45 分钟 · 一小杯就好',12,'Regular',C.sec,52,274,200,17);
rect(f08,'swW',51,31,291,252,C.primary,1,100);circ(f08,'knW',27,303,255,C.white,1);
rect(f08,'eyeCard',326,84,32,330,C.white,1,16);
txt(f08,'et','护眼提醒',14,'Semi Bold',C.text,52,346,120,20);
txt(f08,'ed','20-20-20 · 每 20 分钟远眺 20 秒',12,'Regular',C.sec,52,370,230,17);
rect(f08,'swE',51,31,291,348,C.primary,1,100);circ(f08,'knE',27,303,351,C.white,1);
rect(f08,'quietCard',326,84,32,426,C.white,1,16);
txt(f08,'qt','静音时段',14,'Semi Bold',C.text,52,442,120,20);
txt(f08,'qv','22:00 – 07:00',13,'Regular',C.sec,52,466,140,18);
rect(f08,'sw1',51,31,291,444,C.primary,1,100);circ(f08,'kn1',27,303,447,C.white,1);
rect(f08,'noonCard',326,84,32,522,C.white,1,16);
txt(f08,'nt','午休静音',14,'Semi Bold',C.text,52,538,120,20);
txt(f08,'nv','12:30 – 13:30 不提醒',12,'Regular',C.sec,52,562,170,17);
rect(f08,'sw2',51,31,291,540,C.primary,1,100);circ(f08,'kn2',27,303,543,C.white,1);
txt(f08,'auton','三类提醒共享静音时段；自动降频：负面反馈过多时自动放宽。\n当前：久坐 标准（55 分钟）· 喝水 45 分 · 护眼 20 分',11,'Regular',C.ter,32,622,326,36);
rect(f08,'testbtn',326,52,32,670,C.p10,1,100);
txt(f08,'tb','发一条试试 ›',14,'Semi Bold',C.primary,136,685,140,20);

// ---- 09 设置：通用区顶部加「连接智能手表 PRO」 ----
var f09=frameByName('09 设置');
log.f09=rmExcept(f09, KEEP.concat(['title']));
txt(f09,'sec1','通用',13,'Semi Bold',C.sec,32,126,120,18);
var rows1=[['连接智能手表','久坐判定更准 · Pro 即将上线'],['提醒设置','久坐 · 喝水 · 护眼 · 静音时段'],['隐私与数据说明','我们读取什么、存在哪'],['关于','版本 0.1.0']];
for(var i=0;i<4;i++){var y=152+i*72;
 rect(f09,'row'+i,326,60,32,y,C.white,1,16);
 txt(f09,'rt'+i,rows1[i][0],14,'Semi Bold',C.text,52,y+12,150,20);
 txt(f09,'rd'+i,rows1[i][1],11,'Regular',C.ter,52,y+34,240,16);
 if(i===0){rect(f09,'pro0',36,18,276,y+14,C.primary,1,100);txt(f09,'pro0t','PRO',10,'Bold',C.white,284,y+17,26,14,F_EN);}
 txt(f09,'chev'+i,'›',18,'Regular',C.ter,332,y+16,20,24,F_EN);}
txt(f09,'sec2','开发者',13,'Semi Bold',C.sec,32,462,120,18);
var rows2=[['W1 链路验证','传感器 + Health Connect 探针'],['重看首启引导','设计稿 01–03 · 首启流程'],['拉伸页','设计稿 05–06 · 深链调试']];
for(var i=0;i<3;i++){var y=488+i*72;
 rect(f09,'drow'+i,326,60,32,y,C.white,1,16);
 txt(f09,'dt'+i,rows2[i][0],14,'Semi Bold',C.text,52,y+12,150,20);
 txt(f09,'dd'+i,rows2[i][1],11,'Regular',C.ter,52,y+34,240,16);
 txt(f09,'dchev'+i,'›',18,'Regular',C.ter,332,y+16,20,24,F_EN);}
txt(f09,'devhint','仅调试构建显示 · 正式版隐藏',11,'Regular',C.ter,32,708,300,16);
tabbar3(f09,2);
return log;
