// v6: add water tags (常忘喝水/咽干易上火) into the health-tag system.
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',text:'#28332F',white:'#FFFFFF',fa:'#FAFAFA',p10:'#E9F9F7',p5:'#F4FCFB',sec:'#949997',ter:'#BFC2C1'};
function paint(c,o){return [{type:'SOLID',color:hex(c),opacity:(o==null?1:o)}];}
var F_CN='HarmonyOS Sans SC', F_EN='Poppins';
var STYLE={'Regular':'Regular','Medium':'Medium','Semi Bold':'Bold','Bold':'Bold'};
var FONTS=[F_CN+'|Regular',F_CN+'|Medium',F_CN+'|Bold',F_EN+'|Regular',F_EN+'|Medium',F_EN+'|Bold'];
for(var fi=0;fi<FONTS.length;fi++){var ff=FONTS[fi].split('|');try{await pixso.loadFontAsync({family:ff[0],style:ff[1]});}catch(e){}}
var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
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
var log={};

// ---- 02 首启-健康标签：标签网格 2x2 -> 2x3，下移 兜底项/预览卡 ----
var f02=frameByName('02 首启-健康标签');
for(const n of Array.from(f02.children)){
  if(n.name==='nav') n.characters='你的身体状况与习惯';
  if(n.name==='only') n.y=436;
  if(n.name==='oco') n.y=451;
  if(n.name==='oct') n.y=448;
  if(n.name==='preview') n.y=500;
  if(n.name==='pvh') n.y=516;
  if(n.name==='pvb') n.y=540;
}
var tags45=[['常忘喝水','到点提醒接水',32],['咽干易上火','文案更温和',198]];
for(var i=0;i<2;i++){var x=tags45[i][2];
 rect(f02,'tag'+(4+i),150,84,x,336,C.fa,1,16);
 txt(f02,'ttn'+(4+i),tags45[i][0],15,'Medium',C.text,x+20,354,110,22);
 txt(f02,'ttd'+(4+i),tags45[i][1],11,'Regular',C.ter,x+20,386,100,16);}
log.f02='tags 2x3 + moved only/preview';

// ---- 07 我的：档案胶囊示例补一个喝水标签 ----
var f07=frameByName('07 我的');
pillBtn(f07,'常忘喝水',232,170,80,32,false,12);
log.f07='water tag pill added';
return log;
