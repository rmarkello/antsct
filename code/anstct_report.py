#!/usr/bin/env python

import argparse
import os
import pathlib
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
                  seg_niis=segs,
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
    cuts = cuts_from_bbox(mask, cuts=7)

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


def segmentation_to_files(*, segmentation, types=[2, 4]):
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


def main():
    """
    Generates reports from outputs of ANTs pipeline
    """

    parser = argparse.ArgumentParser(description='Create visual reports')

    parser.add_argument('-s', dest='subject_directory',
                        required=True,
                        type=pathlib.Path,
                        help='Subject directory (BIDS format)')
    parser.add_argument('-t', dest='template_directory',
                        required=True,
                        type=pathlib.Path,
                        help='Template directory used by ANTs')
    parser.add_argument('-o', dest='output_directory',
                        required=False,
                        default=None,
                        help='Where report should be saved.')

    options = vars(parser.parse_args())
    if options['output_directory'] is None:
        options['output_directory'] = options['subject_directory'] / 'output'


if __name__ == '__main__':
    main()