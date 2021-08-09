#!/bin/bash

export url=$1

echo "Running tests on ${url}"
sed "s/{{url}}/${url}/g" ./traduire.spec.ts.template > traduire.spec.ts

npx playwright test