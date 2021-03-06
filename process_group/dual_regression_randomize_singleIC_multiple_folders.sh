#!/bin/sh

# ver 2.0 13/10/2012				:	this version apply the same design to different folders containing ONE rns. 
#															always output results in -idp/-odn => input_folder/analysis_name
#															It assumes that input_directory (-idp) contains the input path with the last folder corresponding to the RSN label.
#															thus extract last folder name and use it as prefix for dr_stage3 files.

Usage() {
    cat <<EOF
Usage: dual_regression_randomize_singleIC_multiple_folders <input directory> <proj_name> <design> <n_perm> <analysis_name> [mask] [gm file] [gm column]

1:<input_directory>       			directory  containing dr_stage_2 images 
			 													the script assumes to extract last folder name to get RSN label
2<proj_path>										project path

-ifn														alternative name to dr_stage2_ic0000
-model 		                      path to Design fsf for final cross-subject modelling with randomise
																can be replaced with just -1 for group-mean (one-group t-test) modelling.
-nperm		                      Num. permutations ; 1 just raw tstat output, 0 to not run randomise at all.
-odn														analysis name, define output folder
-mask 													use idp/mask. nii.gz as mask
-maskf													full path of mask file
-maskp													full path of a folder containing "mask_$RSN_LABEL.nii.gz"
-vxl									      		column number of GM confound in model's fsf	
-vxf								       			4Dimage file with gray matter 							

EOF
    exit 1
}
#==============================================================================================
# process input parameters
[ "$3" = "" ] && Usage

INPUT_DIR=$1; shift
if [ ! -d $1 ]; then echo "ERROR: input dir ($1) not present"; exit; fi
RSN_LABEL=$(basename $INPUT_DIR) 

PROJ_PATH=$1; shift

gm_corr_string=""
input_file_name=dr_stage2_ic0000
mask=$INPUT_DIR/mask
vxl=""
vxf=""
EX_CHANG_BLOCK=0

while [ ! -z "$1" ]
do
  case "$1" in
  
  		-ifn)		input_file_name=$2; shift;;
  		
		-model)		if [ $2 = "-1" ] ; then
  							DESIGN="-1"
  							des_name="mean"
  							ANALYSIS_NAME="mean"
							else
  							if [ ! -f $2.mat -o ! -f $2.con ]; then echo "ERROR: input mat/con ($2) not presents"; exit; fi
  							des=$2
  							DESIGN="-d $des.mat -t $des.con"
  							des_name=$(basename "$des")
  						fi
  						shift;;
  						
		-nperm)		NPERM=$2; shift;;
		
		-odn)			ANALYSIS_NAME=$2; shift;;
		
		-maskf)		mask=$2; shift
							if [ `$FSLDIR/bin/imtest $mask` = 0 ]; then "input mask file ($mask) do not exist"; exit; fi
							mask_string="_mask";;
							
		-maskd)		mask=$2/mask_$RSN_LABEL; shift
							if [ `$FSLDIR/bin/imtest $mask` = 0 ]; then "input mask dir ($mask) do not exist"; exit; fi
							mask_string="_maskrsn";;

		-vxl)			vxl=$2; shift;;
		
		-vxf)			vxf=$2; shift;;
		
			-e)			EX_CHANG_BLOCK=1; shift;;
		
		*)  			break;;
	esac
	shift
done

output_dr_stage3_name=$RSN_LABEL"_"$des_name$mask_string

if [ ! -z $vxl -a -z $vxf ]; then echo "ERROR: vxf param is empty, while vxl is set"; exit; fi
if [ -z $vxl -a ! -z $vxf ]; then echo "ERROR: vxl param is empty, while vxf is set"; exit; fi

if [ ! -z $vxl -a ! -z $vxf ]; then
	output_dr_stage3_name=$output_dr_stage3_name"_gmcorr"
	gm_corr_string="--vxl=$vxl --vxf=$vxf"
fi



# ======= create output dir
OUTPUT=$INPUT_DIR/$ANALYSIS_NAME
mkdir -p $OUTPUT
if [ ! -d $OUTPUT ]; then echo "ERROR: could not create output dir ($OUTPUT)"; exit; fi

# ======= copy design to OUTPUT
if [[ $des_name != "mean" ]]
then
	/bin/cp $des.mat $OUTPUT/design.mat
	/bin/cp $des.con $OUTPUT/design.con
	
	if [ $EX_CHANG_BLOCK -eq 1 ]; then 
		DESIGN="$DESIGN -e $des.grp"
		/bin/cp $des.grp $OUTPUT/design.grp
	fi	
fi

# ======= create script+logs
LOGDIR=${OUTPUT}/scripts+logs
if [ ! -d $LOGDIR ]; then mkdir $LOGDIR; else  rm $LOGDIR/*; fi

#=============================================================================
echo "running randomise: $des_name on RSN: $RSN_LABEL"

RAND=""
if [ $NPERM -le 1 ] ; then
  RAND="$FSLDIR/bin/randomise -i $INPUT_DIR/$input_file_name -o $OUTPUT/$output_dr_stage3_name -m $mask $DESIGN -n 1 $gm_corr_string -V -R --uncorrp"
else
  RAND="$FSLDIR/bin/randomise -i $INPUT_DIR/$input_file_name -o $OUTPUT/$output_dr_stage3_name -m $mask $DESIGN -n $NPERM $gm_corr_string -T -V --uncorrp"
fi

echo "$RAND" >> ${LOGDIR}/drE
ID_drE=`$FSLDIR/bin/fsl_sub -T 60 -N drE -l $LOGDIR -t ${LOGDIR}/drE`
