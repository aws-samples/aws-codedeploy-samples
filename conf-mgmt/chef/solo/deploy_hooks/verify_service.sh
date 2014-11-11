#!/bin/bash

result=$(curl -s http://localhost:8888/hello/)

if [[ "$result" =~ "Hello World" ]]; then
    exit 0
else
    exit 1
fi
