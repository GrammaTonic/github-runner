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
  const fallbackMode = process.env.PLAYWRIGHT_FALLBACK_MODE || 'system-executable';
  const testUrl = process.env.PLAYWRIGHT_TEST_URL;
  
  try {
    console.log('[DEBUG] Launching Chromium browser...');
    let browser;
    try {
      browser = await chromium.launch({ 
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
      });
    } catch (launchError) {
      if (fallbackMode === 'channel-chrome') {
        try {
          console.warn('[WARN] Playwright-managed Chromium is unavailable. Falling back to Playwright Chrome channel.');
          browser = await chromium.launch({
            channel: 'chrome',
            headless: true,
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
          });
        } catch (channelError) {
          console.warn('[WARN] Playwright Chrome channel fallback failed. Switching to system executable fallback.');
          const fallbackChromePath = '/usr/bin/google-chrome';
          if (!fs.existsSync(fallbackChromePath)) {
            throw channelError;
          }
          browser = await chromium.launch({
            executablePath: fallbackChromePath,
            headless: true,
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-crashpad', '--disable-crash-reporter', '--disable-crashpad-for-testing', '--disable-features=Crashpad']
          });
        }
      } else {
        const fallbackChromePath = '/usr/bin/google-chrome';
        if (!fs.existsSync(fallbackChromePath)) {
          throw launchError;
        }
        console.warn('[WARN] Playwright-managed Chromium is unavailable. Falling back to system Google Chrome executable.');
        browser = await chromium.launch({
          executablePath: fallbackChromePath,
          headless: true,
          args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-crashpad', '--disable-crash-reporter', '--disable-crashpad-for-testing', '--disable-features=Crashpad']
        });
      }
    }
    console.log('[DEBUG] Browser launched successfully');
    
    console.log('[DEBUG] Creating new page...');
    const page = await browser.newPage();
    console.log('[DEBUG] New page created');
    
    if (testUrl) {
      console.log(`[DEBUG] Navigating to ${testUrl}...`);
      try {
        await page.goto(testUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
        console.log('[DEBUG] Page loaded successfully');
      } catch (navigationError) {
        console.warn(`[WARN] External navigation failed (${navigationError.message}). Falling back to local test content.`);
        await page.setContent('<html><head><title>Playwright Local Fallback</title></head><body><h1>Playwright Fallback Page</h1><p>External network navigation was unavailable in CI.</p></body></html>');
        console.log('[DEBUG] Local fallback page rendered successfully');
      }
    } else {
      console.log('[DEBUG] No PLAYWRIGHT_TEST_URL provided; using local test content.');
      await page.setContent('<html><head><title>Playwright Local Test</title></head><body><h1>Playwright Local Test Page</h1><p>CI network-independent rendering path.</p></body></html>');
      console.log('[DEBUG] Local test page rendered successfully');
    }
    
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
