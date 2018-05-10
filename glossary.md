# Glossary

The code in this repository relies on two major pipelines:

1.  ANTs' [`antsLongitudinalCorticalThickness.sh`](https://github.com/ANTsX/ANTs/blob/master/Scripts/antsLongitudinalCorticalThickness.sh), and
2.  FreeSurfer's [`recon-all`](https://surfer.nmr.mgh.harvard.edu/fswiki/recon-all)

Both of these pipelines output *a lot* of files, many of which aren't named in intuitive ways. Moreover, the [current](https://github.com/ANTsX/ANTs/wiki/antsCorticalThickness-and-antsLongitudinalCorticalThickness-output) [documentation](https://surfer.nmr.mgh.harvard.edu/fswiki/ReconAllOutputFiles) for both pipelines isn't quite as descriptive as a new user might appreciate. This glossary is an attempt to remedy some of that!


## ANTs Longitudinal Cortical Thickness
Let's assume we called the ANTs pipeline using the following command, supplying longitudinal data for a single subject from three timepoints:

```
antsLongitudinalCorticalThickness.sh \
    -d 3 \
    -e template.nii.gz \
    -t template_brain.nii.gz \
    -p template_brain_prior%d.nii.gz \
    -m template_brain_probability_mask.nii.gz \
    -f template_brain_registration_mask.nii.gz \
    -o /out/sub-001_output \
    -g 1 \
    sub-001_ses-1_T1w.nii.gz sub-001_ses-2_T1w.nii.gz sub-001_ses-3_T1w.nii.gz
```

Ideally, we would supply the full filepaths to all the NIFTI files in this command, but for the sake of this example I'll omit them.

### Inputs
First, we'll take a quick run through of what the inputs represent (though calling `antsLongitudinalCorticalThickness.sh -h` will provide some very detailed information on this, as well!).

* `-d 3`: This indicates the dimensionality of the inputs. ANTs can work with both slice (2D) and volumetric (3D) data. We are supplying 3D, volumetric (T1w) data so we specify `-d 3`. This is a *required* parameter.

* `-e template.nii.gz`: This is the (non-skull-stripped) group template that will be used to aid in (1) skull-stripping and (2) segmentation. This is a *required* parameter.

* `-t template_brain.nii.gz`: This is the skull-stripped version of `-e template.nii.gz`. Providing this will ensure that the subject data are registered to the template (e.g., "normalized" to group space). This is an *optional* parameters (default: no normalization).

* `-p template_brain_prior%d.nii.gz`: These are the tissue probability priors corresponding to `-e template.nii.gz`. There MUST be at least 4 priors, named `template_brain_prior1.nii.gz` through `template_brain_prior4.nii.gz`, corresponding to (1) cerebrospinal fluid, (2) cortical gray matter, (3) white matter, and (4) deep (subcortical) gray matter. This is a *required* parameter.

* `-m template_brain_probability_mask.nii.gz`: This is a probability mask depicting where the brain is in `-e template.nii.gz`. This is a *required* parameter.

* `-f template_brain_registration_mask.nii.gz`: This is a binary mask depicting This is an *optional* parameter (default: no aid in brain registration/extraction).

* `-o /out/sub-001_output`: This indicates the path (`/out`) where the output data will saved and the prefix (`sub-001_output`) that will be prepended to one of the created output directories. This is a *required* parameter.

* `-g 1`: This indicates that we would like the provided input images to be denoised before processing through the pipeline. The denoising procedure uses ANTs' [`DenoiseImage`](https://github.com/ANTsX/ANTs/blob/master/Examples/DenoiseImage.cxx) function, which is based on the algorithm described in [Manjon et al., 2010](https://www.ncbi.nlm.nih.gov/pubmed/20027588). This is an *optional* parameter (default: `-g 0`).

