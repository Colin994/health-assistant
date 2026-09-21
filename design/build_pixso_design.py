#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Build health-assistant app screens in Pixso via MCP eval_script. v2: fixed layout overlaps."""
import json, re, urllib.request, os, sys

URL = "http://127.0.0.1:3667/mcp"
PAGE_ID = "16:1"
TIMEOUT = int(os.environ.get("MCP_TIMEOUT", "180"))

def post(payload, sid=None):
    req = urllib.request.Request(URL, data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json",
                 "Accept": "application/json, text/event-stream"})
    if sid:
        req.add_header("Mcp-Session-Id", sid)
    resp = urllib.request.urlopen(req, timeout=TIMEOUT)
    sid_out = resp.headers.get("Mcp-Session-Id")
    raw = resp.read().decode("utf-8")
    if not raw.strip():
        return {}, sid_out
    m = re.search(r"^data: (.+)$", raw, re.M)
    body = m.group(1) if m else next((l for l in raw.splitlines() if l.lstrip().startswith("{")), raw)
    return json.loads(body), sid_out

def call_tool(name, args):
    _, sid = post({"jsonrpc":"2.0","id":1,"method":"initialize","params":{
        "protocolVersion":"2024-11-05","capabilities":{},
        "clientInfo":{"name":"zcode","version":"1.0"}}})
    post({"jsonrpc":"2.0","method":"notifications/initialized"}, sid)
    result, _ = post({"jsonrpc":"2.0","id":2,"method":"tools/call",
        "params":{"name":name,"arguments":args}}, sid)
    if result.get("isError"):
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:1500])
    texts = [c["text"] for c in result["result"]["content"] if c.get("type") == "text"]
    return "\n".join(texts)

JS_COMMON = r"""
function hex(h){return {r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255};}
var C={primary:'#27C3B0',text:'#28332F',white:'#FFFFFF',fa:'#FAFAFA',p10:'#E9F9F7',p5:'#F4FCFB',sec:'#949997',ter:'#BFC2C1',danger:'#FF4747'};
function paint(c,o){return [{type:'SOLID',color:hex(c),opacity:(o==null?1:o)}];}
var F_CN='HarmonyOS Sans SC', F_EN='Poppins';
var STYLE={'Regular':'Regular','Medium':'Medium','Semi Bold':'Bold','Bold':'Bold'};
var FONTS=[F_CN+'|Regular',F_CN+'|Medium',F_CN+'|Bold',F_EN+'|Regular',F_EN+'|Medium',F_EN+'|Bold'];
for(var fi=0;fi<FONTS.length;fi++){var ff=FONTS[fi].split('|');try{await pixso.loadFontAsync({family:ff[0],style:ff[1]});}catch(e){}}
var page=pixso.getNodeById('%PAGE_ID%');
function rect(f,name,w,h,x,y,c,o,rad){var r=pixso.createRectangle();r.name=name;r.resize(w,h);r.x=x;r.y=y;r.fills=c?paint(c,o):[];if(rad)r.cornerRadius=rad;f.appendChild(r);return r;}
function circ(f,name,d,x,y,c,o){var e=pixso.createEllipse();e.name=name;e.resize(d,d);e.x=x;e.y=y;e.fills=c?paint(c,o):[];f.appendChild(e);return e;}
function txt(f,name,str,size,style,c,x,y,w,lh,fam){var t=pixso.createText();t.name=name;t.characters=str;
 try{t.fontName={family:fam||F_CN,style:STYLE[style]||'Regular'};}catch(e){}
 t.fontSize=size;t.fills=paint(c);
 var lines=String(str).split('\n').length; var lineH=lh||Math.round(size*1.4);
 t.resize(w,lineH*lines);t.x=x;t.y=y;t.textAlignHorizontal='LEFT';
 try{t.lineHeight={value:lineH,unit:'PIXELS'};}catch(e){}
 f.appendChild(t);return t;}
function line(f,name,x1,y1,x2,y2,c,stroke){var l=pixso.createLine();l.name=name;l.x=Math.min(x1,x2);l.y=Math.min(y1,y2);l.resize(Math.abs(x2-x1)||1,Math.abs(y2-y1)||1);l.strokes=[{type:'SOLID',color:hex(c)}];try{l.strokeWeight=stroke||2;}catch(e){}f.appendChild(l);return l;}
function scr(name,x){var fr=pixso.createFrame();fr.name=name;fr.resize(390,844);fr.x=x;fr.y=0;fr.fills=paint(C.white);page.appendChild(fr);return fr;}
// status bar: time on the left, signal/wifi/battery on the right, home indicator at bottom
function statusbar(f){
 txt(f,'time','9:41',15,'Bold','#000000',27,14,54,20,F_EN);
 for(var i=0;i<4;i++){circ(f,'sig',4,289+i*7,20,'#000000',1);}
 circ(f,'wifi1',5,320,19,'#000000',1);circ(f,'wifi2',3.4,321.3,20.8,'#000000',1);circ(f,'wifi3',2,322.3,22.2,'#000000',1);
 var b=rect(f,'battery',25,13,330,17,null,0,4);b.strokes=[{type:'SOLID',color:hex('#000000')}];try{b.strokeWeight=1.2;}catch(e){}
 rect(f,'battfill',17,8,332.5,19.5,'#000000',1,2);
 rect(f,'home',134,5,128,839,null,1,0);
}
// nav row: back arrow on the left, title after it (no overlap)
function navbar(f,title){
 txt(f,'back','‹',26,'Regular',C.text,28,64,30,30,F_EN);
 txt(f,'nav',title,16,'Semi Bold',C.text,68,70,220,22);
}
function pillBtn(f,label,x,y,w,h,active,txtSize){
 var b=rect(f,'btn-'+label,w,h,x,y,active?C.primary:C.p10,1,100);
 txt(f,'bt-'+label,label,txtSize||14,active?'Semi Bold':'Medium',active?C.white:C.primary,x+16,y+(h-(txtSize||14)*1.4)/2,w-32,Math.round((txtSize||14)*1.4));
 return b;}
"""

