#!/bin/bash  
#PBS -N %TASK%
#PBS -r n
#PBS -j oe
#PBS -o %LOGDIR%/%TASK%.out
#PBS -S /bin/bash
#PBS -l select=9:ncpus=128:mpiprocs=128:ompthreads=1:mem=230GB
#PBS -q main
#PBS -A %PROJECT%
#PBS -l walltime=04:00:00
#PBS -V
