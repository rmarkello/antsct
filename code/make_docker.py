#!/usr/bin/env python

from neurodocker import Dockerfile

specs = {
    'pkg_manager': 'apt',
    'check_urls': False,
    'instructions': [
        ('base', 'ubuntu:16.04'),
        # wget for segment_mni.sh and bc for ANTs
        ('install', ['bc', 'wget']),
        ('ants', {'version': '2.2.0'}),
        ('instruction', 'RUN mkdir /data /opt/data'),
        # copy over MICCAI label data and MNI template
        ('copy', ['data/miccai', '/opt/data/miccai']),
        ('copy', ['data/mni_template', '/opt/data/mni_template']),
        # copy over code for making MNI template and generating reports
        ('copy', ['code/segment_mni.sh', '/opt/segment_mni.sh']),
        ('copy', ['code/report.tpl', '/opt/report.tpl']),
        ('copy', ['code/report.py', '/opt/report.py'])
        # create miniconda environment
        ('miniconda', {
            'miniconda_version': '4.3.31',
            'env_name': 'py36',
            'conda_install': ' '.join([
                'python=3.6.2',
                'click=6.7',
                'funcsigs=1.0.2',
                'future=0.16.0',
                'jinja2=2.10',
                'matplotlib=2.1.1',
                'mock=2.0.0',
                'nibabel=2.2.1',
                'numpy=1.14.0',
                'packaging=16.8',
                'pandas=0.21.0',
                'prov=1.5.1',
                'pydot=1.2.3',
                'pydotplus=2.0.2',
                'pytest=3.3.2',
                'python-dateutil=2.6.1',
                'seaborn=0.8.1',
                'scikit-learn=0.19.1',
                'scipy=1.0.0',
                'simplejson=3.12.0',
                'traits=4.6.0'
            ]),
            'pip_install': [
                'nilearn==0.3.1',
                'niworkflows==0.3.1',
                'svgutils==0.3.0'
            ],
            'activate': True
        }),
        # copy pipeline code and set as entrypoint
        ('copy', ['code/antsct.sh', '/opt/antsct.sh']),
        ('entrypoint', '/opt/antsct.sh')
    ]
}

if __name__ == '__main__':
    Dockerfile(specs).save()
