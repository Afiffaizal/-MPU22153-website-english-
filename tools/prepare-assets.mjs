import fs from 'node:fs';
import { loadImage, createCanvas } from '@napi-rs/canvas';
for (const name of ['clouds','landscape','paper']) {
 const source=await loadImage(`temp/reference/${name}.png`);
 const width=name==='paper'?700:1800;
 const canvas=createCanvas(width,Math.round(source.height*width/source.width));
 canvas.getContext('2d').drawImage(source,0,0,canvas.width,canvas.height);
 fs.writeFileSync(`public/assets/${name}.webp`,await canvas.encode('webp',70));
 if(name!=='paper') {const small=createCanvas(900,Math.round(source.height*900/source.width));small.getContext('2d').drawImage(source,0,0,small.width,small.height);fs.writeFileSync(`public/assets/${name}-small.webp`,await small.encode('webp',70));}
 console.log(name,fs.statSync(`public/assets/${name}.webp`).size);
}
