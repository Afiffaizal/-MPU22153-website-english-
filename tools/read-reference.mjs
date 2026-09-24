import fs from 'node:fs';
import { createCanvas, DOMMatrix, ImageData, Path2D } from '@napi-rs/canvas';
Object.assign(globalThis, { DOMMatrix, ImageData, Path2D });
const { getDocument } = await import('pdfjs-dist/legacy/build/pdf.mjs');
const doc = await getDocument({ data: new Uint8Array(fs.readFileSync(process.argv[2])), useSystemFonts: true }).promise;
fs.mkdirSync('temp/reference', { recursive: true });
console.log('Pages:', doc.numPages);
for (let i = 1; i <= doc.numPages; i++) {
  const page = await doc.getPage(i);
  const viewport = page.getViewport({ scale: 0.8 });
  const canvas = createCanvas(viewport.width, viewport.height);
  await page.render({ canvasContext: canvas.getContext('2d'), viewport }).promise;
  fs.writeFileSync(`temp/reference/page-${i}.png`, canvas.toBuffer('image/png'));
  console.log(i, (await page.getTextContent()).items.map(x => x.str).join(' ').slice(0, 3500));
}
