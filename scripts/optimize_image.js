// One-shot image optimizer. Usage: node scripts/optimize_image.js
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

async function optimize() {
  const inputPath = path.join(__dirname, '..', 'assets', 'images', 'splash_mascots.png');
  const outputPath = inputPath; // overwrite in place

  const before = fs.statSync(inputPath).size;
  const metadata = await sharp(inputPath).metadata();
  console.log(`Before: ${metadata.width}x${metadata.height}, ${(before / 1024).toFixed(0)} KB`);

  // Resize (max 1200px on longest edge, no upscale) + PNG quantize for max compression
  const buffer = await sharp(inputPath)
    .resize({ width: 1200, height: 1200, fit: 'inside', withoutEnlargement: true })
    .png({ quality: 80, compressionLevel: 9, palette: true })
    .toBuffer();

  fs.writeFileSync(outputPath, buffer);

  const after = fs.statSync(outputPath).size;
  const outMeta = await sharp(outputPath).metadata();
  console.log(`After:  ${outMeta.width}x${outMeta.height}, ${(after / 1024).toFixed(0)} KB`);
  console.log(`Saved:  ${((1 - after / before) * 100).toFixed(1)}%`);
}

optimize().catch((e) => { console.error(e); process.exit(1); });