SCREENS = []

# ---------------- Screen 1: 首启-价值页 ----------------
SCREENS.append(("01 首启-价值", r"""
var f=scr('01 首启-价值', 0); statusbar(f);
txt(f,'skip','跳过',14,'Regular',C.sec,318,74,50,20);
var cx=195, cy=290;
circ(f,'r3',300,cx-150,cy-150,C.primary,0.06);
circ(f,'r2',220,cx-110,cy-110,C.primary,0.12);
circ(f,'r1',140,cx-70,cy-70,C.primary,0.2);
circ(f,'dot',84,cx-42,cy-42,C.primary,1);
txt(f,'doticon','◷',34,'Regular',C.white,cx-17,cy-20,34,40,F_EN);
// floating notification card over the rings
var nb=rect(f,'nb',204,58,cx-152,cy+52,C.white,1,16);
txt(f,'nbt','坐了 55 分钟啦',13,'Semi Bold',C.text,cx-136,cy+66,160,18);
txt(f,'nbs','起来活动一下吧',11,'Regular',C.sec,cx-136,cy+86,160,16);
txt(f,'title','最懂你工作节奏的\n健康提醒',24,'Semi Bold',C.text,32,500,326,36);
var rows=[['时机准','手环判断你真的久坐了，不是定时闹钟'],
          ['懂你','结合你的状况，说你听得进去的话'],
          ['零负担','1 分钟拉伸，不用换衣服不用打卡']];
for(var i=0;i<3;i++){var y=600+i*42;
 circ(f,'pt',8,32,y+5,C.primary,1);
 txt(f,'pt'+i,rows[i][0],14,'Semi Bold',C.text,50,y,60,20);
 txt(f,'pd'+i,rows[i][1],12,'Regular',C.sec,118,y+2,208,18);}
var dots=[C.primary,C.ter,C.ter];
for(var i=0;i<3;i++){circ(f,'dot'+i,i==0?8:6,171+i*16,736,dots[i],1);}
pillBtn(f,'开始使用',32,772,326,56,true,16);
"""))

# ---------------- Screen 2: 首启-健康标签 ----------------
SCREENS.append(("02 首启-健康标签", r"""
var f=scr('02 首启-健康标签', 446); statusbar(f);
navbar(f,'你的身体状况');
txt(f,'sub','让我们更懂你 · 可随时修改',13,'Regular',C.sec,32,104,260,18);
var tags=[['颈椎不适',true],['肩颈僵硬',false],['腰部劳损',false],['眼疲劳',false]];
for(var i=0;i<4;i++){var x=32+(i%2)*166, y=144+Math.floor(i/2)*96, sel=tags[i][1];
 rect(f,'tag'+i,150,84,x,y,sel?C.primary:C.fa,1,16);
 txt(f,'ttn'+i,tags[i][0],15,sel?'Semi Bold':'Medium',sel?C.white:C.text,x+20,y+18,110,22);
 if(sel){circ(f,'ck',20,x+20,y+46,C.white,1);txt(f,'cki','✓',12,'Bold',C.primary,x+27,y+50,10,14,F_EN);}
 else{txt(f,'ttd'+i,'工作中提醒',11,'Regular',C.ter,x+20,y+50,100,16);}}
rect(f,'only',326,48,32,338,C.fa,1,100);
circ(f,'oco',18,46,353,C.p5,1);
txt(f,'oct','只是久坐，没特殊不适',14,'Medium',C.text,74,350,240,20);
rect(f,'preview',326,110,32,404,C.p10,1,16);
txt(f,'pvh','已选「颈椎不适」，提醒会像这样：',12,'Semi Bold',C.text,48,420,290,18);
txt(f,'pvb','“低头一小时了，抬头看看远处吧——\n顺便做个收下巴，30 秒”',13,'Regular',C.text,48,444,290,22);
pillBtn(f,'下一步',32,772,326,56,true,16);
"""))

