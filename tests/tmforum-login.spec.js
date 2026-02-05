// @ts-check
const { test, expect } = require('@playwright/test');

test('Login to TM Forum', async ({ page }) => {
  // Increase timeout for this test
  test.setTimeout(60000);
  
  // Go to TM Forum login page
  await page.goto('https://www.tmforum.org/login');
  await page.waitForTimeout(2000);
  
  // Accept cookies if prompted
  const allowAllButton = page.getByRole('button', { name: 'Allow all' });
  if (await allowAllButton.isVisible({ timeout: 3000 }).catch(() => false)) {
    await allowAllButton.click();
    await page.waitForTimeout(1000);
  }
  
  // Fill in username/email
  await page.locator('#username').click();
  await page.locator('#username').fill('pedro.jose@snowflake.com');
  await page.waitForTimeout(500);
  
  // Fill in password
  await page.locator('#password').click();
  await page.locator('#password').fill('!Pedro9900');
  await page.waitForTimeout(500);
  
  // Click Log in button
  await page.getByRole('link', { name: 'Log in' }).click();
  
  // Wait for login to complete and redirect
  await page.waitForTimeout(8000);
  
  // Take a screenshot of the result
  await page.screenshot({ path: 'tmforum-logged-in.png' });
  
  console.log('✅ TM Forum login complete!');
  console.log('📍 Current URL:', page.url());
});
