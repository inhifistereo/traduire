import { defineConfig } from '@playwright/test';
import config from './playwright.config';

// Define environment on the dev box in .env file:
//  .env:
//    PLAYWRIGHT_SERVICE_ACCESS_TOKEN=XXX
//    PLAYWRIGHT_SERVICE_URL=XXX


process.env.PLAYWRIGHT_SERVICE_RUN_ID = process.env.PLAYWRIGHT_SERVICE_RUN_ID || new Date().toISOString();
const os = process.env.PLAYWRIGHT_SERVICE_OS || 'linux';

export default defineConfig(config, {
  workers: 20,
  ignoreSnapshots: false,
  snapshotPathTemplate: `{testDir}/__screenshots__/{testFilePath}/${os}/{arg}{ext}`,
  
  use: {
    connectOptions: {
      wsEndpoint: `${process.env.PLAYWRIGHT_SERVICE_URL}?cap=${JSON.stringify({
        os,
        runId: process.env.PLAYWRIGHT_SERVICE_RUN_ID
      })}`,
      timeout: 30000,
      headers: {
        'x-mpt-access-key': process.env.PLAYWRIGHT_SERVICE_ACCESS_TOKEN!
      },
      exposeNetwork: '<loopback>'
    }
  },
  projects: config.projects? config.projects : [{}]
});
