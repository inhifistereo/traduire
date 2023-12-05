import { PlaywrightTestConfig, devices } from '@playwright/test';

const config: PlaywrightTestConfig = {
    timeout: 90000,
    globalTimeout: 600000,
    use: {
        contextOptions: {
            ignoreHTTPSErrors: true,
        },
    },
    reporter: [
        ['list'],
    ],
    projects: [
        // {
        //   name: 'chromium',
        //   use: {
        //     ...devices['Desktop Chrome'],
        //   },
        // },
        {
          name: 'Mobile Safari',
          use: {
            ...devices['iPhone 13'],
          },
        },
      ],
};
export default config;
