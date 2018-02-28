#!/usr/bin/env python

import argparse
import os
import pathlib
import re
import jinja2
import nibabel as nib
from niworkflows.viz.utils import (compose_view, plot_segs,
                                   plot_registration, cuts_from_bbox)
import numpy as np


def make_brain(*, anatomical, mask, out_file):
    """
    Creates `out_file`.svg of brain `mask` on input `anatomical`

    Parameters
    ----------
    anatomical : str
        Path to anatomical T1w image (*with skull*)
    mask : str
        Path to brain mask file
    out_file : str
        Path to where svg will be saved

    Returns
    -------
    out_file : str
        Where svg was saved
    """

    if not out_file.endswith('.svg'): out_file += '.svg'

    compose_view(
        plot_segs(image_nii=anatomical,
                  seg_niis=[mask],
                  bbox_nii=mask,
                  out_file='reports.svg',
                  masked=False,
                  compress='auto'),
        fg_svgs=None,
        out_file=out_file
    )

    return out_file


def make_segmentation(*, anatomical, segmentation, mask, out_file):
    """
    Creates `out_file`.svg of `segmentation` countours on input `anatomical`

    Parameters
    ----------
    anatomical : str
        Path to anatomical T1w image (*without skull*)
    segmentation : str
        Path to segmentation file with tissue types (1-6)
    mask : str
        Path to brain mask file
    out_file : str
        Path to where svg will be saved

    Returns
    -------
    out_file : str
        Where svg was saved
    """

    if not out_file.endswith('.svg'): out_file += '.svg'
    segs = segmentation_to_files(segmentation)

    compose_view(
        plot_segs(image_nii=anatomical,
                  seg_niis=[mask] + segs,
                  bbox_nii=mask,
                  out_file='reports.svg',
                  masked=False,
                  compress='auto'),
        fg_svgs=None,
        out_file=out_file
    )

    for fname in segs: os.remove(fname)

    return out_file


def make_registration(*, moving, fixed, mask, out_file):
    """
    Creates `out_file`.svg of registration between `moving` and `fixed`

    Parameters
    ----------
    moving : str
        Path to file that was registered to `fixed`
    fixed : str
        Path to file that `moving` was registered to
    mask : str
        Path to brain mask file
    out_file : str
        Path to where svg will be saved

    Returns
    -------
    out_file : str
        Where svg was saved
    """

    if not out_file.endswith('.svg'): out_file += '.svg'
    cuts = cuts_from_bbox(nib.load(mask), cuts=7)

    compose_view(
        plot_registration(nib.load(fixed),
                          'fixed-image',
                          estimate_brightness=True,
                          cuts=cuts,
                          label='fixed'),
        plot_registration(nib.load(moving),
                          'moving-image',
                          estimate_brightness=True,
                          cuts=cuts,
                          label='moving'),
        out_file=out_file
    )

    return out_file


def segmentation_to_files(segmentation, types=[2, 4]):
    """
    Converts single `segmentation` into multiple files

    Output of ANTs pipeline is a single segmentation file with 6 tissue types
    (1: CSF, 2: Cortical GM, 3: WM, 4: Deep GM, 5: Brainstem, 6: Cerebellum).
    `plot_segs` requires a *list* of files, so this splits up the input file
    into individual files corresponding separately to each tissue type.

    Parameters
    ----------
    segmentation : str
        Path to segmentation file with tissue types (1-6)
    types : list, optional
        Which tissue types to extract. Default: [2, 4]
    """

    for lab in types:
        if lab not in range(1, 7):
            raise ValueError('`types` must only include numbers [1-6]')

    img = nib.load(segmentation)
    labels = img.get_data()
    out_files = []

    for lab in types:
        out_files.append(segmentation.replace('.nii.gz', f'_seg{lab}.nii.gz'))
        seg = np.zeros_like(labels)
        seg[labels == lab] = lab
        img.__class__(seg, img.affine, img.header).to_filename(out_files[-1])

    return out_files


def make_sst(sst_dir, temp_dir, out_dir):
    """
    Parameters
    ----------
    sst_dir : pathlib.Path
    temp_dir : pathlib.Path
    out_dir : pathlib.Path
    """

    T1w = sst_dir / 'T_template0.nii.gz'
    T1w_mask = sst_dir / 'T_templateBrainExtractionMask.nii.gz'
    T1w_seg = sst_dir / 'T_templateBrainSegmentation.nii.gz'
    T1w_to_MNI = sst_dir / 'T_templateBrainNormalizedToTemplate.nii.gz'
    MNI_brain = temp_dir / 'template_brain.nii.gz'
    MNI_mask = temp_dir / 'template_brain_mask.nii.gz'

    seg = make_segmentation(anatomical=T1w.as_posix(),
                            segmentation=T1w_seg.as_posix(),
                            mask=T1w_mask.as_posix(),
                            out_file=(out_dir / 'sst_seg.svg').as_posix())
    reg = make_registration(moving=T1w_to_MNI.as_posix(),
                            fixed=MNI_brain.as_posix(),
                            mask=MNI_mask.as_posix(),
                            out_file=(out_dir / 'sst_reg.svg').as_posix())

    return seg, reg


