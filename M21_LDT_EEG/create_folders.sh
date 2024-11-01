#!/bin/bash

start_index=201
end_index=245
for ((i=start_index; i<=end_index; i++)); do
  # format a filename with the 3-digit index
  printf -v dirname 'S%03d' $i
  mkdir -p -- "$dirname"
done