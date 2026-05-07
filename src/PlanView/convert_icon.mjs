import sharp from 'sharp';
import fs from 'fs';
import path from 'path';

const svgPath = 'src/NewImages/dronecommanderlogo.svg';
const androidResPath = 'android/res';
const iosResPath = 'deploy/ios/Images.xcassets/AppIcon.appiconset';

const androidSizes = [
    { folder: 'drawable-ldpi', size: 36 },
    { folder: 'drawable-mdpi', size: 48 },
    { folder: 'drawable-hdpi', size: 72 },
    { folder: 'drawable-xhdpi', size: 96 },
    { folder: 'drawable-xxhdpi', size: 144 },
    { folder: 'drawable-xxxhdpi', size: 192 }
];

async function convertIcons() {
    if (!fs.existsSync(svgPath)) {
        console.error(`Source SVG not found at ${svgPath}`);
        return;
    }

    console.log('--- Converting Android Icons ---');
    for (const { folder, size } of androidSizes) {
        const destFolder = path.join(androidResPath, folder);
        if (!fs.existsSync(destFolder)) fs.mkdirSync(destFolder, { recursive: true });
        const destPath = path.join(destFolder, 'icon.png');
        await sharp(svgPath).resize(size, size).png().toFile(destPath);
        console.log(`Created ${destPath}`);
    }

    console.log('\n--- Converting iOS Icons ---');
    if (fs.existsSync(iosResPath)) {
        const contentsJson = JSON.parse(fs.readFileSync(path.join(iosResPath, 'Contents.json'), 'utf8'));
        for (const img of contentsJson.images) {
            if (img.filename) {
                const [widthStr, heightStr] = img.size.split('x');
                const scale = parseInt(img.scale) || 1;
                const width = Math.round(parseFloat(widthStr) * scale);
                const height = Math.round(parseFloat(heightStr) * scale);
                const destPath = path.join(iosResPath, img.filename);
                await sharp(svgPath).resize(width, height).png().toFile(destPath);
                console.log(`Created ${destPath} (${width}x${height})`);
            }
        }
    }

    console.log('\n--- Converting Internal QGC Logos & Splash Screen ---');
    const resourcesPath = 'resources';
    const logos = [
        { name: 'QGCLogoWhite.svg', type: 'svg' },
        { name: 'QGCLogoBlack.svg', type: 'svg' },
        { name: 'QGCLogoArrow.svg', type: 'svg' },
        { name: 'QGCLogoFull.png', type: 'png', size: 800 },
        { name: 'SplashScreen.png', type: 'png', size: 800 }
    ];

    for (const logo of logos) {
        const destPath = path.join(resourcesPath, logo.name);
        if (logo.type === 'svg') {
            fs.copyFileSync(svgPath, destPath);
            console.log(`Updated ${destPath} (SVG Copy)`);
        } else {
            await sharp(svgPath).resize(logo.size).png().toFile(destPath);
            console.log(`Updated ${destPath} (PNG ${logo.size}x${logo.size})`);
        }
    }

    console.log('\n--- Refreshing Resource Timestamps ---');
    const qrcFiles = ['qgcresources.qrc', 'qgcimages.qrc', 'qgroundcontrol.qrc'];
    const now = new Date();
    for (const qrc of qrcFiles) {
        if (fs.existsSync(qrc)) {
            fs.utimesSync(qrc, now, now);
            console.log(`Touched ${qrc}`);
        }
    }

    console.log('\nBranding update complete! Please rebuild your project.');
}

convertIcons().cat