#!/bin/bash

# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts  # should be put in the console PATH variable to access use_fsl 
PROJ_DIR=/gnappo/home3/dati/BELGRADO_1.5Philips/PROVA_STE
. use_fsl 5
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
. $PROJ_SCRIPT_DIR/subjects_list.sh

declare -i NUM_CPU=1
EXECUTE_SH=$GLOBAL_SUBJECT_SCRIPT_DIR/subject_wellcome.sh


# ---------------------------------------------------------------------
# EXTRA PARAMS
BET_PARAMS="-SNB -f 0.25"
FIRST_STRUCTURES="L_Caud,L_Pall,L_Puta,L_Thal,R_Caud,R_Pall,R_Puta,R_Thal"
FIRST_OUTPUT_DIR_NAME=first

# High pass filtering...we normally want an HPF in seconds of 100...if you want to change it
HPF_SEC=100  # HPF_SEC/2*TR =  highpass sigma for fslmaths -bptf parameter
FINAL_VOLUMES=196
PATH2STUDYTEMPLATE=T77
# ---------------------------------------------------------------------





# TYPICAL FULL PIPELINE (bedpostx and freesurfer should be run in specific processes, since they last several hours)
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_all_subjects80" $PROJ_DIR -epirm2vol $FINAL_VOLUMES -mel -dtifit 
# if you want to modify the HPF value of EPI nuisance removal step
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_all_subjects80" $PROJ_DIR -epirm2vol $FINAL_VOLUMES -mel -hpfsec $HPF_SEC 

# REGISTER 2 STUDY TEMPLATE
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_all_subjects80" $PROJ_DIR -epirm2vol $FINAL_VOLUMES -melodn T77 -stdimg $PATH2STUDYTEMPLATE


# to do only some specific analysis (put -skipanat to prevent filling the log file with duplicated lines))

# SIENAX

. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_prova_early_pd" $PROJ_DIR -skipanat -sienax "$BET_PARAMS"

# FIRST
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_prova_early_pd" $PROJ_DIR -skipanat -firstodn $FIRST_OUTPUT_DIR_NAME -firststructs $FIRST_STRUCTURES

# BEDPOSTX
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_prova_early_pd" $PROJ_DIR -skipanat -bedx

# FREESURFER
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_prova_early_pd" $PROJ_DIR -skipanat -freesurfer

# STRUCT CONN
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_prova_early_pd" $PROJ_DIR -skipanat -structconn
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_prova_early_pd" $PROJ_DIR -skipanat -freesurfer


wait



echo "=================>>>>  End processing"
