import { test, expect } from '@playwright/test';

test('home page', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/Search the CPAN - metacpan.org/, { timeout: 10 });
});