# ---------------- Screen 3: 首启-权限引导 ----------------
SCREENS.append(("03 首启-权限引导", r"""
var f=scr('03 首启-权限引导', 892); statusbar(f);
navbar(f,'连接你的健康数据');
txt(f,'sub','两步授权，之后就不需要再管了',13,'Regular',C.sec,32,104,280,18);
rect(f,'perm1',326,120,32,144,C.fa,1,16);
circ(f,'ic1',44,52,168,C.p10,1);txt(f,'ic1t','♥',18,'Regular',C.primary,68,182,20,24,F_EN);
txt(f,'p1t','健康数据',15,'Semi Bold',C.text,108,162,120,22);
txt(f,'p1d','读取活动与久坐记录，\n仅此而已。',12,'Regular',C.sec,108,188,124,18);
pillBtn(f,'去授权',240,168,102,36,true,13);
rect(f,'perm2',326,120,32,280,C.fa,1,16);
circ(f,'ic2',44,52,304,C.p10,1);txt(f,'ic2t','◔',18,'Regular',C.primary,68,318,20,24,F_EN);
txt(f,'p2t','通知',15,'Semi Bold',C.text,108,298,120,22);
txt(f,'p2d','提醒的唯一通道，\n可随时在系统中关闭。',12,'Regular',C.sec,108,324,124,18);
pillBtn(f,'去开启',240,304,102,36,true,13);
txt(f,'priv','我们只读取活动与久坐记录，不采集心率、睡眠等\n敏感数据；数据仅用于为你生成提醒。',11,'Regular',C.ter,32,428,326,18);
pillBtn(f,'进入应用',32,772,326,56,true,16);
"""))

# ---------------- Screen 4: 今日（首页） ----------------
SCREENS.append(("04 今日", r"""
var f=scr('04 今日', 1338); statusbar(f);
txt(f,'title','今日',24,'Semi Bold',C.text,32,70,120,32);
circ(f,'wface',34,32,120,C.p10,1);txt(f,'wicon','◔',15,'Regular',C.primary,44,129,16,18,F_EN);
txt(f,'src','Apple Watch · 数据更新 5 分钟前',12,'Regular',C.sec,74,128,280,18);
rect(f,'countcard',326,140,32,164,C.white,1,24);
txt(f,'ccl','今天已提醒',13,'Regular',C.sec,60,192,100,18);
txt(f,'cnum','3',40,'Semi Bold',C.text,60,212,60,52,F_EN);
txt(f,'crl','和你一起完成了',13,'Regular',C.sec,176,192,96,18);
txt(f,'crn','2',40,'Semi Bold',C.primary,176,212,60,52,F_EN);
circ(f,'cbr',44,276,236,C.p10,1);txt(f,'cbt','💪',16,'Regular',C.primary,290,251,20,22,F_EN);
txt(f,'nel','下次提醒预估',13,'Semi Bold',C.text,32,332,140,18);
txt(f,'nev','如果你持续坐着，约 14:30 会提醒你',12,'Regular',C.sec,32,354,290,18);
rect(f,'recent',326,60,32,390,C.p10,1,16);
txt(f,'rft','✓ 颈部侧拉伸 · 11:20 · 完成',13,'Medium',C.text,52,411,260,18);
rect(f,'tabbar',342,62,24,756,C.white,1,31);
var tb=pixso.getNodeById(f.children[f.children.length-1].id);
tb.strokes=[{type:'SOLID',color:hex(C.p5)}];try{tb.strokeWeight=1;}catch(e){}
rect(f,'tab1',155,54,28,760,C.primary,1,26);
txt(f,'tab1t','今日',12,'Semi Bold',C.white,86,783,40,17);
rect(f,'tab2bg',155,54,207,760,null,0,26);
txt(f,'tab2t','我的',12,'Medium',C.sec,264,783,40,17);
"""))

