import { test, expect } from "@playwright/test";

test("Moose sidebar has people sections", async ({ page }) => {
    await page.goto("/dist/Moose");

    // "Released by" with author link and gravatar
    const releasedBy = page.getByText("Released by");
    await expect(releasedBy).toBeVisible();

    const personRow = releasedBy.locator("+ .sidebar-person-row");
    await expect(personRow.getByRole("link")).toBeVisible();
    await expect(personRow.getByRole("img")).toBeVisible();

    // Authors, Maintainers, Contributors have chevron and expand
    for (const section of ["Authors", "Maintainers", "Contributors"]) {
        const toggle = page.getByRole("button", {
            name: new RegExp(`${section}:`),
        });
        await expect(toggle).toBeVisible();
        await expect(toggle).toHaveAttribute("aria-expanded", "false");

        const targetId = await toggle.getAttribute("aria-controls");
        const expandable = page.locator(`#${targetId}`);
        await expect(expandable).toBeHidden();

        await toggle.click();

        await expect(toggle).toHaveAttribute("aria-expanded", "true");
        await expect(expandable).toBeVisible();
        await expect(expandable.getByRole("img").first()).toBeVisible();
    }
});
