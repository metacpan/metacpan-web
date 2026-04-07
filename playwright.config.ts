import { defineConfig, devices } from "@playwright/test";

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
const port = process.env.PLAYWRIGHT_PORT
    ? Number(process.env.PLAYWRIGHT_PORT)
    : 5099;

const baseURL =
    process.env.PLAYWRIGHT_BASE_URL || `http://127.0.0.1:${port}`;

export default defineConfig({
    testDir: "./e2e",
    outputDir: "./playwright/test-results",
    /* Run tests in files in parallel */
    fullyParallel: true,
    /* Fail the build on CI if you accidentally left test.only in the source code. */
    // forbidOnly: !!process.env.CI,
    /* Retry on CI only */
    retries: 0,
    /* Opt out of parallel tests on CI. */
    // workers: process.env.CI ? 1 : undefined,
    workers: 1,
    /* Reporter to use. See https://playwright.dev/docs/test-reporters */
    reporter: [["html", { outputFolder: "./playwright/report" }]],
    /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
    use: {
        /* Base URL to use in actions like `await page.goto('/')`. */
        baseURL,

        /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
        trace: "on-first-retry",
    },

    ...(!process.env.PLAYWRIGHT_PORT &&
        !process.env.PLAYWRIGHT_BASE_URL && {
            webServer: {
                command: `plackup -p ${port} app.psgi`,
                port,
                reuseExistingServer: true,
            },
        }),

    /* Configure projects for major browsers */
    projects: [
        {
            name: "chromium",
            use: { ...devices["Desktop Chrome"] },
        },

        // {
        // name: 'firefox',
        // use: { ...devices['Desktop Firefox'] },
        // },
        //
        // {
        // name: 'webkit',
        // use: { ...devices['Desktop Safari'] },
        // },
    ],
});
