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

echo `date "+%F %T"` - Running Tests against ${uri}
URI=${uri} npx playwright test
npx playwright show-trace trace.zip