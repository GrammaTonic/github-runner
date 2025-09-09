const { chromium } = require('playwright');
const fs = require('fs');

// Handle synchronous errors that occur before the async function
process.on('uncaughtException', (error) => {
  console.error('[FATAL] Uncaught exception:', error.message);
  console.error('[FATAL] Stack trace:', error.stack);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[FATAL] Unhandled rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

(async () => {
  console.log('[DEBUG] Starting Playwright screenshot script...');
  
  try {
    console.log('[DEBUG] Launching Chromium browser...');
    const browser = await chromium.launch({ 
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });
    console.log('[DEBUG] Browser launched successfully');
    
    console.log('[DEBUG] Creating new page...');
    const page = await browser.newPage();
    console.log('[DEBUG] New page created');
    
    console.log('[DEBUG] Navigating to https://www.google.com...');
    await page.goto('https://www.google.com', { waitUntil: 'networkidle' });
    console.log('[DEBUG] Page loaded successfully');
    
    // Check if page has content
    const title = await page.title();
    console.log(`[DEBUG] Page title: ${title}`);
    
    // Use env var for screenshot path, fallback to default
    const screenshotPath = process.env.SCREENSHOT_PATH || '/tmp/google_screenshot.png';
    console.log('[DEBUG] Taking screenshot...');
    await page.screenshot({ path: screenshotPath, fullPage: true });
    console.log('[DEBUG] Screenshot taken successfully');
    
    // Verify file was created
    if (fs.existsSync(screenshotPath)) {
      const stats = fs.statSync(screenshotPath);
      console.log(`[DEBUG] Screenshot file created: ${stats.size} bytes at ${screenshotPath}`);
    } else {
      console.log('[ERROR] Screenshot file was not created!');
      process.exit(1);
    }
    
    console.log('[DEBUG] Closing browser...');
    await browser.close();
    console.log('[DEBUG] Browser closed successfully');
    
  } catch (error) {
    console.error('[ERROR] An error occurred:', error.message);
    console.error('[ERROR] Stack trace:', error.stack);
    process.exit(1);
  }
})().catch((error) => {
  console.error('[FATAL] Top-level error:', error.message);
  console.error('[FATAL] Stack trace:', error.stack);
  process.exit(1);
});
