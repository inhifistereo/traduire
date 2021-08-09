import { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
    timeout: 90000,
    globalTimeout: 600000,
    reporter: [
        ['list'],
        //['json', {  outputFile: 'test-results.json' }]
    ]
};
export default config;