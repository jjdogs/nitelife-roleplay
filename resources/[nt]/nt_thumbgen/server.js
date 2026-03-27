const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

onNet('dnx_thumbgen:capture', (modelName, skipExisting) => {
    const src = global.source;
    const resourcePath = GetResourcePath(GetCurrentResourceName());
    const outputDir = path.join(resourcePath, 'output');

    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    if (skipExisting) {
        const alreadyPng  = fs.existsSync(path.join(outputDir, modelName + '.png'));
        const alreadyWebp = fs.existsSync(path.join(outputDir, modelName + '.webp'));
        if (alreadyPng || alreadyWebp) {
            console.log(`[DNX Thumbgen] SKIP (exists): ${modelName}`);
            emitNet('dnx_thumbgen:next', src, true);
            return;
        }
    }

    exports.screencapture.serverCapture(
        src,
        { encoding: 'webp', maxWidth: 512, maxHeight: 512 },
        (data) => {
            const filepath = path.join(outputDir, modelName + '.webp');
            try {
                const b64 = typeof data === 'string'
                    ? data.replace(/^data:image\/\w+;base64,/, '')
                    : Buffer.from(Object.values(data)).toString('base64');
                fs.writeFileSync(filepath, Buffer.from(b64, 'base64'));
                console.log(`[DNX Thumbgen] Saved: ${modelName}.webp — removing background...`);

                const pngPath  = path.join(outputDir, modelName + '.png');
                const pyScript = path.join(resourcePath, 'rembg_process.py');
                const py = spawn('python', [pyScript, filepath, pngPath]);

                py.on('close', (code) => {
                    if (code === 0) {
                        fs.unlinkSync(filepath); // remove the raw webp
                        console.log(`[DNX Thumbgen] Done: ${modelName}.png (transparent)`);
                    } else {
                        console.warn(`[DNX Thumbgen] rembg failed for ${modelName} (exit ${code}), keeping .webp`);
                    }
                    emitNet('dnx_thumbgen:next', src, true);
                });

                py.stderr.on('data', (d) => {
                    const msg = d.toString().trim();
                    if (msg) console.warn(`[rembg] ${msg}`);
                });
            } catch (e) {
                console.error(`[DNX Thumbgen] Failed to save ${modelName}: ${e.message}`);
                emitNet('dnx_thumbgen:next', src, false);
            }
        },
        'base64'
    );
});
