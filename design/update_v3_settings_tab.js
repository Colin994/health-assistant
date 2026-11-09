// v3 targeted update: 3-tab nav (今日/设置/我的) + new 09 设置 screen.
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
function rect(f,name,w,h,x,y,c,o,rad){var r=pixso.createRectangle();r.name=name;r.resize(w,h);r.x=x;r.y=y;r.fills=c?paint(c,o):[];if(rad)r.cornerRadius=rad;f.appendChild(r);return r;}
function circ(f,name,d,x,y,c,o){var e=pixso.createEllipse();e.name=name;e.resize(d,d);e.x=x;e.y=y;e.fills=c?paint(c,o):[];f.appendChild(e);return e;}
function txt(f,name,str,size,style,c,x,y,w,lh,fam){var t=pixso.createText();t.name=name;t.characters=str;
 try{t.fontName={family:fam||F_CN,style:STYLE[style]||'Regular'};}catch(e){}
 t.fontSize=size;t.fills=paint(c);
 var lines=String(str).split('\n').length; var lineH=lh||Math.round(size*1.4);
 t.resize(w,lineH*lines);t.x=x;t.y=y;t.textAlignHorizontal='LEFT';
 try{t.lineHeight={value:lineH,unit:'PIXELS'};}catch(e){}
 f.appendChild(t);return t;}
function statusbar(f){
 txt(f,'time','9:41',15,'Bold','#000000',27,14,54,20,F_EN);
 for(var i=0;i<4;i++){circ(f,'sig',4,289+i*7,20,'#000000',1);}
 circ(f,'wifi1',5,320,19,'#000000',1);circ(f,'wifi2',3.4,321.3,20.8,'#000000',1);circ(f,'wifi3',2,322.3,22.2,'#000000',1);
 var b=rect(f,'battery',25,13,330,17,null,0,4);b.strokes=[{type:'SOLID',color:hex('#000000')}];try{b.strokeWeight=1.2;}catch(e){}
 rect(f,'battfill',17,8,332.5,19.5,'#000000',1,2);
 rect(f,'home',134,5,128,839,null,1,0);
}
// 3-slot bottom tab bar: slots at x=28/142/256 (w=106, gap=8), active index 0=今日 1=设置 2=我的
function tabbar3(f, active){
 var tb=rect(f,'tabbar',342,62,24,756,C.white,1,31);
 tb.strokes=[{type:'SOLID',color:hex(C.p5)}];try{tb.strokeWeight=1;}catch(e){}
 var labels=['今日','设置','我的'], xs=[28,142,256];
 for(var i=0;i<3;i++){
  if(i===active){rect(f,'tabpill'+i,106,54,xs[i],760,C.primary,1,26);}
  txt(f,'tabt'+i,labels[i],12,i===active?'Semi Bold':'Medium',i===active?C.white:C.sec,xs[i]+33,783,40,17);
 }
}
var log={};

// ---- 04 今日: swap to 3-tab, 今日 active ----
var f04=frameByName('04 今日');
log.removed04=rm(f04,['tabbar','tab1','tab1t','tab2bg','tab2t']);
tabbar3(f04,0);

// ---- 07 我的: strip settings rows (moved to 09), swap to 3-tab, 我的 active ----
var f07=frameByName('07 我的');
log.removed07=rm(f07,['tabbar','tab1','tab1t','tab2bg','tab2t','sec2',
 'row0','row1','row2','rt0','rt1','rt2','rd0','rd1','rd2','chev0','chev1','chev2']);
txt(f07,'sethint','设置与开发者选项已移至「设置」页',11,'Regular',C.ter,32,276,300,16);
tabbar3(f07,2);

// ---- 09 设置 (new) ----
var fr=pixso.createFrame();fr.name='09 设置';fr.resize(390,844);fr.x=3568;fr.y=0;fr.fills=paint(C.white);page.appendChild(fr);
statusbar(fr);
txt(fr,'title','设置',24,'Semi Bold',C.text,32,70,120,32);
txt(fr,'sec1','通用',13,'Semi Bold',C.sec,32,126,120,18);
var rows1=[['提醒设置','密度 · 静音时段 · 测试提醒'],['隐私与数据说明','我们读取什么、存在哪'],['关于','版本 0.1.0']];
for(var i=0;i<3;i++){var y=152+i*72;
 rect(fr,'row'+i,326,60,32,y,C.white,1,16);
 txt(fr,'rt'+i,rows1[i][0],14,'Semi Bold',C.text,52,y+12,150,20);
 txt(fr,'rd'+i,rows1[i][1],11,'Regular',C.ter,52,y+34,240,16);
 txt(fr,'chev'+i,'›',18,'Regular',C.ter,332,y+16,20,24,F_EN);}
txt(fr,'sec2','开发者',13,'Semi Bold',C.sec,32,390,120,18);
var rows2=[['W1 链路验证','Health Connect + 计步探针'],['重看首启引导','设计稿 01–03 · 首启流程'],['拉伸页','设计稿 05–06 · 深链调试']];
for(var i=0;i<3;i++){var y=416+i*72;
 rect(fr,'drow'+i,326,60,32,y,C.white,1,16);
 txt(fr,'dt'+i,rows2[i][0],14,'Semi Bold',C.text,52,y+12,150,20);
 txt(fr,'dd'+i,rows2[i][1],11,'Regular',C.ter,52,y+34,240,16);
 txt(fr,'dchev'+i,'›',18,'Regular',C.ter,332,y+16,20,24,F_EN);}
txt(fr,'devhint','仅调试构建显示 · 正式版隐藏',11,'Regular',C.ter,32,648,300,16);
tabbar3(fr,1);
return log;
