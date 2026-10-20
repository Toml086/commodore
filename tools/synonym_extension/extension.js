const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

// Zerlegt Bezeichner in Teilwörter: snake_case, camelCase, PascalCase, HTTPServer ...
const TOKEN = /\p{Lu}+(?!\p{Ll})|\p{Lu}?\p{Ll}+|\p{N}+/gu;

let wordsFile;

// Liest words.json bei jedem Hover neu ein, Änderungen wirken also sofort.
function buildMap() {
  const map = new Map();
  let groups = [];
  try {
    groups = JSON.parse(fs.readFileSync(wordsFile, 'utf8'));
  } catch (err) {
    return map;
  }
  for (const group of groups) {
    for (const word of group) {
      const key = word.toLowerCase();
      const others = group.filter((w) => w.toLowerCase() !== key);
      map.set(key, [...(map.get(key) ?? []), ...others]);
    }
  }
  return map;
}

function activate(context) {
  wordsFile = path.join(context.extensionPath, 'words.json');

  const provider = vscode.languages.registerHoverProvider('*', {
    provideHover(document, position) {
      const wordRange = document.getWordRangeAtPosition(position, /[\p{L}\p{N}_]+/u);
      if (!wordRange) return undefined;

      const text = document.getText(wordRange);
      const base = document.offsetAt(wordRange.start);
      const cursor = document.offsetAt(position);

      // 1. Ganzer Bezeichner (z.B. "max_rows") hat Vorrang
      const wholeHints = buildMap().get(text.toLowerCase());
      if (wholeHints && wholeHints.length > 0) {
        return new vscode.Hover(`**Synonym:** ${wholeHints.join(', ')}`, wordRange);
      }

      // 2. Sonst Teilwörter (z.B. "row" in "cursor_row")
      for (const m of text.matchAll(TOKEN)) {
        const start = base + m.index;
        const end = start + m[0].length;
        if (cursor < start || cursor >= end) continue;

        const hints = buildMap().get(m[0].toLowerCase());
        if (!hints || hints.length === 0) return undefined;

        const range = new vscode.Range(document.positionAt(start), document.positionAt(end));
        return new vscode.Hover(`**Synonym:** ${hints.join(', ')}`, range);
      }
      return undefined;
    },
  });

  context.subscriptions.push(provider);
}

function deactivate() {}

module.exports = { activate, deactivate };
