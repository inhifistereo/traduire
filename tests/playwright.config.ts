import { PlaywrightTestConfig } from '@playwright/test';

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
    ]
};
export default config;