// v4: reorder bottom tabs to 今日/我的/设置 (settings last).
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',white:'#FFFFFF',p5:'#F4FCFB',sec:'#949997'};
function paint(c,o){return [{type:'SOLID',color:hex(c),opacity:(o==null?1:o)}];}
var F_CN='HarmonyOS Sans SC';
var STYLE={'Regular':'Regular','Medium':'Medium','Semi Bold':'Bold','Bold':'Bold'};
try{await pixso.loadFontAsync({family:F_CN,style:'Medium'});}catch(e){}
try{await pixso.loadFontAsync({family:F_CN,style:'Bold'});}catch(e){}
var page=pixso.getNodeById('16:1');
function frameByName(name){for(const c of page.children){if(c.name===name)return c;}return null;}
function rect(f,name,w,h,x,y,c,o,rad){var r=pixso.createRectangle();r.name=name;r.resize(w,h);r.x=x;r.y=y;r.fills=c?paint(c,o):[];if(rad)r.cornerRadius=rad;f.appendChild(r);return r;}
function txt(f,name,str,size,style,c,x,y,w,lh){var t=pixso.createText();t.name=name;t.characters=str;
 try{t.fontName={family:F_CN,style:STYLE[style]||'Regular'};}catch(e){}
 t.fontSize=size;t.fills=paint(c);
 var lineH=lh||Math.round(size*1.4);
 t.resize(w,lineH);t.x=x;t.y=y;t.textAlignHorizontal='LEFT';
 try{t.lineHeight={value:lineH,unit:'PIXELS'};}catch(e){}
 f.appendChild(t);return t;}
function tabbar3(f, active){
 var tb=rect(f,'tabbar',342,62,24,756,C.white,1,31);
 tb.strokes=[{type:'SOLID',color:hex(C.p5)}];try{tb.strokeWeight=1;}catch(e){}
 var labels=['今日','我的','设置'], xs=[28,142,256];
 for(var i=0;i<3;i++){
  if(i===active){rect(f,'tabpill'+i,106,54,xs[i],760,C.primary,1,26);}
  txt(f,'tabt'+i,labels[i],12,i===active?'Semi Bold':'Medium',i===active?C.white:C.sec,xs[i]+33,783,40,17);
 }
}
var log={};
var plan=[['04 今日',0],['07 我的',1],['09 设置',2]];
for(const [name, active] of plan){
 var f=frameByName(name);
 if(!f){log[name]='NOT FOUND';continue;}
 var removed=[];
 for(const n of Array.from(f.children)){
  if(['tabbar','tabpill0','tabpill1','tabpill2','tabt0','tabt1','tabt2','tab1bg','tab2','tab2bg','tab1','tab1t','tab2t'].indexOf(n.name)>=0){removed.push(n.name);n.remove();}
 }
 tabbar3(f, active);
 log[name]={removed:removed, active:active};
}
return log;
