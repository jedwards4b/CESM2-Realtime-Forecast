#!/usr/bin/env bash  
#PBS -N %TASK%
#PBS -r n
#PBS -j oe
#PBS -o %LOGDIR%/%TASK%.out
#PBS -S /bin/bash
#PBS -l select=1:ncpus=128:mpiprocs=128:ompthreads=1:mem=230GB
#PBS -q main
#PBS -A %PROJECT%
#PBS -l walltime=02:00:00
#PBS -V
