import { test, expect, PlaywrightTestConfig } from '@playwright/test';

declare var process : {
  env: {
    BASE_URL: string
  }
}

const BASE_URL = process.env["URI"];

test('test transcription', async ({ page, context }) => {
  await context.tracing.start({ screenshots: true, snapshots: true });
  await page.goto(BASE_URL);
  await page.click('input[type="file"]');
  await page.setInputFiles('input[type="file"]', '../assets/Recording.m4a');
  await page.click('text=Upload Recording.m4a');
  await page.waitForSelector('text=Completed', { timeout: 0 });
  await page.click('text=Get Transcription');
  await page.waitForTimeout(1000);
  const transcription = await page.innerText('div.card-body');
  expect(transcription).toBe('This is a simple test message to be translated.');
  await context.tracing.stop({ path: 'trace.zip' });
});