const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

// Configuration
const CONFIG = {
    templatePath: path.join(__dirname, 'blueprints', 'template.png'),
    outputDir: path.join(__dirname, 'output'),
    defaultSize: { width: 128, height: 128 },
    itemScale: 0.6,
    itemOffsetY: 0,
};

const TEMPLATE_SETTINGS = {
    'template': { itemScale: 0.45, itemOffsetY: 3 }, 
    'template_2': { itemScale: 0.6, itemOffsetY: 0 }, 
};

const INVENTORY_SYSTEMS = [
    { name: 'ox_inventory', imagePath: 'web/images' },
    { name: 'qs-inventory', imagePath: 'html/images' },
    { name: 'qs-inventory-pro', imagePath: 'html/images' },
    { name: 'qb-inventory', imagePath: 'html/images' },
    { name: 'ps-inventory', imagePath: 'html/images' },
    { name: 'lj-inventory', imagePath: 'html/images' },
    { name: 'codem-inventory', imagePath: 'html/itemimages' },
];

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
    <filter id="glow">
      <feGaussianBlur stdDeviation="2" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="128" height="128" rx="8" fill="url(#bg)"/>

  <!-- Grid pattern -->
  <rect width="128" height="128" rx="8" fill="url(#grid)"/>

  <!-- Corner accents -->
  <path d="M 8 20 L 8 8 L 20 8" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <path d="M 108 8 L 120 8 L 120 20" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <path d="M 120 108 L 120 120 L 108 120" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>
  <path d="M 20 120 L 8 120 L 8 108" stroke="#3b82f6" stroke-width="2" fill="none" opacity="0.8"/>

  <!-- Blueprint text -->
  <text x="64" y="118" font-family="Arial, sans-serif" font-size="8" fill="#3b82f6" text-anchor="middle" opacity="0.7">BLUEPRINT</text>

  <!-- Decorative circles -->
  <circle cx="12" cy="12" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
  <circle cx="116" cy="12" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
  <circle cx="12" cy="116" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
  <circle cx="116" cy="116" r="3" fill="none" stroke="#3b82f6" stroke-width="1" opacity="0.5"/>
