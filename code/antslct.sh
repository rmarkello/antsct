#!/usr/bin/env bash

function Usage {
    cat << USAGE

Description:

    antslct runs ANTs' longtiudinalCorticalThicknessPipeline.sh on data
    organized in BIDS format (see bids.neuroimaging.io for more information).
    Once complete, it uses the output warp files to generate Jacobian
    determinant images.

    This script assumes that each provided subject has AT LEAST one T1w
    anatomical image; more images can be provided (either longitudinally or
    multimodally) and will be utilized in processing (see
    https://github.com/ANTsX/ANTs/ for more info).

    Note if multimodal images are provided, they must be present for every
    session (assuming there are also multiple sessions) for them to be used.
    This script only does minor checks for this, and tends to be more
    conservative (i.e., not including a modality if it thinks it isn't present
    across all sessions).

    This will output all the relevant files AND create an fmriprep-style report
    for visually inspecting the nonlinear registration and segementation. This
    will be saved as sub-XXX.html in the subject output directory.

Usage:

    $ docker_opts="--rm -v /path/to/data:/data:ro -v /path/to/output:/output"
    $ docker run \${docker_opts} antslct -s sub-001

        OR

    $ singularity_opts="-B /path/to/data:/data:ro -B /path/to/output:/output"
    $ singularity run \${singularity_opts} antslct.simg -s sub-001

Required arguments:

    -s: subject directory       Subject directory, accessible in /data,
                                organized in BIDS format. If more than one
                                subject is supplied (by calling -s multiple
                                times) the pipeline will iterate over subjects
                                and be run on each *serially*.

 Optional arguments:

    -o: output directory        Output directory. Assumes /output by default,
                                but alternative can be specified. Either way,
                                make sure you bind something to this or else
                                your data won't be saved!
    -c: number of cpu cores     Determines how many CPU cores to try and use
                                with PEXEC (parallel execution on localhost).
                                In order to maximize speed, this program will
                                check to see the number of available cores and
                                set ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS equal
                                to # available cores / the arugment provided
                                here (to a minimum of 1). Default: 2

USAGE
    exit 0
}

export ANTSPATH=/opt/ants/                           # path to ANTS directory
export TEMP_DIR=/opt/data/mni_template               # MNI152 2009c with priors
export MALF_DIR=/opt/data/miccai                     # Mindboggle brains
export OUT_DIR=/output                               # default output directory
MODALITIES=( T2w PD FLAIR echo-1_PDT2 echo-2_PDT2 )  # possible non-T1w anats
CORES=2                                              # default number of CPUs
SUBJECTS=()

# get arguments
if [[ $# -lt 2 ]]; then
    Usage >&2
    exit 1
else
    while getopts "c:h:o:s:" OPT; do
        case $OPT in
                c)
            CORES=$OPTARG
            ;;
                h)
            Usage >&2
            exit 0
            ;;
                o)
            OUT_DIR=$OPTARG
            ;;
                s)
            SUBJECTS+=("$OPTARG")
            ;;
        esac
    done
fi

