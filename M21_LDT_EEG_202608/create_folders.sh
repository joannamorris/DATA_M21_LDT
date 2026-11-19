#!/bin/bash

start_index=10000
end_index=10005
for ((i=start_index; i<=end_index; i++)); do
  # format a filename with the 3-digit index
  printf -v dirname 'S%03d' $i
  mkdir -p -- "$dirname"
done