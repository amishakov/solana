#!/bin/bash

result=$(timeout -k 50 45 python3 "/home/root/monitoring/$1.py")

if [ -z "${result}" ]
then
        echo "{}"
else
        echo "$result"
fi