* `sub-001_ses-1_T1w.nii.gz sub-001_ses-2_T1w.nii.gz sub-001_ses-3_T1w.nii.gz`: These are the input data. Each file is a 3D anatomical (T1w) image from a separate timepoint. More (or fewer) timepoints can be supplied by including additional files; the inputs need only be separated by a space on the command line. This is a *required* parameter; at least one file must be supplied.

### Outputs
Four directories will be created by the example command, above.

```
/out
├── sub-001_outputSingleSubjectTemplate/
├── sub-001_ses-1_T1w_0/
├── sub-001_ses-2_T1w_1/
└── sub-001_ses-3_T1w_2/
```

#### sub-001_outputSingleSubjectTemplate/

* `T_template0.nii.gz`:

* `T_templateACTStage?Complete.txt`: Where `?` is be a number [1-6].

* `T_templateBrainExtractionBrain.nii.gz`:

* `T_templateBrainExtractionMask.nii.gz`:

* `T_templateBrainExtractionMaskPrior.nii.gz`:

* `T_templateBrainExtractionRegistrationMask.nii.gz`:

* `T_templateBrainNormalizedToTemplate.nii.gz`:

* `T_templateBrainSegmentation0N4.nii.gz`:

* `T_templateBrainSegmentationConvergence.txt`:

* `T_templateBrainSegmentation.nii.gz`:

* `T_templateBrainSegmentationPosteriors?.nii.gz`: Where `?` is be a number [1-6].

* `T_templateBrainSegmentationTiledMosaic.png`:

* `T_templatebrainvols.csv`:

* `T_templateCorticalThickness.nii.gz`:

* `T_templateCorticalThicknessNormalizedToTemplate.nii.gz`:

* `T_templateCorticalThicknessTiledMosaic.png`:

* `T_templateExtractedBrain0N4.nii.gz`:

* `T_templateIntensity.nii.gz`:

* `T_templateLabels.nii.gz`:

* `T_templatePriors?.nii.gz`: Where `?` is be a number [1-6].

* `T_templateRegistrationTemplateBrainMask.nii.gz`:

* `T_templateSubjectToTemplate0GenericAffine.mat`:

* `T_templateSubjectToTemplate1Warp.nii.gz`:

* `T_templateSubjectToTemplateLogJacobian.nii.gz`:

* `T_templateTemplateToSubject0Warp.nii.gz`:

* `T_templateTemplateToSubject1GenericAffine.mat`:

#### sub-001_ses-?\_T1w_?/
The three remaining directories `sub-001_ses-1_T1w_0`, `sub-001_ses-2_T1w_1`, and `sub-001_ses-3_T1w_2` will all have the same structure; they only differ insomuch as they are based on the different provided timepoints. We will only go through the first as an exemplar.

* `sub-3182_ses-1_run-01_T1wACTStage?Complete.txt`: Where `?` is be a number [1-6].

* `sub-3182_ses-1_run-01_T1wBrainExtractionMask.nii.gz`:

* `sub-3182_ses-1_run-01_T1wBrainNormalizedToTemplate.nii.gz`:

* `sub-3182_ses-1_run-01_T1wBrainSegmentation0N4.nii.gz`:

* `sub-3182_ses-1_run-01_T1wBrainSegmentation1N4.nii.gz`:

* `sub-3182_ses-1_run-01_T1wBrainSegmentation2N4.nii.gz`:

* `sub-3182_ses-1_run-01_T1wBrainSegmentationConvergence.txt`:

* `sub-3182_ses-1_run-01_T1wBrainSegmentation.nii.gz`:

* `sub-3182_ses-1_run-01_T1wBrainSegmentationPosteriors?.nii.gz`: Where `?` is be a number [1-6].

* `sub-3182_ses-1_run-01_T1wBrainSegmentationTiledMosaic.png`:

* `sub-3182_ses-1_run-01_T1wbrainvols.csv`:

* `sub-3182_ses-1_run-01_T1wCorticalThickness.nii.gz`:

* `sub-3182_ses-1_run-01_T1wCorticalThicknessNormalizedToTemplate.nii.gz`:

