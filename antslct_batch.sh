#!/bin/bash
#SBATCH --array=__##__LIST,OF,COMMA,DELIMITED,SUBJECT,IDS,HERE__#__
#SBATCH --job-name=antslct
#SBATCH --mail-user=__##__YOUREMAIL@HERE.COM__##__
#SBATCH --mail-type=ALL
#SBATCH --mem=40G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --output=sub-%a_%x.out
#SBATCH --time=7-00:00

# feel free to update the above settings to increase parallelization of the
# processing; if you do, you should consider also changing the -c parameter
# in the singularity run call to something larger (it determined the internal
# parallelization of the pipeline script)
#
# check https://slurm.schedmd.com/sbatch.html for more information on what the
# parameters control

# set up modules
module purge
module load singularity/2.5

# this assumes your data are stored in BIDS format at the below location:
DATADIR=/home/${USER}/project/${USER}/data
OUTDIR=${DATADIR}/derivatives/antslct
# this assumes you have access to a scratch directory!
SCRATCHDIR=/scratch/${USER}/antslct

# get BIDS-style subject info from array ID
SUBJ=sub-${SLURM_ARRAY_TASK_ID}

# make output and data directories in scratch and copy over relevant data
mkdir -p ${SCRATCHDIR}/data ${SCRATCHDIR}/output
rsync -rlu ${DATADIR}/${SUBJ} ${SCRATCHDIR}/data

# run the pipeline (note where the singularity image should be stored)
singularity run -B ${SCRATCHDIR}/data:/data                                   \
                -B ${SCRATCHDIR}/output:/output                               \
                ${DATADIR}/code/antslct.simg                                  \
                -s ${SUBJ} -o /output -c 2

# copy the output back (we don't want to lose this)
rsync -rlu ${SCRATCHDIR}/output/${SUBJ} ${OUTDIR}
rsync -rlu ${SCRATCHDIR}/output/reports/${SUBJ}.html ${OUTDIR}/reports

# get rid of the data on scratch (we don't need to but we'll be nice)
rm -fr ${SCRATCHDIR}/data/${SUBJ} ${SCRATCHDIR}/output/${SUBJ}
rm -rf ${SCRATCHDIR}/output/reports/${SUBJ}.html
