#!/usr/bin/env bash

find output || mkdir output
terraform output > output/output_2
string=`sed -n '1p' output/output_2`
echo ${string:14:-5} > output/output_2
