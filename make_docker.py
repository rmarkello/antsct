#!/usr/bin/env python

from neurodocker import Dockerfile, DockerImage

figshare = "https://ndownloader.figshare.com/files/"
data = f"{figshare}10454170?private_link=5d9349701c771e8d8d46"
code = f"{figshare}10651669?private_link=96f47406f4fd364b5241"

specs = {
    'pkg_manager': 'apt',
    'check_urls': False,
    'instructions': [
        ('base', 'ubuntu:16.04'),
        # wget for segment_mni.sh and bc for ANTs
        ('install', ['bc', 'wget']),
        # not actually V 2.2.0
        ('ants', {'version': '2.2.0',
                  'use_binaries': False,
                  'git_hash': '30eabeb002818ce999e2d368920435c457456d47'}),
        # download data and code
        ('instruction', 'RUN mkdir /data \\\n'
                        f'    && curl -sSL --retry 5 {data} | tar zx -C /opt \\\n'
                        f'    && curl -sSL --retry 5 {code} | tar zx -C /opt'),
        ('entrypoint', '/opt/antsct.sh'),
        # create miniconda environment
        ('miniconda', {
            'miniconda_version': '4.3.31',
            'env_name': 'antsct',
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
            ]
        })
    ]
}

if __name__ == '__main__':
    df = Dockerfile(specs)
    df.save()
    # DockerImage(df).build(tag='antsct', log_console=True)
