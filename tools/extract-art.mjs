import fs from 'node:fs';
import { createCanvas, DOMMatrix, ImageData, Path2D } from '@napi-rs/canvas';
Object.assign(globalThis, { DOMMatrix, ImageData, Path2D });
const { getDocument, OPS } = await import('pdfjs-dist/legacy/build/pdf.mjs');
const doc = await getDocument({data:new Uint8Array(fs.readFileSync(process.argv[2]))}).promise;
const page = await doc.getPage(1);
const viewport = page.getViewport({scale:1});
await page.render({canvasContext:createCanvas(viewport.width,viewport.height).getContext('2d'),viewport}).promise;
const ops = await page.getOperatorList();
fs.mkdirSync('temp/extracted',{recursive:true});
for(let i=0;i<ops.fnArray.length;i++) {
 if(ops.fnArray[i]!==OPS.paintImageXObject) continue;
 const id=ops.argsArray[i][0]; const obj=await new Promise(resolve=>page.objs.get(id,resolve));
 console.log(id,obj.width,obj.height,obj.kind);
 const canvas=createCanvas(obj.width,obj.height), ctx=canvas.getContext('2d');
 if(obj.bitmap) ctx.drawImage(obj.bitmap,0,0);
 else {const rgba=new Uint8ClampedArray(obj.width*obj.height*4);for(let p=0;p<obj.width*obj.height;p++){if(obj.kind===2){rgba.set(obj.data.slice(p*3,p*3+3),p*4);rgba[p*4+3]=255;}else if(obj.kind===3)rgba.set(obj.data.slice(p*4,p*4+4),p*4);}ctx.putImageData(new ImageData(rgba,obj.width,obj.height),0,0);}
 fs.writeFileSync(`temp/extracted/${id}.png`,canvas.toBuffer('image/png'));
}