* `sub-3182_ses-1_run-01_T1wCorticalThicknessTiledMosaic.png`:

* `sub-3182_ses-1_run-01_T1wExtractedBrain0N4.nii.gz`:

* `sub-3182_ses-1_run-01_T1wGroupTemplateToSubjectWarp.nii.gz`:

* `sub-3182_ses-1_run-01_T1wRegistrationTemplateBrainMask.nii.gz`:

* `sub-3182_ses-1_run-01_T1wSubjectToGroupTemplateWarp.nii.gz`:

* `sub-3182_ses-1_run-01_T1wSubjectToTemplate0GenericAffine.mat`:

* `sub-3182_ses-1_run-01_T1wSubjectToTemplate1Warp.nii.gz`:

* `sub-3182_ses-1_run-01_T1wSubjectToTemplateLogJacobian.nii.gz`:

* `sub-3182_ses-1_run-01_T1wTemplateToSubject0Warp.nii.gz`:

* `sub-3182_ses-1_run-01_T1wTemplateToSubject0Warp_tempspace.nii.gz`:

* `sub-3182_ses-1_run-01_T1wTemplateToSubject1GenericAffine.mat`:


## FreeSurfer recon-all

Let's assume we called the FreeSurfer pipeline using the following command, supplying the anatomical from a single timepoint (we will discuss longitudinal data later).

```
recon-all -all -s sub-001_output -sd /out -i sub-001_ses-1_T1w.nii.gz
```

Ideally, we would supply the full filepaths to the T1w file in this command, but for the sake of this example I'll omit it.

### Inputs

