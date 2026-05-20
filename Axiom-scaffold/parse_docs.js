const fs = require('fs');
const path = require('path');

const draftsPath = path.join(__dirname, 'specs', 'notion-documentation-drafts.md');
const content = fs.readFileSync(draftsPath, 'utf8');

function parseRichText(text) {
  if (!text) return [];
  const result = [];
  // Tokenize **bold**, `code`, and plain text
  const regex = /(\*\*.*?\*\*|`.*?`|[^*`]+)/g;
  let match;
  while ((match = regex.exec(text)) !== null) {
    let part = match[0];
    if (part.startsWith('**') && part.endsWith('**')) {
      result.push({
        type: 'text',
        text: { content: part.slice(2, -2) },
        annotations: { bold: true }
      });
    } else if (part.startsWith('`') && part.endsWith('`')) {
      result.push({
        type: 'text',
        text: { content: part.slice(1, -1) },
        annotations: { code: true }
      });
    } else {
      result.push({
        type: 'text',
        text: { content: part }
      });
    }
  }
  return result.length > 0 ? result : [{ type: 'text', text: { content: text } }];
}

// Split the content by page headers
const pagesRaw = content.split(/## 🏛️ Page 1 : |## 🔐 Page 2 : |## 💰 Page 3 : |## 🛡️ Page 4 : /);

// pagesRaw[0] is the intro/title.
// pagesRaw[1] is Page 1
// pagesRaw[2] is Page 2
// pagesRaw[3] is Page 3
// pagesRaw[4] is Page 4

const pageTitles = [
  "🏛️ Architecture & Modèle de Données",
  "🔐 Authentification & Sécurité",
  "💰 Gestion des Cotisations, Cultes & Membres",
  "🛡️ Guide de Débogage & Assurance Qualité"
];

function parsePageToBlocks(rawText) {
  const lines = rawText.split('\n');
  const blocks = [];
  
  let inCodeBlock = false;
  let codeLanguage = '';
  let codeContent = [];
  
  let inCallout = false;
  let calloutEmoji = '💡';
  let calloutContent = [];

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].trim();
    
    // Code block handling
    if (line.startsWith('```')) {
      if (inCodeBlock) {
        // End of code block
        blocks.push({
          object: 'block',
          type: 'code',
          code: {
            rich_text: [{ type: 'text', text: { content: codeContent.join('\n') } }],
            language: codeLanguage || 'plain text'
          }
        });
        inCodeBlock = false;
        codeContent = [];
        codeLanguage = '';
      } else {
        // Start of code block
        inCodeBlock = true;
        codeLanguage = line.slice(3).trim();
        // Notion map some languages
        if (codeLanguage === 'powershell') codeLanguage = 'shell';
        if (codeLanguage === 'text') codeLanguage = 'plain text';
      }
      continue;
    }
    
    if (inCodeBlock) {
      // Keep original line spacing inside code block
      codeContent.push(lines[i]);
      continue;
    }

    // Callout handling
    if (line.startsWith('>')) {
      let calloutLine = line.slice(1).trim();
      if (calloutLine.startsWith('[!CAUTION]')) {
        inCallout = true;
        calloutEmoji = '🚨';
        continue;
      } else if (calloutLine.startsWith('[!IMPORTANT]')) {
        inCallout = true;
        calloutEmoji = '⚠️';
        continue;
      } else if (calloutLine.startsWith('[!NOTE]')) {
        inCallout = true;
        calloutEmoji = 'ℹ️';
        continue;
      } else if (calloutLine.startsWith('[!TIP]')) {
        inCallout = true;
        calloutEmoji = '💡';
        continue;
      }
      
      if (inCallout) {
        calloutContent.push(calloutLine);
      } else {
        // Simple quote block or fallback callout
        inCallout = true;
        calloutEmoji = '💡';
        calloutContent.push(calloutLine);
      }
      continue;
    } else {
      if (inCallout) {
        // End of callout block
        blocks.push({
          object: 'block',
          type: 'callout',
          callout: {
            rich_text: parseRichText(calloutContent.join('\n')),
            icon: { emoji: calloutEmoji }
          }
        });
        inCallout = false;
        calloutContent = [];
        calloutEmoji = '💡';
      }
    }

    if (line === '' || line === '---') {
      continue;
    }

    // Heading 2 (###)
    if (line.startsWith('### ')) {
      blocks.push({
        object: 'block',
        type: 'heading_2',
        heading_2: {
          rich_text: parseRichText(line.slice(4))
        }
      });
      continue;
    }

    // Heading 3 (####)
    if (line.startsWith('#### ')) {
      blocks.push({
        object: 'block',
        type: 'heading_3',
        heading_3: {
          rich_text: parseRichText(line.slice(5))
        }
      });
      continue;
    }

    // Bullet list items (* or -)
    if (line.startsWith('* ') || line.startsWith('- ')) {
      blocks.push({
        object: 'block',
        type: 'bulleted_list_item',
        bulleted_list_item: {
          rich_text: parseRichText(line.slice(2))
        }
      });
      continue;
    }

    // Numbered list items (e.g., 1. or 2.)
    if (/^\d+\.\s/.test(line)) {
      const match = line.match(/^(\d+)\.\s(.*)/);
      blocks.push({
        object: 'block',
        type: 'numbered_list_item',
        numbered_list_item: {
          rich_text: parseRichText(match[2])
        }
      });
      continue;
    }

    // Regular paragraph
    blocks.push({
      object: 'block',
      type: 'paragraph',
      paragraph: {
        rich_text: parseRichText(lines[i].trim())
      }
    });
  }

  // Handle unclosed callout at EOF
  if (inCallout) {
    blocks.push({
      object: 'block',
      type: 'callout',
      callout: {
        rich_text: parseRichText(calloutContent.join('\n')),
        icon: { emoji: calloutEmoji }
      }
    });
  }

  return blocks;
}

for (let idx = 1; idx <= 4; idx++) {
  const rawText = pagesRaw[idx] || "";
  const blocks = parsePageToBlocks(rawText);
  const outPath = path.join(__dirname, 'specs', `page${idx}_blocks.json`);
  fs.writeFileSync(outPath, JSON.stringify(blocks, null, 2), 'utf8');
  console.log(`Successfully wrote ${blocks.length} blocks for Page ${idx} to ${outPath}`);
}