# ---------------- Screen 5: 拉伸页 ----------------
SCREENS.append(("05 拉伸页", r"""
var f=scr('05 拉伸页', 1784); statusbar(f);
txt(f,'close','✕',20,'Regular',C.text,342,66,24,24,F_EN);
rect(f,'aibanner',326,88,32,88,C.p10,1,16);
txt(f,'ai','坐了一个多小时啦，脖子该抗议了——\n起来倒杯水，顺便做个颈部拉伸？',14,'Medium',C.text,48,104,300,24);
txt(f,'ais','来自你的健康助手',10,'Regular',C.ter,48,154,160,14);
txt(f,'st','为你准备的 1 分钟',16,'Semi Bold',C.text,32,198,220,22);
txt(f,'skip','跳过这个 ›',12,'Regular',C.primary,286,202,72,17);
var cards=[['颈部侧拉伸','40 秒 · 每侧 2 次',true],['收下巴','30 秒 · 2 次',false],['肩部画圈','60 秒',false]];
for(var i=0;i<3;i++){var x=32+i*113;
 rect(f,'ac'+i,100,208,x,234,C.white,1,16);
 rect(f,'im'+i,84,104,x+8,242,C.p5,1,12);
 circ(f,'hd'+i,20,x+40,268,C.primary,i==0?1:0.35);
 line(f,'torso'+i,x+49,290,x+49,318,C.primary,i==0?3:2);
 line(f,'arml'+i,x+49,298,x+38,312,C.primary,2);
 line(f,'armr'+i,x+49,298,x+60,312,C.primary,2);
 txt(f,'ct'+i,cards[i][0],12,'Semi Bold',C.text,x+8,356,84,17);
 txt(f,'cd'+i,cards[i][1],10,'Regular',C.sec,x+8,376,88,14);
 if(i==0){rect(f,'sel',48,20,x+8,242,C.primary,1,100);txt(f,'selt','推荐',10,'Semi Bold',C.white,x+20,247,26,14);}}
pillBtn(f,'✓ 做完了',32,668,326,52,true,15);
pillBtn(f,'⏱ 稍后提醒',32,732,156,44,false,13);
pillBtn(f,'☾ 今天别提醒',198,732,160,44,false,13);
txt(f,'never','✕ 别再提醒这类',12,'Regular',C.ter,125,788,140,17);
"""))

# ---------------- Screen 6: 动作详情 ----------------
SCREENS.append(("06 动作详情", r"""
var f=scr('06 动作详情', 2230); statusbar(f);
navbar(f,'颈部侧拉伸');
txt(f,'dur','40 秒',13,'Medium',C.primary,322,72,50,18);
rect(f,'illu',326,290,32,110,C.p5,1,24);
circ(f,'ring',160,115,150,C.primary,0.12);
circ(f,'head',52,194,160,C.primary,1);
line(f,'neck',220,212,220,258,C.primary,6);
line(f,'shoulder',160,262,280,262,C.primary,6);
line(f,'arm',178,262,166,308,C.primary,4);
line(f,'arm2',262,262,274,308,C.primary,4);
line(f,'arrow',244,168,280,184,C.text,3);
circ(f,'arhead',6,276,178,C.text,1);
txt(f,'tip','缓慢侧向右肩',11,'Medium',C.sec,136,320,118,16);
txt(f,'step','缓慢将头侧向右肩，感到左侧颈部\n轻微拉伸即可，不要用力下压。',14,'Regular',C.text,32,428,326,24);
txt(f,'reps','× 每侧 2 次',13,'Medium',C.sec,32,486,120,18);
circ(f,'tring',96,147,548,C.p10,1);
circ(f,'tring2',76,157,558,C.primary,1);
txt(f,'tnum','0:40',22,'Semi Bold',C.text,171,576,60,28,F_EN);
txt(f,'tlab','剩余时间',10,'Regular',C.ter,163,608,70,14);
pillBtn(f,'▶ 开始',32,700,326,56,true,16);
txt(f,'alt','不做了，返回 ›',12,'Regular',C.ter,140,772,120,17);
"""))

