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

cwd="$(dirname "$0")"
cd ../tests

echo `date "+%F %T"` - Installing Playwright ${uri} 
npm install
npx playwright install  

echo `date "+%F %T"` - Running Tests against ${uri}
APPLICATION_URI=${uri} npx playwright test
npx playwright show-trace trace.zip

cd ${cwd}