# make sure at least one subject was provided
if [ ${#SUBJECTS[@]} -eq 0 ]; then
    echo "++ ERROR: Need to provide at least one subject directory to process."
    Usage >&2
    exit 1
fi

# we'll multithread registration based on the # of available CPU cores and how
# much we want to parallelize the data (see argument -c)
# first, check if we're using SBATCH and get the number of available cores
# otherwise, use nproc
if [ ! -z "${SLURM_NTASKS}" ]; then
    TOT_CORES=$SLURM_NTASKS; else
    TOT_CORES=$( nproc )
fi

# set the ITK GLOBAL THREADS for multithreading of antsRegistration
THREADS=$( echo "${TOT_CORES}/${CORES}" | bc )
if [ ${THREADS} -lt 1 ]; then THREADS=1; fi
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${THREADS}

# iterate through provided subjects
for subject in "${SUBJECTS[@]}"; do
    SUBJ_DIR=/data/${subject}               # subject directory based on input
    OUTPUT_DIR=${OUT_DIR}/${subject}        # where ALL output will live
    ALIGN_DIR=${OUTPUT_DIR}/coreg           # where linearly coregistered data
    SUB=${subject/sub-/}

    # make sure subject directory exists
    if [ ! -d ${SUBJ_DIR} ]; then echo "${SUBJ_DIR} doesn't exist."; exit 1; fi

    # determine where anatomical data lives (either one session or multiple)
    sessions=${SUBJ_DIR}/anat
    if [ ! -d ${sessions} ]; then
        sessions=$( find ${SUBJ_DIR} -not -empty -type d -name "ses-*" | sort )
        sessions=( $( for ses in ${sessions}; do echo ${ses}/anat; done ) )
    fi

    # make sure that there is *at least* one T1w image to run
    anatomicals=(); ses_nums=()
    for ses in ${sessions[@]}; do
        if [ ! -d ${ses} ]; then continue; fi
        ses_num=$( basename $( dirname ${ses} ) ); ses_nums+=("${ses_num}")
        t1w=$( find ${ses} -type f -name "sub-${SUB}*${ses_num}*T1w.nii.gz" )
        if [ -f ${t1w} ]; then anatomicals+=("${t1w}"); fi
    done
    if [ "${#anatomicals[@]}" -eq 0 ]; then
        echo "There do not appear to be any T1w files in ${SUBJ_DIR}"; exit 1
    fi

    if [ ! -d ${ALIGN_DIR} ]; then mkdir -p ${ALIGN_DIR}; fi; cd ${SUBJ_DIR}

    # linearly align (rigid body, 6 DOF) all modalities to the T1w image from
    # session and put all output in ${ALIGN_DIR}
    long_inputs=()
    for fixed in ${anatomicals[@]}; do
        # copy T1w anatomical to "coreg" directory and add to inputs for LCT
        cp -v ${fixed} ${ALIGN_DIR}
        long_inputs+=("${ALIGN_DIR}/$( basename ${fixed} )")

        # iterate through other modalities, appending to inputs for LCT, and
        # register to T1w image for given session
        for dtype in "${MODALITIES[@]}"; do
            # make sure that there are an equal number of given dtype and T1ws;
            # if there aren't, we can't use this file otherwise the CT pipeline
            # will be thrown off from an uneven number of modalities/inputs
            n_dtype=$( find ${ses_nums[@]} -name "*${dtype}.nii.gz" | wc -l )
            if [ "${n_dtype}" -lt "${#anatomicals[@]}" ]; then continue; fi

            # get filename for moving image and skip if it doesn't exist
            # this should hypothetically never get triggered due to the above
            # but gonna keep it here for posterity's sake
            moving=${fixed/T1w/${dtype}};
            if [ ! -f ${moving} ]; then continue; fi

            # create output name and add to input string for LCT pipeline
            output=${ALIGN_DIR}/$( basename ${moving%%.*} )
            long_inputs+=("${output}.nii.gz")

            # if registration was already run, don't do it again...
            if [ -f ${output}.nii.gz ]; then
                echo "${fixed##*/} already exists; skipping this registration."

            # run the rigid body registration to the T1w; this is basically
            # the same as a call to antsRegistrationSyN but w/the output names
            # specified a bit differently than that script allows
            else
                echo "Linearly registering ${moving##*/} to ${fixed##*/}."
                antsRegistration                                              \
                    --dimensionality 3                                        \
                    --float 0                                                 \
                    --output [${output},${output}.nii.gz,${output}inv.nii.gz] \
                    --interpolation Linear                                    \
                    --use-histogram-matching 0                                \
                    --winsorize-image-intensities [0.005,0.995]               \
                    --initial-moving-transform [${fixed},${moving},1]         \
                    --transform Rigid[0.1]                                    \
                    --metric MI[${fixed},${moving},1,32,Regular,0.25]         \
                    --convergence [1000x500x250x100,1e-6,10]                  \
                    --shrink-factors 8x4x2x1                                  \
                    --smoothing-sigmas 3x2x1x0vox
            fi
        done
    done

    # get atlases and labels for Joint Label Fusion
    atlases=''
    for lab in `ls ${MALF_DIR}/*labels.nii.gz`; do
        atlas=$( echo $lab | cut -d '_' -f1,2 )_BrainCerebellum.nii.gz
        atlases="${atlases} -a ${atlas} -l ${lab}"
    done

    # get number of modalities based on number of T1ws and number of inputs
    num_mod=$( echo "${#long_inputs[@]}/${#anatomicals[@]}" | bc )

    # run longitudinal cortical thickness pipeline using all modalities
    # this can take a couple of day, so...do something else for a while?
    command="antsLongitudinalCorticalThickness.sh                             \
                -d 3                                                          \
                -e ${TEMP_DIR}/template.nii.gz                                \
                -m ${TEMP_DIR}/template_brain_probability_mask.nii.gz         \
                -p ${TEMP_DIR}/prior%d.nii.gz                                 \
                -t ${TEMP_DIR}/template_brain.nii.gz                          \
                -f ${TEMP_DIR}/template_brain_registration_mask.nii.gz        \
                -g 1 -c 2 -j ${CORES} -q 0 -k ${num_mod}                      \
                ${atlases}                                                    \
                -o ${OUTPUT_DIR}/sub-${SUB}_CT                                \
                ${long_inputs[@]}"

    # save the command to a txt file for posterity and then run it
    echo ${command} >> ${OUTPUT_DIR}/sub-${SUB}_antscommand.txt
    ${command}

    # if the command errored we don't want to continue (we likely can't!)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    # now we need to create the Jacobian images
    # we only want the nonlinear warps, but we need the SST --> visit warp to
    # be in the same space as the template --> SST warp, so we have to do some
    # rather annoying transformation
    anatomicals=( $( for f in ${anatomicals[@]}; do basename ${f%%.*}; done ) )
    suffixes=( `eval echo {0..$( echo "${#anatomicals[@]}-1" | bc )}` )
    sst_dir=${OUTPUT_DIR}/sub-${SUB}_CTSingleSubjectTemplate

    # affine for transforming SST --> visit warps into template space
    sst_to_group_mat=${sst_dir}/T_templateSubjectToTemplate0GenericAffine.mat

    # template --> SST warp to combine with SST --> visit warp
    group_to_sst_war=${sst_dir}/T_templateTemplateToSubject0Warp.nii.gz

    for index in ${!anatomicals[*]}; do
        # get input files and whatnot
        anat=${anatomicals[$index]}; suff=${suffixes[$index]}
        warp_dir=${OUTPUT_DIR}/${anat}_${suff}
        warp=${warp_dir}/${anat}TemplateToSubject0Warp.nii.gz

        # convert displacement field into vector images and warp to template
        ConvertImage 3 ${warp} ${warp/.nii.gz/} 10
        for j in xvec yvec zvec; do
            antsApplyTransforms                                               \
                -d 3 -v 1                                                     \
                -r ${TEMP_DIR}/template.nii.gz                                \
                -i ${warp/.nii.gz/}${j}.nii.gz                                \
                -o ${warp/.nii.gz/}${j}.nii.gz                                \
                -t ${sst_to_group_mat}
        done

        # convert vectors into displacement field and combine nonlinear warps
        ConvertImage 3 ${warp/.nii.gz/} ${warp/.nii.gz/_tempspace.nii.gz} 9
        rm ${warp/.nii.gz/}{x,y,z}vec.nii.gz
        combo_warp=${warp_dir}/${anat}_nonlinearwarps.nii.gz
        antsApplyTransforms                                                   \
            -d 3 -v 1                                                         \
            -r ${TEMP_DIR}/template.nii.gz                                    \
            -o [${combo_warp},1]                                              \
            -t ${warp/.nii.gz/_tempspace.nii.gz}                              \
            -t ${group_to_sst_war}

        # create ouput jacobian determinant image (log and geometric)
        # these will be images where a POSITIVE value indicates relative
        # subject atrophy, and a NEGATIVE value indicates relative subject
        # expansion as compared to the TEMPLATE BRAIN. images will be in
        # TEMPLATE SPACE, and thus comparable across individuals
        jacobian=${OUTPUT_DIR}/${anat}_jacobian.nii.gz
        CreateJacobianDeterminantImage 3 ${combo_warp} ${jacobian} 1 1

        # let's also drag along the cortical thickness to group space
        antsApplyTransforms                                                   \
            -d 3 -v 1                                                         \
            -r ${TEMP_DIR}/template.nii.gz                                    \
            -i ${warp_dir}/${anat}CorticalThickness.nii.gz                    \
            -o ${OUTPUT_DIR}/${anat}_corticalthickness.nii.gz                 \
            -t ${warp_dir}/${anat}SubjectToGroupTemplateWarp.nii.gz
    done

    # generate html report
    source activate antslct; py=`which python`
    $py /opt/report.py -s ${OUTPUT_DIR} -t ${TEMP_DIR} -o ${OUT_DIR}
done
