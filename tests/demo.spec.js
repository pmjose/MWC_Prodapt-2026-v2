// @ts-check
const { test, expect } = require('@playwright/test');

test('Live browser demo - Google search', async ({ page }) => {
  // Go to Google
  await page.goto('https://www.google.com');
  await page.waitForTimeout(1000);
  
  // Find and fill the search box (multiple selectors for reliability)
  const searchBox = page.locator('textarea[name="q"], input[name="q"]').first();
  await searchBox.fill('Snowflake data cloud');
  await page.waitForTimeout(500);
  
  // Press Enter to search
  await searchBox.press('Enter');
  
  // Wait for results
  await page.waitForTimeout(2000);
  
  // Scroll down to see results
  await page.evaluate(() => window.scrollBy(0, 300));
  await page.waitForTimeout(1500);
  
  console.log('✅ Google demo complete!');
});

test('Live browser demo - Wikipedia', async ({ page }) => {
  // Go to Wikipedia
  await page.goto('https://en.wikipedia.org');
  await page.waitForTimeout(1000);
  
  // Search for something
  await page.getByRole('searchbox', { name: 'Search Wikipedia' }).fill('Artificial Intelligence');
  await page.waitForTimeout(500);
  
  await page.keyboard.press('Enter');
  await page.waitForTimeout(2000);
  
  // Scroll down the page
  await page.evaluate(() => window.scrollBy(0, 500));
  await page.waitForTimeout(1000);
  
  console.log('✅ Wikipedia demo complete!');
});

test('Live browser demo - GitHub', async ({ page }) => {
  // Go to GitHub
  await page.goto('https://github.com/explore');
  await page.waitForTimeout(1500);
  
  // Scroll to see trending repos
  await page.evaluate(() => window.scrollBy(0, 400));
  await page.waitForTimeout(1000);
  
  await page.evaluate(() => window.scrollBy(0, 400));
  await page.waitForTimeout(1000);
  
  console.log('✅ GitHub demo complete!');
});
