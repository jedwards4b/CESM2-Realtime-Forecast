#!/bin/bash

#PBS -N test_from_cheyenne
#PBS -l select=1:ncpus=1
#PBS -j oe
#PBS -k eod
#PBS -A CESM0020

hostname
date
echo hello
