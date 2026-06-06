const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log("=========================================");
console.log("   SAYR ASSETS BUILD & PIPELINE SCRIPT   ");
console.log("=========================================");

// 1. Ensure sharp is installed locally
try {
  console.log("Checking sharp dependency...");
  require('sharp');
} catch (e) {
  console.log("sharp not found. Installing sharp locally...");
  try {
    execSync("npm install sharp --no-save", { stdio: 'inherit' });
  } catch (err) {
    console.error("Error: Failed to install sharp. Ensure Node.js and npm are installed.", err.message);
    process.exit(1);
  }
}

const sharp = require('sharp');

// Paths
const iconSvg = path.join(__dirname, 'assets', 'icons', 'app_icon.svg');
const iconPngDest = path.join(__dirname, 'assets', 'icons', 'app_icon.png');
const iconImagePngDest = path.join(__dirname, 'assets', 'images', 'app_icon.png');
const iconAdaptiveForegroundDest = path.join(__dirname, 'assets', 'icons', 'app_icon_adaptive_foreground.png');
const splashSvg = path.join(__dirname, 'assets', 'images', 'splash_logo.svg');
const splashPngDest = path.join(__dirname, 'assets', 'images', 'splash_logo.png');

async function runPipeline() {
  console.log("\n[1/3] Converting app_icon.svg to PNG...");
  if (!fs.existsSync(iconSvg)) {
    console.error(`Error: Source SVG not found at ${iconSvg}`);
    process.exit(1);
  }
  
  // Render and resize app launcher icon with safe-area padding (dark background)
  await sharp(iconSvg)
    .png()
    .resize(400, 400, {
      fit: 'contain',
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .extend({
      top: 56,
      bottom: 56,
      left: 56,
      right: 56,
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .toFile(iconPngDest);
  console.log(`✓ Generated: ${iconPngDest}`);

  await sharp(iconSvg)
    .png()
    .resize(400, 400, {
      fit: 'contain',
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .extend({
      top: 56,
      bottom: 56,
      left: 56,
      right: 56,
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .toFile(iconImagePngDest);
  console.log(`✓ Generated: ${iconImagePngDest}`);


  // Render adaptive launcher foreground with safe-area padding
  await sharp(iconSvg)
    .png()
    .resize(312, 312, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 }
    })
    .extend({
      top: 100,
      bottom: 100,
      left: 100,
      right: 100,
      background: { r: 0, g: 0, b: 0, alpha: 0 }
    })
    .toFile(iconAdaptiveForegroundDest);
  console.log(`✓ Generated: ${iconAdaptiveForegroundDest}`);

  console.log("\n[2/3] Converting splash_logo.svg to PNG...");
  if (!fs.existsSync(splashSvg)) {
    console.error(`Error: Source SVG not found at ${splashSvg}`);
    process.exit(1);
  }
  
  // Render and resize splash logo
  await sharp(splashSvg)
    .png()
    .resize(1080, 1920)
    .toFile(splashPngDest);
  console.log(`✓ Generated: ${splashPngDest}`);

  console.log("\n[3/3] Generating native Android launcher icons...");
  try {
    execSync("flutter pub run flutter_launcher_icons", { stdio: 'inherit', cwd: __dirname });
    console.log("✓ Native Android launcher icons successfully updated!");
  } catch (err) {
    console.error("Error: Failed to run flutter_launcher_icons.", err.message);
    process.exit(1);
  }

  console.log("\n=========================================");
  console.log("🎉 PIPELINE COMPLETED SUCCESSFULLY!");
  console.log("=========================================");
}

runPipeline().catch(err => {
  console.error("Pipeline failed with error:", err);
  process.exit(1);
});