# ---------------- Screen 7: 我的 ----------------
SCREENS.append(("07 我的", r"""
var f=scr('07 我的', 2676); statusbar(f);
txt(f,'title','我的',24,'Semi Bold',C.text,32,70,120,32);
txt(f,'secl','我的健康标签',13,'Semi Bold',C.sec,32,126,160,18);
rect(f,'tagcard',326,72,32,152,C.white,1,16);
pillBtn(f,'颈椎不适',52,170,92,32,true,12);
pillBtn(f,'眼疲劳',152,170,72,32,false,12);
txt(f,'tghint','修改标签会即时影响下次提醒',11,'Regular',C.ter,32,232,280,16);
txt(f,'sec2','设置',13,'Semi Bold',C.sec,32,252,120,18);
var rows=[['提醒设置','密度 · 静音时段 · 测试提醒'],['隐私与数据说明','我们读取什么、存在哪'],['关于','版本 0.1.0']];
for(var i=0;i<3;i++){var y=278+i*72;
 rect(f,'row'+i,326,60,32,y,C.white,1,16);
 txt(f,'rt'+i,rows[i][0],14,'Semi Bold',C.text,52,y+12,150,20);
 txt(f,'rd'+i,rows[i][1],11,'Regular',C.ter,52,y+34,240,16);
 txt(f,'chev'+i,'›',18,'Regular',C.ter,332,y+16,20,24,F_EN);}
rect(f,'tabbar',342,62,24,756,C.white,1,31);
var tb=pixso.getNodeById(f.children[f.children.length-1].id);
tb.strokes=[{type:'SOLID',color:hex(C.p5)}];try{tb.strokeWeight=1;}catch(e){}
rect(f,'tab1bg',155,54,28,760,null,0,26);
txt(f,'tab1t','今日',12,'Medium',C.sec,86,783,40,17);
rect(f,'tab2',155,54,207,760,C.primary,1,26);
txt(f,'tab2t','我的',12,'Semi Bold',C.white,264,783,40,17);
"""))

# ---------------- Screen 8: 提醒设置 ----------------
SCREENS.append(("08 提醒设置", r"""
var f=scr('08 提醒设置', 3122); statusbar(f);
navbar(f,'提醒设置');
rect(f,'denCard',326,110,32,116,C.white,1,16);
txt(f,'dt','提醒密度',14,'Semi Bold',C.text,52,132,120,20);
var segs=[['更严格','45 分钟',false],['标准','55 分钟',true],['更宽松','75 分钟',false]];
for(var i=0;i<3;i++){var x=52+i*98, sel=segs[i][2];
 rect(f,'seg'+i,90,48,x,158,sel?C.primary:C.fa,1,12);
 txt(f,'sgt'+i,segs[i][0],12,sel?'Semi Bold':'Medium',sel?C.white:C.text,x+10,166,70,17);
 txt(f,'sgd'+i,segs[i][1],10,'Regular',sel?C.white:C.ter,x+10,184,70,14);}
rect(f,'quietCard',326,84,32,244,C.white,1,16);
txt(f,'qt','静音时段',14,'Semi Bold',C.text,52,260,120,20);
txt(f,'qv','22:00 – 07:00',13,'Regular',C.sec,52,284,140,18);
rect(f,'sw1',51,31,291,262,C.primary,1,100);circ(f,'kn1',27,303,265,C.white,1);
rect(f,'noonCard',326,84,32,340,C.white,1,16);
txt(f,'nt','午休静音',14,'Semi Bold',C.text,52,356,120,20);
txt(f,'nv','12:30 – 13:30 不提醒',12,'Regular',C.sec,52,380,170,17);
rect(f,'sw2',51,31,291,356,C.primary,1,100);circ(f,'kn2',27,303,359,C.white,1);
txt(f,'auton','自动降频：负面反馈过多时会自动放宽提醒。\n当前：标准（55 分钟 · 间隔 90 分钟）',11,'Regular',C.ter,32,444,326,18);
rect(f,'testbtn',326,52,32,496,C.p10,1,100);
txt(f,'tb','发一条试试 ›',14,'Semi Bold',C.primary,136,511,140,20);
"""))

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "build"
    only = sys.argv[2:]
    if mode in ("clean", "rebuild"):
        out = call_tool("eval_script", {"script":
            "const p=pixso.getNodeById('%s'); const rm=[];"
            "for(const n of Array.from(p.children)){rm.push(n.name);n.remove();}"
            "return {removed:rm};" % PAGE_ID})
        print("clean:", out)
        if mode == "clean":
            return
    for name, js in SCREENS:
        if only and not any(o in name for o in only):
            continue
        script = (JS_COMMON.replace("%PAGE_ID%", PAGE_ID)
                  + "try{\n" + js + "\n}catch(e){return {err:String(e).slice(0,300), stack:(e&&e.stack?e.stack.slice(0,300):'')};}\nreturn {ok:1};")
        out = call_tool("eval_script", {"script": script})
        print("==", name, "==>", out[:160])

if __name__ == "__main__":
    main()
