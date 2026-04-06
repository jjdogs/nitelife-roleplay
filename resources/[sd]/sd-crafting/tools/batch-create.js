const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const CONFIG = {
    templatePath: path.join(__dirname, 'blueprints', 'template.png'),
    outputDir: path.join(__dirname, 'output'),
    defaultSize: { width: 128, height: 128 },
    itemScale: 0.6,
    supportedExtensions: ['.png', '.jpg', '.jpeg', '.webp'],
};

const DEFAULT_TEMPLATE_SVG = `
<svg width="128" height="128" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1e3a5f;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0d1f33;stop-opacity:1" />
    </linearGradient>
    <pattern id="grid" width="16" height="16" patternUnits="userSpaceOnUse">
      <path d="M 16 0 L 0 0 0 16" fill="none" stroke="#3b82f6" stroke-width="0.3" opacity="0.4"/>
    </pattern>
  </defs>
  <rect width="128" height="128" rx="8" fill="url(#bg)"/>
  <rect width="128" height="128" rx="8" fill="url(#grid)"/>
  <path d="M 8 20 L 8 8 L 20 8" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <path d="M 108 8 L 120 8 L 120 20" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <path d="M 120 108 L 120 120 L 108 120" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <path d="M 20 120 L 8 120 L 8 108" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <text x="64" y="118" font-family="Arial, sans-serif" font-size="8" fill="#3b82f6" text-anchor="middle" opacity="0.7">BLUEPRINT</text>
  <circle cx="12" cy="12" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
  <circle cx="116" cy="12" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
  <circle cx="12" cy="116" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
  <circle cx="116" cy="116" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
</svg>
`;

async function ensureDirectories() {
    const dirs = [
        path.join(__dirname, 'blueprints'),
        path.join(__dirname, 'output'),
    ];

    for (const dir of dirs) {
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
    }
}

async function ensureTemplate() {
    if (!fs.existsSync(CONFIG.templatePath)) {
        console.log('Creating default blueprint template...');
        await sharp(Buffer.from(DEFAULT_TEMPLATE_SVG))
            .png()
            .toFile(CONFIG.templatePath);
        console.log(`Template created at: ${CONFIG.templatePath}`);
    }
}

async function createBlueprint(itemImagePath, templateBuffer, size, itemScale) {
    const baseName = `blueprint_${path.basename(itemImagePath, path.extname(itemImagePath))}`;
    const outputPath = path.join(CONFIG.outputDir, `${baseName}.png`);

    try {
        const itemSize = Math.round(Math.min(size.width, size.height) * itemScale);

        const itemBuffer = await sharp(itemImagePath)
            .resize(itemSize, itemSize, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
            .toBuffer();

        const left = Math.round((size.width - itemSize) / 2);
        const top = Math.round((size.height - itemSize) / 2) - 5;

        await sharp(templateBuffer)
            .composite([{ input: itemBuffer, left, top }])
            .png()
            .toFile(outputPath);

        return { success: true, name: baseName, path: outputPath };
    } catch (error) {
        return { success: false, name: baseName, error: error.message };
    }
}

function parseArgs(args) {
    const options = {
        source: null,
        items: [],
        filter: null,
        template: CONFIG.templatePath,
        size: CONFIG.defaultSize,
        itemScale: CONFIG.itemScale,
        listMode: false,
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];

        if (arg === '--list') {
            options.listMode = true;
        } else if (arg === '--filter' && args[i + 1]) {
            options.filter = args[++i];
        } else if (arg === '--template' && args[i + 1]) {
            options.template = args[++i];
        } else if (arg === '--size' && args[i + 1]) {
            const [w, h] = args[++i].split('x').map(Number);
            options.size = { width: w, height: h };
        } else if (arg === '--item-scale' && args[i + 1]) {
            options.itemScale = parseFloat(args[++i]);
        } else if (!arg.startsWith('--')) {
            if (options.listMode) {
                options.items.push(arg);
            } else if (!options.source) {
                options.source = arg;
            }
        }
    }

    return options;
}

function getItemsFromFolder(folderPath, filter) {
    if (!fs.existsSync(folderPath)) {
        console.error(`Error: Folder not found: ${folderPath}`);
        process.exit(1);
    }

    const files = fs.readdirSync(folderPath);
    let items = files.filter(file => {
        const ext = path.extname(file).toLowerCase();
        return CONFIG.supportedExtensions.includes(ext);
    });

    if (filter) {
        const regex = new RegExp(filter, 'i');
        items = items.filter(file => regex.test(file));
    }

    return items.map(file => path.join(folderPath, file));
}

async function main() {
    await ensureDirectories();
    await ensureTemplate();

    const args = process.argv.slice(2);

    if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
        console.log(`
Batch Blueprint Creator
=======================

Creates multiple blueprint images from a folder or list of items.

Usage:
  node batch-create.js <items-folder> [options]
  node batch-create.js --list <item1.png> <item2.png> ...

Arguments:
  items-folder    Folder containing item images

Options:
  --list              Process a list of specific files instead of a folder
  --filter <pattern>  Only process files matching the pattern (regex)
  --template <path>   Use a custom blueprint template
  --size <WxH>        Output size in pixels (default: 128x128)
  --item-scale <0-1>  Scale of the item relative to template (default: 0.6)

Examples:
  node batch-create.js C:/ox_inventory/web/images --filter "weapon_"
  node batch-create.js ./items
  node batch-create.js --list lockpick.png thermite.png armour.png

Output:
  All blueprints are saved to the 'output' folder with 'blueprint_' prefix.
`);
        return;
    }

    const options = parseArgs(args);
    let itemPaths = [];

    if (options.listMode) {
        itemPaths = options.items.map(item => {
            if (path.isAbsolute(item)) return item;
            if (fs.existsSync(item)) return item;
            if (fs.existsSync(path.join(__dirname, item))) return path.join(__dirname, item);
            return item;
        }).filter(p => fs.existsSync(p));
    } else if (options.source) {
        itemPaths = getItemsFromFolder(options.source, options.filter);
    } else {
        console.error('Error: No source folder or items provided');
        process.exit(1);
    }

    if (itemPaths.length === 0) {
        console.log('No items found to process.');
        return;
    }

    console.log(`\nProcessing ${itemPaths.length} item(s)...\n`);

    // Load template once
    const templateBuffer = await sharp(options.template)
        .resize(options.size.width, options.size.height)
        .toBuffer();

    let successCount = 0;
    let failCount = 0;

    for (const itemPath of itemPaths) {
        const result = await createBlueprint(itemPath, templateBuffer, options.size, options.itemScale);

        if (result.success) {
            console.log(`  [OK] ${result.name}`);
            successCount++;
        } else {
            console.log(`  [FAIL] ${result.name}: ${result.error}`);
            failCount++;
        }
    }

    console.log(`\nComplete! Created ${successCount} blueprint(s), ${failCount} failed.`);
    console.log(`Output folder: ${CONFIG.outputDir}`);
}

main().catch(console.error);
