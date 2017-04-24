#!/bin/bash
################################################################################
#  slurm.sbatch - A sample submit script for SLURM that illustrates how to
#  spin up a Hadoop cluster for a map/reduce task using myHadoop
#
# Created:
#  Glenn K. Lockwood, San Diego Supercomputer Center             February 2014
# Revised:
#  Tingyang Xu      September 2015
################################################################################
## -N 4 means we are going to use 4 nodes to run Hadoop cluster
#SBATCH -N 4
## -c 24 means we are going to use 24 cores on each node.
#SBATCH -c 24
## --ntasks-per-node=1 means each node runs single datanode/namenode.
## When you write your own SLURM batch, you DON'T need to change ntasks-per-node or exclusive.
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive

# download example data to your folder for later on mapredue job.
if [ ! -f ./pg2701.txt ]; then
  echo "*** Retrieving some sample input data"
  wget 'http://www.gutenberg.org/cache/epub/2701/pg2701.txt'
fi

# where to store the temp configure files.
# make sure that the configure files are GLOBALLY ACCESSIBLE
export HADOOP_CONF_DIR=/apps2/myHadoop/Sep012015/scratch/${USER}_hadoop-conf.$SLURM_JOBID

# If you want to use Hive, please add the following line
#export HIVE_CONF_DIR=$HADOOP_CONF_DIR/hive

#################NO CHANGE############################
export SPARK_CONF_DIR=$HADOOP_CONF_DIR

if [ "z$HADOOP_OLD_DIR" == "z" ]; then
  myhadoop-configure.sh
else
  myhadoop-configure.sh -p $HADOOP_OLD_DIR
fi

# test if the HADOOP_CONF_DIR is globally accessible
if ! srun ls -d $HADOOP_CONF_DIR; then
  echo "The configure files are not globally accessible.
       Please consider the the shared, home, or scratch directory to put your HADOOP_CONF_DIR.
       For example, export HADOOP_CONF_DIR=/scratch/$USER_hadoop-conf.$SLURM_JOBID"
  myhadoop-cleanup.sh
  rm -rf $HADOOP_CONF_DIR
  exit 1
fi
$HADOOP_HOME/sbin/start-all.sh
sleep 5
hdfs dfs -ls /
$SPARK_HOME/sbin/start-all.sh
hdfs dfs -mkdir -p /tmp/hive/$USER
hdfs dfs -chmod -R 777 /tmp
#################NO CHANGE END########################

# make the data dir. Here we need the direct dir in the hdfs
hdfs dfs -mkdir /data
hdfs dfs -put ./pg2701.txt /data
hdfs dfs -ls /data
# run spark
spark-shell -i example.scala
# copy out the results
hdfs dfs -ls /scala_outputs
hdfs dfs -get /scala_outputs ./

#################NO CHANGE############################
$SPARK_HOME/sbin/stop-all.sh
$HADOOP_HOME/sbin/stop-all.sh
myhadoop-cleanup.sh
rm -rf $HADOOP_CONF_DIR
#################NO CHANGE END########################