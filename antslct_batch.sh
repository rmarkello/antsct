#!/bin/bash
#SBATCH --array=SUBJECT_IDS_AS_COMMA_DELIMITED_LIST_HERE (e.g., 1,2,3,4)
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=7-00:00

#
# feel free to update the above settings to increase parallelization of the
# processing; if you do, you should consider also change the -c parameter
# in the singularity run call to something larger (it determines the internal
# parallelization of the pipeline script)
#
# check https://slurm.schedmd.com/sbatch.html for more information on what the
# parameters control
#

# set up modules (may be HPC specific)
module purge
module load singularity

# set path to BIDS data directory and desired output directory
DATADIR=/home/${USER}/project/${USER}/data
OUTDIR=${DATADIR}/derivatives/antslct

# set path to temporary scratch directory for faster data I/O
SCRATCHDIR=/scratch/${USER}/antslct

# get BIDS-style subject info from array ID
SUBJ=sub-${SLURM_ARRAY_TASK_ID}

# make output and data directories in scratch
mkdir -p ${SCRATCHDIR}/data ${SCRATCHDIR}/output

# copy over relevant input data for subject
rsync -rlu ${DATADIR}/${SUBJ} ${SCRATCHDIR}/data

# run the pipeline
# note that you may have to update the singularity image path
singularity run -B ${SCRATCHDIR}/data:/data                                   \
                -B ${SCRATCHDIR}/output:/output                               \
                ${DATADIR}/code/antslct.simg                                  \
                -s ${SUBJ} -o /output -c 1 -t 1 -m

# copy the output back to the output directory
rsync -rlu ${SCRATCHDIR}/output/${SUBJ} ${OUTDIR}
rsync -rlu ${SCRATCHDIR}/output/reports/${SUBJ}.html ${OUTDIR}/reports

# get rid of the data on scratch
rm -fr ${SCRATCHDIR}/data/${SUBJ} ${SCRATCHDIR}/output/${SUBJ}
rm -rf ${SCRATCHDIR}/output/reports/${SUBJ}.html
