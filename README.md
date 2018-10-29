# Modified ANTS Longitudinal Cortical Thickness pipeline

[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/1842)

This repository contains code for running the [ANTs longitudinal cortical thickness pipeline](https://www.biorxiv.org/content/early/2018/08/16/170209) on a [BIDS](bids.neuroimaging.io) dataset.

## Table of contents

* [Description](#description)
* [Requirements](#requirements)
* [Quickstart](#quickstart)
* [Usage](#usage)
* [Outputs](#outputs)
* [Description of files](#description-of-files)

## Description

In many respects this code is similar to the [ANTs BIDS-App](https://github.com/BIDS-Apps/antsCorticalThickness), which is designed to automatically run the ANTs cortical thickness pipeline on a formatted BIDS datasets. However, this pipeline has a few notable differences from the BIDS App, including:

1. Automated use of additional data modalities as inputs to the pipeline, as available
2. Use of the [MNI152 ICBM nonlinear asymmetric 2009c](http://www.bic.mni.mcgill.ca/ServicesAtlases/ICBM152NLin2009) atlas as the default group template
3. Use of [labelled template files](https://drive.google.com/drive/folders/0B4SvObeEfaRyZGhlUlJOcmItTVU?usp=sharing) for better image segmentation using ANTs [joint label fusion](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3837555/)
4. Generation of additional output files (see [outputs](#outputs))
5. Generation of [fMRIPrep-style visual reports](https://fmriprep.readthedocs.io/en/stable/outputs.html#visual-reports) to aid in quality control

It was originally designed for analyzing the [PPMI](http://www.ppmi-info.org/) dataset, but should be applicable to other datasets, as well.

## Requirements

* [Singularity](https://github.com/sylabs/singularity/releases) v2.4 or higher (N.B. this has only been tested with Singularity 2.4 and 2.5)

## Quickstart

The recommended way to get things running is:

```bash
singularity pull shub://rmarkello/antslct
singularity run -B /path/to/bids/data:/data                                   \
                -B /path/to/output:/output                                    \
                antslct.simg                                                  \
                -s subject_ids_to_process
```

If you have access to an HPC cluster with a SLURM job scheduler check out [`antslct_batch.sh`](antslct_batch.sh) for an example script to run the pipeline.

If you'd prefer to build the Singularity container locally, you can do so with:

```bash
sudo singularity build antslct.simg Singularity
```

Note that this requires root permissions, so the first option is preferred.

## Usage

The primary script, contained in [`code/antslct.sh`](code/antslct.sh), provides the following information:

``` # noqa
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
```

## Outputs

This code will generate all of the "normal" ANTsLongitudinalCorticalThickness.sh outputs in the specified output directory, but will also create several additional derivatives:

1. `sub-XXXX_*_jacobian.nii.gz`: log jacobian determinant image of the concatenated non-linear warps (subject &rarr; subject-specific template AND subject-specific template &rarr; group template) for a single timepoint, in MNI space
2. `sub-XXXX_*_corticalthickness.nii.gz`: cortical thickness image for a single timepoint, in MNI space
3. `sub-XXX.html`: a visual report with images for checking the quality of the segmentation and registration for the generated subject-specific template and all individual timepoints

## Description of files

`./`

* `antslct_batch.sh`: Example code for submitting a job to a HPC cluster with a SLURM job scheduler. Note that using this requires a few edits&mdash;check the script for comments
* `environment.yml`: File specifying the [`conda`](https://conda.io/docs/) environment required for running `code/report.py` within the Singularity container`
* `generate_singularity.sh`: Code used to generate the Singularity recipe file. This script uses [`neurodocker`](https://github.com/kaczmarj/neurodocker), so running it will require that you have [Docker](https://www.docker.com/) installed

`code/`  

* `antslct.sh`: The primary script that is called when the Singularity image is invoked with `singularity run`
* `report.py`: Code called by `antslct.sh` to generate the visual reports
* `report.tpl`: Template used by `report.py` to create the HTML files for the visual reports

`data/`

* `segment_mni.sh`: Code used to generate an ANTs-ready group template from the original MNI152 ICBM nonlinear asymmetric 2009c atlas. The MNI atlas does not come with the required tissue priors that ANTs expects (CSF, cortical gray matter, white matter, subcortical gray matter, brainstem, cerebellum), so this script uses a combination of ANTs tools and the provided atlas files to create them. It should not need to be re-run as the output files are available on [figshare]("https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46").