* `-all`: This indicates that we want the entire (i.e., `all` of the) `recon-all` pipeline to be run on the input data. If we were only interested in certain parts of the pipeline, we could [specify that instead](https://surfer.nmr.mgh.harvard.edu/fswiki/recon-all#Manual-InterventionWorkflowDirectives). This is a *required* parameter.

* `-s sub-001_output`: This indicates the name of the output directory (`sub-001_output`) that will be created. This is a *required* parameter.

* `-sd /out`: For better or worse, FreeSurfer relies on a significant number of environmental variables. One of those variables it expects to be set is `${SUBJECTS_DIR}`, which will generally point to a subdirectory of the location where you installed FreeSurfer. By including `-sd /out` in our command, we are explicitly specifying that we want to ignore that environmental variable and use `/out` as the location where our output data will be saved. This is an *optional* parameter (default: `${SUBJECTS_DIR}`).

* `-i sub-001_ses-1_T1w.nii.gz`: This is the input datafile. It is a 3D anatomical (T1w) image from a single timepoint. This is a *required* parameter.

### Outputs

Twekve directories will be created by the example command, above.

```
/out
└── sub-001_output/
    ├── label/
    ├── mri/
    |   ├── orig
    |   └── transforms
    |       └── bak
    ├── scripts/
    ├── stats/
    ├── surf/
    ├── tmp/
    ├── touch/
    └── trash/
```

#### label/
* `aparc.annot.a2009s.ctab`:

* `aparc.annot.ctab`:

* `aparc.annot.DKTatlas.ctab`:

* `BA_exvivo.ctab`:

* `BA_exvivo.thresh.ctab`:

* `lh.aparc.a2009s.annot`:

* `lh.aparc.annot`:

* `lh.aparc.DKTatlas.annot`:

* `lh.BA1_exvivo.label`:

* `lh.BA1_exvivo.thresh.label`:

* `lh.BA2_exvivo.label`:

* `lh.BA2_exvivo.thresh.label`:

* `lh.BA3a_exvivo.label`:

* `lh.BA3a_exvivo.thresh.label`:

* `lh.BA3b_exvivo.label`:

* `lh.BA3b_exvivo.thresh.label`:

* `lh.BA44_exvivo.label`:

* `lh.BA44_exvivo.thresh.label`:

* `lh.BA45_exvivo.label`:

* `lh.BA45_exvivo.thresh.label`:

* `lh.BA4a_exvivo.label`:

* `lh.BA4a_exvivo.thresh.label`:

* `lh.BA4p_exvivo.label`:

* `lh.BA4p_exvivo.thresh.label`:

* `lh.BA6_exvivo.label`:

* `lh.BA6_exvivo.thresh.label`:

* `lh.BA_exvivo.annot`:

* `lh.BA_exvivo.thresh.annot`:

* `lh.cortex.label`:

* `lh.entorhinal_exvivo.label`:

* `lh.entorhinal_exvivo.thresh.label`:

* `lh.MT_exvivo.label`:

* `lh.MT_exvivo.thresh.label`:

* `lh.perirhinal_exvivo.label`:

* `lh.perirhinal_exvivo.thresh.label`:

* `lh.V1_exvivo.label`:

* `lh.V1_exvivo.thresh.label`:

* `lh.V2_exvivo.label`:

* `lh.V2_exvivo.thresh.label`:

* `rh.aparc.a2009s.annot`:

* `rh.aparc.annot`:

* `rh.aparc.DKTatlas.annot`:

* `rh.BA1_exvivo.label`:

* `rh.BA1_exvivo.thresh.label`:

* `rh.BA2_exvivo.label`:

* `rh.BA2_exvivo.thresh.label`:

* `rh.BA3a_exvivo.label`:

* `rh.BA3a_exvivo.thresh.label`:

* `rh.BA3b_exvivo.label`:

* `rh.BA3b_exvivo.thresh.label`:

* `rh.BA44_exvivo.label`:

* `rh.BA44_exvivo.thresh.label`:

* `rh.BA45_exvivo.label`:

* `rh.BA45_exvivo.thresh.label`:

* `rh.BA4a_exvivo.label`:

* `rh.BA4a_exvivo.thresh.label`:

* `rh.BA4p_exvivo.label`:

* `rh.BA4p_exvivo.thresh.label`:

* `rh.BA6_exvivo.label`:

* `rh.BA6_exvivo.thresh.label`:

* `rh.BA_exvivo.annot`:

* `rh.BA_exvivo.thresh.annot`:

* `rh.cortex.label`:

* `rh.entorhinal_exvivo.label`:

* `rh.entorhinal_exvivo.thresh.label`:

* `rh.MT_exvivo.label`:

* `rh.MT_exvivo.thresh.label`:

* `rh.perirhinal_exvivo.label`:

* `rh.perirhinal_exvivo.thresh.label`:

* `rh.V1_exvivo.label`:

* `rh.V1_exvivo.thresh.label`:

* `rh.V2_exvivo.label`:

* `rh.V2_exvivo.thresh.label`:

#### mri/
* `aparc.a2009s+aseg.mgz`:

* `aparc+aseg.mgz`:

* `aparc.DKTatlas+aseg.mgz`:

* `aseg.auto.mgz`:

* `aseg.auto_noCCseg.label_intensities.txt`:

* `aseg.auto_noCCseg.mgz`:

* `aseg.mgz`:

* `aseg.presurf.hypos.mgz`:

* `aseg.presurf.mgz`:

* `brain.finalsurfs.mgz`:

* `brainmask.auto.mgz`:

* `brainmask.mgz`:

* `brain.mgz`:

* `ctrl_pts.mgz`:

* `filled.mgz`:

* `lh.ribbon.mgz`:

* `mri_nu_correct.mni.log`:

* `mri_nu_correct.mni.log.bak`:

* `norm.mgz`:

* `nu.mgz`:

* `orig`:

* `orig.mgz`:

* `orig_nu.mgz`:

* `rawavg.mgz`:

* `rh.ribbon.mgz`:

* `ribbon.mgz`:

* `segment.dat`:

* `T1.mgz`:

* `talairach.label_intensities.txt`:

* `talairach.log`:

* `talairach_with_skull.log`:

* `transforms`:

* `wm.asegedit.mgz`:

* `wm.mgz`:

* `wmparc.mgz`:

* `wm.seg.mgz`:

#### mri/orig/
* `001.mgz`:

#### mri/transforms/
* `cc_up.lta`:

* `talairach.auto.xfm`:

* `talairach.auto.xfm.lta`:

* `talairach_avi.log`:

* `talairach_avi_QA.log`:

* `talairach.lta`:

* `talairach.m3z`:

* `talairach_with_skull.lta`:

* `talairach.xfm`:

* `talsrcimg_to_711-2C_as_mni_average_305_t4_vox2vox.txt`:

#### scripts/
* `build-stamp.txt`:

* `lastcall.build-stamp.txt`:

* `patchdir.txt`:

* `pctsurfcon.log`:

* `pctsurfcon.log.old`:

* `ponscc.cut.log`:

* `recon-all.cmd`:

* `recon-all.done`:

* `recon-all.env`:

* `recon-all.local-copy`:

* `recon-all.log`:

* `recon-all-status.log`:

##### stats/
* `aseg.stats`:

* `lh.aparc.a2009s.stats`:

* `lh.aparc.DKTatlas.stats`:

* `lh.aparc.pial.stats`:

* `lh.aparc.stats`:

* `lh.BA_exvivo.stats`:

* `lh.BA_exvivo.thresh.stats`:

* `lh.curv.stats`:

* `lh.w-g.pct.stats`:

* `rh.aparc.a2009s.stats`:

* `rh.aparc.DKTatlas.stats`:

* `rh.aparc.pial.stats`:

* `rh.aparc.stats`:

* `rh.BA_exvivo.stats`:

* `rh.BA_exvivo.thresh.stats`:

* `rh.curv.stats`:

* `rh.w-g.pct.stats`:

* `wmparc.stats`:

##### surf/
* `lh.area`:

* `lh.area.mid`:

* `lh.area.pial`:

* `lh.avg_curv`:

* `lh.curv`:

* `lh.curv.pial`:

* `lh.defect_borders`:

* `lh.defect_chull`:

* `lh.defect_labels`:

* `lh.inflated`:

* `lh.inflated.H`:

* `lh.inflated.K`:

* `lh.inflated.nofix`:

* `lh.jacobian_white`:

* `lh.orig`:

* `lh.orig.nofix`:

* `lh.pial`:

* `lh.qsphere.nofix`:

* `lh.smoothwm`:

* `lh.smoothwm.BE.crv`:

* `lh.smoothwm.C.crv`:

* `lh.smoothwm.FI.crv`:

* `lh.smoothwm.H.crv`:

* `lh.smoothwm.K1.crv`:

* `lh.smoothwm.K2.crv`:

* `lh.smoothwm.K.crv`:

* `lh.smoothwm.nofix`:

* `lh.smoothwm.S.crv`:

* `lh.sphere`:

* `lh.sphere.reg`:

* `lh.sulc`:

* `lh.thickness`:

* `lh.volume`:

* `lh.w-g.pct.mgh`:

* `lh.white`:

* `lh.white.H`:

* `lh.white.K`:

* `lh.white.preaparc`:

* `lh.white.preaparc.H`:

* `lh.white.preaparc.K`:

* `rh.area`:

* `rh.area.mid`:

* `rh.area.pial`:

* `rh.avg_curv`:

* `rh.curv`:

* `rh.curv.pial`:

* `rh.defect_borders`:

* `rh.defect_chull`:

* `rh.defect_labels`:

* `rh.inflated`:

* `rh.inflated.H`:

* `rh.inflated.K`:

* `rh.inflated.nofix`:

* `rh.jacobian_white`:

* `rh.orig`:

* `rh.orig.nofix`:

* `rh.pial`:

* `rh.qsphere.nofix`:

* `rh.smoothwm`:

* `rh.smoothwm.BE.crv`:

* `rh.smoothwm.C.crv`:

* `rh.smoothwm.FI.crv`:

* `rh.smoothwm.H.crv`:

* `rh.smoothwm.K1.crv`:

* `rh.smoothwm.K2.crv`:

* `rh.smoothwm.K.crv`:

* `rh.smoothwm.nofix`:

* `rh.smoothwm.S.crv`:

* `rh.sphere`:

* `rh.sphere.reg`:

* `rh.sulc`:

* `rh.thickness`:

* `rh.volume`:

* `rh.w-g.pct.mgh`:

* `rh.white`:

* `rh.white.H`:

* `rh.white.K`:

* `rh.white.preaparc`:

* `rh.white.preaparc.H`:

* `rh.white.preaparc.K`:

##### touch/
* `aparc.a2009s2aseg.touch`:

* `aparc.DKTatlas2aseg.touch`:

* `apas2aseg.touch`:

* `asegmerge.touch`:

* `ca_label.touch`:

* `ca_normalize.touch`:

* `ca_register.touch`:

* `conform.touch`:

* `cortical_ribbon.touch`:

* `em_register.touch`:

* `fill.touch`:

* `inorm1.touch`:

* `inorm2.touch`:

* `lh.aparc2.touch`:

* `lh.aparcstats2.touch`:

* `lh.aparcstats3.touch`:

* `lh.aparcstats.touch`:

* `lh.aparc.touch`:

* `lh.avgcurv.touch`:

* `lh.curvstats.touch`:

* `lh.final_surfaces.touch`:

* `lh.inflate1.touch`:

* `lh.inflate2.touch`:

* `lh.inflate.H.K.touch`:

* `lh.jacobian_white.touch`:

* `lh.pctsurfcon.touch`:

* `lh.pial_surface.touch`:

* `lh.qsphere.touch`:

* `lh.smoothwm1.touch`:

* `lh.smoothwm2.touch`:

* `lh.sphmorph.touch`:

* `lh.sphreg.touch`:

* `lh.surfvolume.touch`:

* `lh.tessellate.touch`:

* `lh.topofix.touch`:

* `lh.white.H.K.touch`:

* `lh.white_surface.touch`:

* `nu.touch`:

* `relabelhypos.touch`:

* `rh.aparc2.touch`:

* `rh.aparcstats2.touch`:

* `rh.aparcstats3.touch`:

* `rh.aparcstats.touch`:

* `rh.aparc.touch`:

* `rh.avgcurv.touch`:

* `rh.curvstats.touch`:

* `rh.final_surfaces.touch`:

* `rh.inflate1.touch`:

* `rh.inflate2.touch`:

* `rh.inflate.H.K.touch`:

* `rh.jacobian_white.touch`:

* `rh.pctsurfcon.touch`:

* `rh.pial_surface.touch`:

* `rh.qsphere.touch`:

* `rh.smoothwm1.touch`:

* `rh.smoothwm2.touch`:

* `rh.sphmorph.touch`:

* `rh.sphreg.touch`:

* `rh.surfvolume.touch`:

* `rh.tessellate.touch`:

* `rh.topofix.touch`:

* `rh.white.H.K.touch`:

* `rh.white_surface.touch`:

* `rusage.mri_ca_register.dat`:

* `rusage.mri_em_register.dat`:

* `rusage.mri_em_register.skull.dat`:

* `rusage.mris_fix_topology.lh.dat`:

* `rusage.mris_fix_topology.rh.dat`:

* `rusage.mris_inflate.lh.dat`:

* `rusage.mris_inflate.rh.dat`:

* `rusage.mris_register.lh.dat`:

* `rusage.mris_register.rh.dat`:

* `rusage.mris_sphere.lh.dat`:

* `rusage.mris_sphere.rh.dat`:

* `rusage.mri_watershed.dat`:

* `segstats.touch`:

* `skull.lta.touch`:

* `skull_strip.touch`:

* `talairach.touch`:

* `wmaparc.stats.touch`:

* `wmaparc.touch`:

* `wmsegment.touch`:

##### tmp/

##### trash/