def make_visit(visit_dir, sst_dir, out_dir):
    """
    visit_dir : pathlib.Path
    sst_dir : pathlib.Path
    out_dir : pathlib.Path
    """

    base = '_'.join(visit_dir.name.split('_')[:-1])
    ses = re.search('ses-(\d+)', base).group()

    T1w = visit_dir / '..' / 'coreg' / f'{base}.nii.gz'
    T1w_mask = visit_dir / f'{base}BrainExtractionMask.nii.gz'
    T1w_seg = visit_dir / f'{base}BrainSegmentation.nii.gz'
    T1w_to_SST = visit_dir / f'{base}BrainNormalizedToTemplate.nii.gz'
    SST_brain = sst_dir / 'T_templateBrainExtractionBrain.nii.gz'
    SST_mask = sst_dir / 'T_templateBrainExtractionMask.nii.gz'

    seg = make_segmentation(anatomical=T1w.as_posix(),
                            segmentation=T1w_seg.as_posix(),
                            mask=T1w_mask.as_posix(),
                            out_file=(out_dir / f'{ses}_seg.svg').as_posix())
    reg = make_registration(moving=T1w_to_SST.as_posix(),
                            fixed=SST_brain.as_posix(),
                            mask=SST_mask.as_posix(),
                            out_file=(out_dir / f'{ses}_reg.svg').as_posix())

    return seg, reg


def prep_for_jinja(images):
    """
    Prepares svg `images` for jinja rendering

    Parameters
    ----------
    images : list-of-str

    Returns
    -------
    outputs : list-of-tuple
    """

    from textwrap import dedent

    xmlcontent = dedent("""\
    <object type="image/svg+xml" data="./{0}" \
    class="reportlet">filename:{0}</object>\
    """)

    outputs = []
    for im in images:
        subject = 'sub-' + re.findall('/sub-(\d+)/', im)[0]
        fbase = os.path.basename(im)
        fig_dir = re.findall(f'/{subject}/(.*)/{fbase}', im)[0]
        content = xmlcontent.format(os.path.join(subject, fig_dir, fbase))
        outputs.append((im, content))

    return outputs


def main():
    """
    Generates reports from outputs of ANTs pipeline
    """

    parser = argparse.ArgumentParser(description='Create visual reports')

    parser.add_argument('-s', dest='subj_dir',
                        required=True,
                        type=pathlib.Path,
                        help='Subject output directory')
    parser.add_argument('-t', dest='temp_dir',
                        required=True,
                        type=pathlib.Path,
                        help='Template directory used by ANTs')
    parser.add_argument('-o', dest='out_dir',
                        required=False,
                        default=argparse.SUPPRESS,
                        type=pathlib.Path,
                        help='Where report should be saved.')

    options = vars(parser.parse_args())
    sub, subj_dir = options['subj_dir'].parts[-2], options['subj_dir']
    temp_dir = options['temp_dir'].resolve()
    out_dir = options.get('out_dir', subj_dir).resolve() / 'figures'
    os.makedirs(out_dir, exist_ok=True)

    # first let's make the SST brain mask, segmentation, registration to MNI
    sst_dir = (subj_dir / f'{sub}_CTSingleSubjectTemplate').resolve()
    sst_seg, sst_reg = make_sst(sst_dir, temp_dir, out_dir)
    images = [sst_seg, sst_reg]

    # now let's make the individual visits
    for v in sorted([f for f in subj_dir.glob(f'{sub}*T1w_*') if f.is_dir()]):
        v_seg, v_reg = make_visit(v.resolve(), sst_dir, out_dir)
        images.extend([v_seg, v_reg])

    # prepare the images to be put into jinja template
    images = prep_for_jinja(images)

    # finally, grab the ANTS command to add to the report
    antsfp = subj_dir / f'${sub}_antscommand.txt'
    if antsfp.exists():
        with open(antsfp, 'r') as src:
            antscmd = src.read()
    else:
        antscmd = ''

    env = jinja2.Environment(loader=jinja2.FileSystemLoader(searchpath='/opt'),
                             trim_blocks=True,
                             lstrip_blocks=True)
    report_tpl = env.get_template('report.tpl')
    report_render = report_tpl.render(images=images, antscmd=antscmd)
    with open(f'{sub}.html', 'w') as fp: fp.write(report_render)


if __name__ == '__main__':
    main()
