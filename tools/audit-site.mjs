import lighthouse from 'lighthouse';
import { launch } from 'chrome-launcher';
import fs from 'node:fs';
const chrome=await launch({chromePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',chromeFlags:['--headless','--no-sandbox']});
try {
 const result=await lighthouse(process.argv[2]||'http://127.0.0.1:4173',{port:chrome.port,output:'json',onlyCategories:['performance','accessibility','best-practices','seo']});
 fs.writeFileSync('temp/checks/lighthouse.json',result.report);
 console.log(JSON.stringify({scores:Object.fromEntries(Object.entries(result.lhr.categories).map(([k,v])=>[k,v.score])),issues:Object.values(result.lhr.audits).filter(a=>a.score!==null&&a.score<1).map(a=>({id:a.id,title:a.title,value:a.displayValue}))},null,2));
} finally {try {await chrome.kill();} catch(error) {console.warn('Chrome temporary-profile cleanup:',error.message);}}
