const vscode = require('vscode');
const zlib = require('zlib');

// 8 Hex-Werte in eckigen Klammern: [0x00, 0x3C, ..., 0x00]
const PATTERN = /\[\s*((?:0x[0-9A-Fa-f]{2}\s*,\s*){7}0x[0-9A-Fa-f]{2})\s*\]/g;
const SIZE = 16; // Pixelgröße pro Feld -> Bild 128x128

function crc32(buf) {
    let crc = 0xFFFFFFFF;
    for (let n = 0; n < buf.length; n++) {
        let c = (crc ^ buf[n]) & 0xFF;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
        crc = (crc >>> 8) ^ c;
    }
    return (crc ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(body));
    return Buffer.concat([len, body, crc]);
}

function buildImage(bytes) {
    const W = 8 * SIZE;
    const bg = [0x40, 0x31, 0x8d];
    const fg = [0xa5, 0xa5, 0xff];

    const raw = Buffer.alloc((W * 3 + 1) * W);
    let p = 0;
    for (let y = 0; y < W; y++) {
        raw[p++] = 0; // Filter-Byte
        const byte = bytes[Math.floor(y / SIZE)];
        for (let x = 0; x < W; x++) {
            const on = (byte >> (7 - Math.floor(x / SIZE))) & 1;
            const c = on ? fg : bg;
            raw[p++] = c[0]; raw[p++] = c[1]; raw[p++] = c[2];
        }
    }

    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(W, 0);
    ihdr.writeUInt32BE(W, 4);
    ihdr[8] = 8; // Bittiefe
    ihdr[9] = 2; // Farbtyp RGB

    const png = Buffer.concat([
        Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
        chunk('IHDR', ihdr),
        chunk('IDAT', zlib.deflateSync(raw)),
        chunk('IEND', Buffer.alloc(0)),
    ]);
    return 'data:image/png;base64,' + png.toString('base64');
}

function activate(context) {
    console.log('Hex Pixel Preview aktiv');

    context.subscriptions.push(
        vscode.languages.registerHoverProvider('python', {
            provideHover(document, position) {
                const line = document.lineAt(position.line).text;

                for (const m of line.matchAll(new RegExp(PATTERN))) {
                    const start = m.index;
                    const end = start + m[0].length;
                    if (position.character < start || position.character > end) continue;

                    const bytes = m[1].split(',').map(s => parseInt(s.trim(), 16));
                    const md = new vscode.MarkdownString(`![](${buildImage(bytes)})`);
                    return new vscode.Hover(md, new vscode.Range(position.line, start, position.line, end));
                }
            }
        })
    );
}

function deactivate() {}

module.exports = { activate, deactivate };
