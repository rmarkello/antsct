#!/usr/bin/env bash
#
# Downloads MNI ICBM152 2009c 1x1x1 asymmetrical template and creates priors as
# required by ANTS using the priors/brain mask provided with the template as a
# basis and then improving (?) them with the MICCAI labelled images.
# This should only need to be done ONCE and ideally will have already been
# done during the creation of the Singularity container.

WORK_DIR=/opt/data; cd ${WORK_DIR}
MALF_DIR=${WORK_DIR}/miccai
DATA_DIR=${WORK_DIR}/mni_2009c_asym
OUTPUT_DIR=${WORK_DIR}/mni_template

# download original MNI template
if [ ! -d ${DATA_DIR} ]; then
    TEMP_FILE=mni_icbm152_nlin_asym_09c_nifti.zip
    wget http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/${TEMP_FILE}
    unzip ${TEMP_FILE} -d ${DATA_DIR}; rm -fr ${TEMP_FILE}
    mv ${DATA_DIR}/${TEMP_FILE%%_nifti.zip}/* ${DATA_DIR}
    rmdir ${DATA_DIR}/${TEMP_FILE%%_nifti.zip}
    for image in `ls ${DATA_DIR}/*nii`; do gzip ${image}; done
fi

# first, copy over original template and brain mask
input_template=${OUTPUT_DIR}/template.nii.gz
input_mask=${OUTPUT_DIR}/template_brain_mask.nii.gz
cp ${DATA_DIR}/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz ${input_template}
cp ${DATA_DIR}/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz ${input_mask}

# extract brain from template
template_brain=${OUTPUT_DIR}/template_brain.nii.gz
ImageMath 3 ${template_brain} m ${input_mask} ${input_template}

# generate brain probability mask
input_prob_mask=${OUTPUT_DIR}/template_brain_probability_mask.nii.gz
SmoothImage 3 ${input_mask} 1 ${input_prob_mask}

# create the JointLabelFusion command using atlases/labels from MICCAI
command="antsJointLabelFusion.sh -d 3 -o ${OUTPUT_DIR}/jlf_"
command="${command} -t ${template_brain}"
for lab in `ls ${MALF_DIR}/*labels.nii.gz`; do
    atlas=$( echo $lab | cut -d '_' -f1,2 )_BrainCerebellum.nii.gz
    command="${command} -g ${atlas} -l ${lab}"
done

# run JointLabelFusion (go get lunch)
${command}

# get tissue types from labelled image and smooth to create priors
label_image=${OUTPUT_DIR}/template_brain_6labelsJF.nii.gz
mv ${OUTPUT_DIR}/jlf_Labels.nii.gz ${label_image}
for (( j=1; j<=6; j++)); do
    prior=${OUTPUT_DIR}/prior${j}.nii.gz
    ThresholdImage 3 ${label_image} ${prior} ${j} ${j} 1 0
    SmoothImage 3 ${prior} 1 ${prior}
done

# get the CSF prior provided with the MNI template and compare with calculated
# take MAX value of two (i.e., be very liberal about what we consider CSF)
csf_prior=${OUTPUT_DIR}/csf_prior.nii.gz; prior1=${OUTPUT_DIR}/prior1.nii.gz
cp ${DATA_DIR}/mni_icbm152_csf_tal_nlin_asym_09c.nii.gz ${csf_prior}
ImageMath 3 ${prior1} max ${prior1} ${csf_prior}

# subtract CSF prior from all other priors
tmp=${OUTPUT_DIR}/temporary.nii.gz
for (( j=2; j<=6; j++ )); do
    prior=${OUTPUT_DIR}/prior${j}.nii.gz
    ImageMath 3 $prior - $prior $prior1
    ThresholdImage 3 $prior $tmp 0 1 1 0
    ImageMath 3 $prior m $prior $tmp
done

# now let's zeropad our images and create a "registration mask" by dilating the
# brain mask. this can be used in the antsCorticalThickness.sh pipeline
for fname in ${OUTPUT_DIR}/*.nii.gz; do
    ImageMath 3 ${fname} PadImage ${fname} 30
done
registration_mask=${OUTPUT_DIR}/template_brain_registration_mask.nii.gz
ImageMath 3 ${registration_mask} MD ${input_mask} 30

# remove unnecessary outputs
rm -fr $tmp ${OUTPUT_DIR}/jlf_* ${DATA_DIR}
