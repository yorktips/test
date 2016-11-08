#!/bin/bash

echo "Killing Containers:"
docker rm -f core1
docker rm -f core2
docker rm -f access1
docker rm -f access2
docker rm -f host1
docker rm -f host2
