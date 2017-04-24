#!/bin/bash

DIR=`readlink -e $0`
DIR=`dirname $DIR`
for i in `ls $DIR/scratch`;do 
  [ "z`/gpfs/gpfs1/slurm/bin/squeue -j ${i##*\.} -h 2>/dev/null`" == "z" ] && rm -rf $DIR/scratch/$i
done
