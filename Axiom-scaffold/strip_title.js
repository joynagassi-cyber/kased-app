const fs = require('fs');
const path = require('path');

for (let idx = 1; idx <= 4; idx++) {
  const inPath = path.join(__dirname, 'specs', `page${idx}_blocks.json`);
  const outPath = path.join(__dirname, 'specs', `page${idx}_blocks_final.json`);
  
  if (fs.existsSync(inPath)) {
    const blocks = JSON.parse(fs.readFileSync(inPath, 'utf8'));
    // Strip the first block (redundant page title)
    blocks.shift();
    fs.writeFileSync(outPath, JSON.stringify(blocks, null, 2), 'utf8');
    console.log(`Page ${idx}: stripped first block, saved ${blocks.length} blocks to ${outPath}`);
  }
}
