import { test, expect } from "@playwright/test";

test("home page", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Search the CPAN - metacpan.org/, {
        timeout: 10,
    });
});

test("suggest is correct", async ({ page }) => {
    await page.goto("/");
    const searchInput = page.getByPlaceholder("Search the CPAN");
    await expect(searchInput).toBeVisible();
    searchInput.fill("HTML:Restrict");
    await searchInput.press("Enter");

    await expect(page.getByRole('alert')).toContainText('Did you mean: HTML::Restrict');
});

test("suggest accounts for prefix and makes suggestion", async ({ page }) => {
    await page.goto("/");
    const searchInput = page.getByPlaceholder("Search the CPAN");
    await expect(searchInput).toBeVisible();
    searchInput.fill("distribution:HTML:Restrict");
    await searchInput.press("Enter");

    await expect(page.getByRole('alert')).toContainText('Did you mean: distribution:HTML::Restrict');
});

test("suggest accounts for prefix but cannot make suggestion", async ({ page }) => {
    await page.goto("/");
    const searchInput = page.getByPlaceholder("Search the CPAN");
    await expect(searchInput).toBeVisible();
    searchInput.fill("distribution:HTMLRestrict");
    await searchInput.press("Enter");

    await expect(page.getByRole('alert')).toBeHidden();
});

test("suggest ignores misspelled prefix and makes suggestion", async ({ page }) => {
    await page.goto("/");
    const searchInput = page.getByPlaceholder("Search the CPAN");
    await expect(searchInput).toBeVisible();
    searchInput.fill("disstribution:HTML:Restrict");
    await searchInput.press("Enter");

    await expect(page.getByRole('alert')).toContainText('Did you mean: disstribution::HTML::Restrict');
});
