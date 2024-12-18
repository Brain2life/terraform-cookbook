#!/bin/bash
ip=$(curl -s https://checkip.amazonaws.com)
echo "{\"ip\": \"$ip\"}"