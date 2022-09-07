#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -u|--uri)
      uri=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./run-tests.sh -u {uri}
        --uri(u)  - The URI of the application being tested.  Example: https://traduire.bjdcsa.demo
      "
      exit 0
      ;;
    --) 
      shift
      break
      ;;
    -*|--*=) 
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

cat << EOF > playwright.config.ts
    import { PlaywrightTestConfig } from '@playwright/test';

    const config: PlaywrightTestConfig = {
        timeout: 90000,
        globalTimeout: 600000,
        baseURL: '${uri}'
        reporter: [
            ['list'],
        ]
    };
    export default config;
EOF

echo `date "+%F %T"` - Running Tests against ${uri}
npx playwright test
npx playwright show-trace trace.zip

echo `date "+%F %T"` - Cleaning up
rm -f playwright.config.ts