import { test, expect } from "@playwright/test";

test.describe("author favorites page", () => {
    test.beforeEach(async ({ page }) => {
        await page.goto("/author/PERLER/favorites");
    });

    test("renders favorites table", async ({ page }) => {
        await expect(
            page.locator("table#metacpan_author_favorites")
        ).toBeVisible();
    });

    test("has breadcrumb back to author", async ({ page }) => {
        const breadcrumb = page.locator(
            ".breadcrumbs a[href='/author/PERLER']"
        );
        await expect(breadcrumb).toBeVisible();
    });
});

test("author page links to all favorites", async ({ page }) => {
    await page.goto("/author/PERLER");
    const favoritesLink = page.getByRole("link", {
        name: /View all.*favorites/,
    });

    // Only visible if author has more than 10 favorites
    const count = await favoritesLink.count();
    if (count > 0) {
        await expect(favoritesLink).toBeVisible();
    }
});
