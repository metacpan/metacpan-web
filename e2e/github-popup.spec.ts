import { test, expect, type Locator } from "@playwright/test";

const payload = '<img src=x onerror="window.__xss=1">';
// Both try to break out of the quoted attribute they are rendered into.
const homepage =
    'https://example.com/" onmouseover="window.__xss=1" data-pwn="1';
const email = 'a@example.com" onmouseover="window.__xss=1" data-pwn="1';
// Markup guards the non-http branch, which outputs text rather than a link.
const blog = 'javascript:window.__xss=1//<img src=x onerror="window.__xss=1">';

const repo = {
    description: payload,
    homepage,
    html_url: "https://github.com/moose/Moose",
    clone_url: "https://github.com/moose/Moose.git",
    ssh_url: "git@github.com:moose/Moose.git",
    has_issues: true,
    watchers: 1,
    forks: 2,
    open_issues: 3,
    pushed_at: "2024-01-01T00:00:00Z",
};

const user = {
    name: payload,
    company: payload,
    location: payload,
    blog,
    email,
    html_url: "https://github.com/xss-user",
    created_at: "2020-01-01T00:00:00Z",
    followers: 1,
    following: 2,
    public_repos: 3,
};

const issues = [
    {
        title: payload,
        html_url: "https://github.com/xss/repo/issues/1",
        created_at: "2024-01-01T00:00:00Z",
    },
];

test("GitHub popups escape API data", async ({ page }) => {
    await page.route("https://api.github.com/**", (route) => {
        const path = new URL(route.request().url()).pathname;
        const body = path.startsWith("/users/")
            ? user
            : path.endsWith("/issues")
              ? issues
              : repo;
        return route.fulfill({
            json: body,
            headers: { "Access-Control-Allow-Origin": "*" },
        });
    });

    // Add user and issues links next to the existing repo link so github.js wires popups to them.
    await page.route("**/dist/Moose", async (route) => {
        const response = await route.fetch();
        const body = (await response.text()).replace(
            /<a[^>]*data-keyboard-shortcut="g r"/,
            '<a href="https://github.com/xss-user">user</a> <a href="https://github.com/xss/repo/issues">issues</a> $&',
        );
        // The original length/encoding describe the old body; fulfill sets the new length.
        const headers = response.headers();
        delete headers["content-length"];
        delete headers["content-encoding"];
        return route.fulfill({ response, body, headers });
    });

    const links = {
        repo: page.locator('a[data-keyboard-shortcut="g r"]'),
        user: page.locator('a[href="https://github.com/xss-user"]'),
        issues: page.locator('a[href="https://github.com/xss/repo/issues"]'),
    };

    await page.goto("/dist/Moose");
    await expect(links.user, "injected user link").toHaveCount(1);
    await expect(links.issues, "injected issues link").toHaveCount(1);

    // Popup-specific checks, run while that popup is open.
    const checks: Partial<
        Record<keyof typeof links, (tip: Locator) => Promise<void>>
    > = {
        // An http(s) homepage becomes a link, its value confined to one href.
        repo: (tip) =>
            expect(
                tip.getByRole("link", { name: homepage, exact: true }),
            ).toHaveAttribute("href", homepage),
        // Email is confined to one mailto href; a non-http blog renders as plain text.
        user: async (tip) => {
            await expect(
                tip.getByRole("link", { name: email, exact: true }),
            ).toHaveAttribute("href", `mailto:${email}`);
            const text = tip.getByText(blog, { exact: true });
            await expect(text).toBeVisible();
            await expect(text).not.toHaveRole("link");
        },
    };

    for (const [name, link] of Object.entries(links)) {
        await link.hover();
        await expect(link).toHaveAttribute("aria-describedby", /^qtip-/);
        const tip = page.locator(
            `#${await link.getAttribute("aria-describedby")}`,
        );

        await expect(tip, name).toContainText(payload);
        await expect(tip.locator("img"), name).toHaveCount(0);
        await expect(tip.locator('a[href^="javascript:"]'), name).toHaveCount(
            0,
        );
        await expect(
            tip.locator("[data-pwn], [onmouseover]"),
            name,
        ).toHaveCount(0);
        await checks[name as keyof typeof links]?.(tip);
        await page.mouse.move(0, 0);
        await expect(tip).toBeHidden();
    }

    expect(await page.evaluate(() => "__xss" in window)).toBe(false);
});
