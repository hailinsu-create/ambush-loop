from playwright.sync_api import sync_playwright
import json
cdp='ws://127.0.0.1:45153/devtools/browser/2fe75df8-11af-437c-ae38-df82d05b1f7b'
script='''(() => {
window.__pr15AudioProbe={contexts:[],taps:[]};
const Original=window.AudioContext;
window.AudioContext=new Proxy(Original,{construct(target,args){const ctx=Reflect.construct(target,args);window.__pr15AudioProbe.contexts.push(ctx);return ctx;}});
const originalConnect=AudioNode.prototype.connect;
const tapped=new WeakSet();
AudioNode.prototype.connect=function(destination,...args){
const result=originalConnect.call(this,destination,...args);
if(destination===this.context.destination&&!tapped.has(this)){tapped.add(this);const analyser=this.context.createAnalyser();analyser.fftSize=2048;originalConnect.call(this,analyser);window.__pr15AudioProbe.taps.push(analyser);}
return result;
};
window.__pr15AudioSnapshot=()=>({contexts:window.__pr15AudioProbe.contexts.map(c=>({state:c.state,sampleRate:c.sampleRate,currentTime:c.currentTime})),taps:window.__pr15AudioProbe.taps.map(a=>{const d=new Float32Array(a.fftSize);a.getFloatTimeDomainData(d);return {rms:Math.sqrt(d.reduce((s,x)=>s+x*x,0)/d.length),peak:Math.max(...d.map(Math.abs))};}),userActivation:{active:navigator.userActivation.isActive,ever:navigator.userActivation.hasBeenActive}});
})();'''
with sync_playwright() as p:
 b=p.chromium.connect_over_cdp(cdp);assert len(b.contexts)==1;page=next(x for x in b.contexts[0].pages if x.url.startswith("http://127.0.0.1:12784/"));page.add_init_script(script);page.reload(wait_until='load');page.wait_for_function("document.getElementById('status').style.display==='none'",timeout=45000);print(json.dumps({'before_gesture':page.evaluate('window.__pr15AudioSnapshot()')}))
 print(json.dumps({'actual_exit':0,'probe':'external pre-navigation AudioContext/analyser tee, no gain/output changes; not performance instrumentation','browser_contexts':len(b.contexts),'init_script':script}))