</svg>
`;

function findResourcesFolder() {
    let currentDir = __dirname;

    for (let i = 0; i < 10; i++) {
        const parentDir = path.dirname(currentDir);
        const resourcesPath = path.join(parentDir, 'resources');

        if (fs.existsSync(resourcesPath) && fs.statSync(resourcesPath).isDirectory()) {
            return resourcesPath;
        }

        if (path.basename(currentDir) === 'resources') {
            return currentDir;
        }

        const txDataResources = path.resolve(currentDir, '..', '..', '..', '..');
        if (fs.existsSync(txDataResources) && path.basename(txDataResources).includes('resources')) {
            return txDataResources;
        }

        currentDir = parentDir;
    }

    return null;
}
function findFolderRecursive(dir, folderName, maxDepth = 4, currentDepth = 0) {
    if (currentDepth > maxDepth) return null;

    try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });

        for (const entry of entries) {
            if (!entry.isDirectory()) continue;

            const fullPath = path.join(dir, entry.name);

            if (entry.name === folderName) {
                return fullPath;
            }

            if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;

            const found = findFolderRecursive(fullPath, folderName, maxDepth, currentDepth + 1);
            if (found) return found;
        }
    } catch (e) {
    }

    return null;
}

function detectInventoryImagesPath() {
    const resourcesFolder = findResourcesFolder();

    if (!resourcesFolder) {
        console.log('Could not find FiveM resources folder automatically.');
        return null;
    }

    console.log(`Found resources folder: ${resourcesFolder}`);

    for (const inv of INVENTORY_SYSTEMS) {
        const invFolder = findFolderRecursive(resourcesFolder, inv.name, 5);

        if (invFolder) {
            const imagesPath = path.join(invFolder, inv.imagePath);

            if (fs.existsSync(imagesPath)) {
                console.log(`Detected inventory: ${inv.name}`);
                console.log(`Images folder: ${imagesPath}`);
                return imagesPath;
            }
        }
    }

    console.log('No supported inventory system found.');
    return null;
}

function getAvailableTemplates() {
    const blueprintsDir = path.join(__dirname, 'blueprints');
    if (!fs.existsSync(blueprintsDir)) return [];

    const files = fs.readdirSync(blueprintsDir);
    return files.filter(f => f.endsWith('.png')).map(f => ({
        filename: f,
        name: f.replace('.png', ''),
        path: path.join(blueprintsDir, f)
    }));
}


function findTemplate(bgName) {
    const blueprintsDir = path.join(__dirname, 'blueprints');

    // Try exact match first (e.g., "template_2" or "template_2.png")
    const exactPath = path.join(blueprintsDir, bgName.endsWith('.png') ? bgName : `${bgName}.png`);
    if (fs.existsSync(exactPath)) {
        return exactPath;
    }

    // Try with "template_" prefix (e.g., "2" -> "template_2.png")
    const prefixedPath = path.join(blueprintsDir, `template_${bgName}.png`);
    if (fs.existsSync(prefixedPath)) {
        return prefixedPath;
    }

    // Try with just "template" + number (e.g., "2" -> "template2.png")
    const numberedPath = path.join(blueprintsDir, `template${bgName}.png`);
    if (fs.existsSync(numberedPath)) {
        return numberedPath;
    }

    return null;
}

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

function parseArgs(args) {
    const options = {
        itemName: null,
        outputName: null,
        template: CONFIG.templatePath,
        size: CONFIG.defaultSize,
        itemScale: CONFIG.itemScale,
        tint: null,
        inventoryPath: null,
        userSetScale: false,
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];

        if (arg === '--template' && args[i + 1]) {
            options.template = args[++i];
        } else if ((arg === '--bg' || arg === '-b') && args[i + 1]) {
            const bgName = args[++i];
            const templatePath = findTemplate(bgName);
            if (templatePath) {
                options.template = templatePath;
            } else {
                console.error(`Error: Template "${bgName}" not found in blueprints folder.`);
                const templates = getAvailableTemplates();
                if (templates.length > 0) {
                    console.log('\nAvailable templates:');
                    templates.forEach(t => console.log(`  - ${t.name}`));
                }
                process.exit(1);
            }
        } else if (arg === '--size' && args[i + 1]) {
            const [w, h] = args[++i].split('x').map(Number);
            options.size = { width: w, height: h };
        } else if (arg === '--item-scale' && args[i + 1]) {
            options.itemScale = parseFloat(args[++i]);
            options.userSetScale = true;
        } else if (arg === '--tint' && args[i + 1]) {
            options.tint = args[++i];
        } else if (arg === '--inventory' && args[i + 1]) {
            options.inventoryPath = args[++i];
        } else if (arg === '--list-templates' || arg === '-l') {
            const templates = getAvailableTemplates();
            console.log('Available templates:');
            templates.forEach(t => console.log(`  - ${t.name}`));
            process.exit(0);
        } else if (!arg.startsWith('--') && !arg.startsWith('-')) {
            if (!options.itemName) {
                options.itemName = arg;
            } else if (!options.outputName) {
                options.outputName = arg;
            }
        }
    }

    return options;
}

function findItemImage(itemName, inventoryImagesPath) {
    const baseName = itemName.replace(/\.png$/i, '');

    const pathsToCheck = [];

    if (inventoryImagesPath) {
        pathsToCheck.push(path.join(inventoryImagesPath, `${baseName}.png`));
    }

    if (path.isAbsolute(itemName) && fs.existsSync(itemName)) {
        return itemName;
    }

    pathsToCheck.push(
        path.join(__dirname, `${baseName}.png`),
        path.join(__dirname, 'items', `${baseName}.png`),
        itemName,
        `${itemName}.png`
    );

    for (const p of pathsToCheck) {
        if (fs.existsSync(p)) {
            return p;
        }
    }

    return null;
}

async function createBlueprint(options, inventoryImagesPath) {
    const { itemName, outputName, template, size, itemScale, tint } = options;

    if (!itemName) {
        console.error('Error: No item name provided');
        console.log('\nUsage: node create-blueprint.js <item-name> [output-name] [options]');
        console.log('\nOptions:');
        console.log('  --template <path>   Custom blueprint template');
        console.log('  --size <WxH>        Output size (default: 128x128)');
        console.log('  --item-scale <0-1>  Item scale (default: 0.6)');
        console.log('  --tint <hex>        Tint color for item');
        console.log('  --inventory <path>  Override inventory images path');
        process.exit(1);
    }

    const itemImagePath = findItemImage(itemName, options.inventoryPath || inventoryImagesPath);

    if (!itemImagePath) {
        console.error(`Error: Could not find item image for: ${itemName}`);
        console.log('\nSearched in:');
        if (inventoryImagesPath) {
            console.log(`  - ${inventoryImagesPath}`);
        }
        console.log(`  - ${__dirname}`);
        console.log(`  - ${path.join(__dirname, 'items')}`);
        console.log('\nTip: You can specify a full path or use --inventory to set the images folder');
        process.exit(1);
    }

    const baseName = itemName.replace(/\.png$/i, '');
    const outputFileName = outputName || `blueprint_${baseName}`;
    const outputPath = path.join(CONFIG.outputDir, `${outputFileName}.png`);

    const templateName = path.basename(template, '.png');
    const templateSettings = TEMPLATE_SETTINGS[templateName] || {};
    const finalItemScale = options.userSetScale ? itemScale : (templateSettings.itemScale || itemScale);
    const finalItemOffsetY = templateSettings.itemOffsetY !== undefined ? templateSettings.itemOffsetY : CONFIG.itemOffsetY;

    console.log(`\nCreating blueprint: ${outputFileName}`);
    console.log(`  Item image: ${itemImagePath}`);
    console.log(`  Template: ${template}`);
    console.log(`  Item scale: ${finalItemScale}`);
    console.log(`  Output: ${outputPath}`);

    try {
        const templateBuffer = await sharp(template)
            .resize(size.width, size.height)
            .toBuffer();

        const itemSize = Math.round(Math.min(size.width, size.height) * finalItemScale);

        let itemPipeline = sharp(itemImagePath)
            .resize(itemSize, itemSize, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } });

        if (tint) {
            const r = parseInt(tint.slice(1, 3), 16);
            const g = parseInt(tint.slice(3, 5), 16);
            const b = parseInt(tint.slice(5, 7), 16);
            itemPipeline = itemPipeline.tint({ r, g, b });
        }

        const itemBuffer = await itemPipeline.toBuffer();

        const left = Math.round((size.width - itemSize) / 2);
        const top = Math.round((size.height - itemSize) / 2) + finalItemOffsetY - 5;

        await sharp(templateBuffer)
            .composite([
                {
                    input: itemBuffer,
                    left,
                    top,
                },
            ])
            .png()
            .toFile(outputPath);

        console.log(`\nBlueprint created successfully!`);
        console.log(`Output: ${outputPath}`);
        return outputPath;

    } catch (error) {
        console.error('Error creating blueprint:', error.message);
        process.exit(1);
    }
}

async function main() {
    await ensureDirectories();
    await ensureTemplate();

    const args = process.argv.slice(2);

    if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
        const templates = getAvailableTemplates();
        console.log(`
