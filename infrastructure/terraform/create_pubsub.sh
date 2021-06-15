#!/bin/bash

export pubsub_name=$1
export pubsub_rg_name=$2
export pubsub_secret_name=$3
export keyvault_name=$4

az webpubsub create -n ${pubsub_name} -g ${pubsub_rg_name} --sku Free_F1 -l eastus
key=`az webpubsub key show -n ${pubsub_name} -g ${pubsub_rg_name} -o tsv --query primaryKey`
az keyvault secret set --name ${pubsub_secret_name} --vault-name ${keyvault_name} --value ${key}