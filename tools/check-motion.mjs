import { chromium } from 'playwright';
const browser = await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
const page = await browser.newPage({viewport:{width:1440,height:1050},reducedMotion:'no-preference'});
const assert=(condition,label)=>{if(!condition)throw new Error(label);};
await page.goto('http://127.0.0.1:4173',{waitUntil:'networkidle'});
const cloud=page.locator('.clouds-back');
const transform=()=>cloud.evaluate(el=>getComputedStyle(el).transform);
const before=await transform(); await page.waitForTimeout(1200);
assert(before!==await transform(),'Cloud must move');
assert(await page.locator('.motion-toggle').count()===0,'No pause control should remain');
await page.screenshot({path:'temp/checks/animated-hero-desktop.png'});
await page.locator('#b').evaluate(el=>el.scrollIntoView({behavior:'instant'}));
await page.waitForTimeout(100);
assert(await cloud.evaluate(el=>getComputedStyle(el).animationPlayState)==='running','Cloud animation must keep running offscreen');
await page.emulateMedia({reducedMotion:'reduce'});
assert(await cloud.evaluate(el=>getComputedStyle(el).animationName)==='none','Reduced motion must disable animation');
await page.emulateMedia({reducedMotion:'no-preference'});
for(const width of [320,390,768,1024]){
 await page.setViewportSize({width,height:844});
 await page.goto('http://127.0.0.1:4173',{waitUntil:'networkidle'});
 assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`Overflow at ${width}`);
 const titleFits=await page.locator('h1').evaluate(el=>{const r=el.getBoundingClientRect();return r.right<=innerWidth&&r.left>=0&&el.scrollWidth<=el.clientWidth;});
 assert(titleFits,`Hero title clipped at ${width}`);
 if(width===390)await page.screenshot({path:'temp/checks/animated-hero-mobile.png'});
}
await browser.close();
console.log('PASS: continuous cloud movement, no pause button, offscreen playback, reduced motion, four responsive widths and title fit.');