Blueprint Image Creator
=======================

Creates blueprint images by overlaying item images onto a blueprint template.
Auto-detects your inventory system and finds item images automatically.

Usage:
  node create-blueprint.js <item-name> [output-name] [options]

Arguments:
  item-name     Name of the item (e.g., "lockpick" - will find lockpick.png)
  output-name   Name for the output file (default: blueprint_<item-name>)

Options:
  --bg, -b <name>     Select template from blueprints folder (e.g., --bg 2 or --bg template_2)
  --template <path>   Use a custom blueprint template (full path)
  --size <WxH>        Output size in pixels (default: 128x128)
  --item-scale <0-1>  Scale of the item relative to template (default: 0.6)
  --tint <hex>        Apply a tint color to the item (e.g., #3b82f6)
  --inventory <path>  Override auto-detected inventory images path
  --list-templates    List available templates
  -l

Examples:
  node create-blueprint.js lockpick
  node create-blueprint.js lockpick --bg 2
  node create-blueprint.js thermite blueprint_thermite --bg template_2
  node create-blueprint.js armour --tint #3b82f6
  node create-blueprint.js pistol --inventory "C:/path/to/inventory/images"

Available Templates:
${templates.length > 0 ? templates.map(t => `  - ${t.name}`).join('\n') : '  (none found)'}

Supported Inventories (auto-detected):
  - ox_inventory
  - qb-inventory / ps-inventory / lj-inventory
  - qs-inventory / qs-inventory-pro
  - codem-inventory

Output:
  Blueprints are saved to the 'output' folder.
`);
        return;
    }

    console.log('Blueprint Image Creator\n=======================\n');

    const inventoryImagesPath = detectInventoryImagesPath();

    const options = parseArgs(args);
    await createBlueprint(options, inventoryImagesPath);
}

main().catch(console.error);
