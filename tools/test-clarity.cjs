const vm = require('node:vm');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const code = fs.readFileSync(__dirname + '/../js/clarity-consent.js', 'utf8');
function run({path='/',query='',stored=null,external=false}={}) {
 const elements=[], events={}, cookies=[];
 const make=tag=>({tag,focus(){},children:[],dataset:{},setAttribute(k,v){this[k]=v},appendChild(e){this.children.push(e);elements.push(e)},append(...es){es.forEach(e=>this.appendChild(e))},addEventListener(k,fn){this[k]=fn},remove(){this.removed=true},querySelector(){return {focus(){}}}});
 const head=make('head'),body=make('body');let value=stored,reloads=0;
 const document={currentScript:{dataset:{project:'abc123',consent:external?'external':'',paths:'/,/index.php'},src:'https://example.com/js/clarity-consent.js'},head,body,documentElement:{lang:'sk'},createElement:make,querySelector(){return null},get cookie(){return ''},set cookie(c){cookies.push(c)}};
 const window={addEventListener(k,fn){events[k]=fn}};
 const location={pathname:path,search:query,hostname:'sub.example.com',reload(){reloads++}};
 vm.runInNewContext(code,{document,window,location,localStorage:{getItem(){return value},setItem(k,v){value=v}},URL,URLSearchParams,Date});
 return {elements,events,window,body,cookies,get reloads(){return reloads},get value(){return value},scripts:()=>elements.filter(e=>e.tag==='script')};
}
let s=run();assert.equal(s.scripts().length,0);let accept=s.elements.find(e=>e.textContent==='Povoliť analytiku');accept.click();assert.equal(s.scripts().length,1);assert.equal(s.scripts()[0].src,'https://www.clarity.ms/tag/abc123');assert.equal(s.body['data-clarity-mask'],'true');assert.equal(s.window.clarity.q[0][1].ad_Storage,'denied');
s.elements.find(e=>e.textContent==='Nastavenia analytiky').click();s.elements.filter(e=>e.textContent==='Odmietnuť').at(-1).click();assert.equal(s.reloads,1);assert.equal(JSON.parse(s.value).granted,false);assert.ok(s.cookies.some(c=>c.includes('Domain=.example.com')));
s=run();s.elements.find(e=>e.textContent==='Odmietnuť').click();assert.equal(s.scripts().length,0);
for(const path of ['/login.php','/calculator.php','/admin.php'])assert.equal(run({path}).elements.length,0);
assert.equal(run({query:'?token=private'}).elements.length,0);
s=run({stored:JSON.stringify({granted:true,expires:Date.now()-1})});assert.equal(s.scripts().length,0);
s=run({stored:JSON.stringify({granted:true,expires:Date.now()+10000})});assert.equal(s.scripts().length,1);
s=run({external:true});assert.equal(s.scripts().length,0);s.events['site:analytics-consent']({detail:true});s.events['site:analytics-consent']({detail:true});assert.equal(s.scripts().length,1);s.events['site:analytics-consent']({detail:false});assert.equal(s.reloads,1);
console.log('PASS: consent gating, project ID, masking, revocation, cookies, expiry, duplicate prevention, private paths and tokens.');

