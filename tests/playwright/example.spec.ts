import { test, expect } from '@playwright/test';

test('about:blank loads', async ({ page }) => {
  await page.goto('about:blank');
  const body = await page.locator('body');
  await expect(body).toBeTruthy();
});
