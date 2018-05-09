# Generated by Neurodocker version 0.4.0rc1-7-g2e7143a
# Timestamp: 2018-05-09 18:55:49 UTC
# 
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
# 
#     https://github.com/kaczmarj/neurodocker

Bootstrap: docker
From: ubuntu:18.04

%post
export ND_ENTRYPOINT="/neurodocker/startup.sh"
apt-get update -qq
apt-get install -y -q --no-install-recommends \
    apt-utils \
    bzip2 \
    ca-certificates \
    curl \
    locales \
    unzip
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG="en_US.UTF-8"
chmod 777 /opt && chmod a+s /opt
mkdir -p /neurodocker
if [ ! -f "$ND_ENTRYPOINT" ]; then
  echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT"
  echo 'set -e' >> "$ND_ENTRYPOINT"
  echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT";
fi
chmod -R 777 /neurodocker && chmod a+s /neurodocker

apt-get update -qq
apt-get install -y -q --no-install-recommends \
    bc \
    wget
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

mkdir -p /data /output

curl -sSL --retry 5 https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46 \
      | tar zx -C /opt

export PATH="/opt/miniconda/bin:$PATH"
echo "Downloading Miniconda installer ..."
conda_installer="/tmp/miniconda.sh"
curl -fsSL --retry 5 -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash "$conda_installer" -b -p /opt/miniconda
rm -f "$conda_installer"
conda update -yq -nbase conda
conda config --system --prepend channels conda-forge
conda config --system --set auto_update_conda false
conda config --system --set show_channel_urls true
sync && conda clean -tipsy && sync
conda create -y -q --name antsclt
conda install -y -q --name antsclt \
    python=3.6.2 \
    click=6.7 \
    funcsigs=1.0.2 \
    future=0.16.0 \
    jinja2=2.10 \
    matplotlib=2.1.1 \
    mock=2.0.0 \
    nibabel=2.2.1 \
    numpy=1.14.0 \
    packaging=16.8 \
    pandas=0.21.0 \
    prov=1.5.1 \
    pydot=1.2.3 \
    pydotplus=2.0.2 \
    pytest=3.3.2 \
    python-dateutil=2.6.1 \
    seaborn=0.8.1 \
    scikit-learn=0.19.1 \
    scipy=1.0.0 \
    simplejson=3.12.0 \
    traits=4.6.0
sync && conda clean -tipsy && sync
bash -c "source activate antsclt
  pip install -q --no-cache-dir \
      nilearn==0.3.1 \
      niworkflows==0.3.1 \
      svgutils==0.3.0"
sync
sed -i '$isource activate antsclt' $ND_ENTRYPOINT


apt-get update -qq
apt-get install -y -q --no-install-recommends \
    bc \
    libgomp1 \
    libxmu6 \
    libxt6 \
    perl \
    tcsh
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
echo "Downloading FreeSurfer ..."
mkdir -p /opt/freesurfer
curl -fsSL --retry 5 https://dl.dropbox.com/s/nnzcfttc41qvt31/recon-all-freesurfer6-3.min.tgz \
| tar -xz -C /opt/freesurfer --strip-components 1 
sed -i '$isource "/opt/freesurfer/SetUpFreeSurfer.sh"' "$ND_ENTRYPOINT"

apt-get update -qq
apt-get install -y -q --no-install-recommends \
    cmake \
    g++ \
    gcc \
    git \
    make \
    zlib1g-dev
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
mkdir -p /tmp/ants/build
git clone https://github.com/ANTsX/ANTs.git /tmp/ants/source
cd /tmp/ants/source
git fetch --tags
git checkout 30eabeb002818ce999e2d368920435c457456d47
cd /tmp/ants/build
cmake -DBUILD_SHARED_LIBS=ON /tmp/ants/source
make -j1
mkdir -p /opt/ants
mv bin lib /opt/ants/
mv /tmp/ants/source/Scripts/* /opt/ants/bin
rm -rf /tmp/ants

if [ ! -f /opt/entrypoint.sh ]; then
      echo "#!/usr/bin/env bash
export FREESURFER_HOME=/opt/freesurfer
. /opt/freesurfer/FreeSurferEnv.sh
/opt/antsclt "${@}"" >> /opt/entrypoint.sh;
      chmod 777 /opt/entrypoint.sh;
      fi

echo '{
\n  "pkg_manager": "apt",
\n  "instructions": [
\n    [
\n      "base",
\n      "ubuntu:18.04"
\n    ],
\n    [
\n      "_header",
\n      {
\n        "version": "generic",
\n        "method": "custom"
\n      }
\n    ],
\n    [
\n      "install",
\n      [
\n        "bc",
\n        "wget"
\n      ]
\n    ],
\n    [
\n      "run",
\n      "mkdir -p /data /output"
\n    ],
\n    [
\n      "run",
\n      "curl -sSL --retry 5 https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46 \\\\n      | tar zx -C /opt"
\n    ],
\n    [
\n      "miniconda",
\n      {
\n        "install_path": "/opt/miniconda",
\n        "env_name": "antsclt",
\n        "conda_install": [
\n          "python=3.6.2",
\n          "click=6.7",
\n          "funcsigs=1.0.2",
\n          "future=0.16.0",
\n          "jinja2=2.10",
\n          "matplotlib=2.1.1",
\n          "mock=2.0.0",
\n          "nibabel=2.2.1",
\n          "numpy=1.14.0",
\n          "packaging=16.8",
\n          "pandas=0.21.0",
\n          "prov=1.5.1",
\n          "pydot=1.2.3",
\n          "pydotplus=2.0.2",
\n          "pytest=3.3.2",
\n          "python-dateutil=2.6.1",
\n          "seaborn=0.8.1",
\n          "scikit-learn=0.19.1",
\n          "scipy=1.0.0",
\n          "simplejson=3.12.0",
\n          "traits=4.6.0"
\n        ],
\n        "pip_install": [
\n          "nilearn==0.3.1",
\n          "niworkflows==0.3.1",
\n          "svgutils==0.3.0"
\n        ],
\n        "activate": true
\n      }
\n    ],
\n    [
\n      "freesurfer",
\n      {
\n        "version": "6.0.0-min",
\n        "install_path": "/opt/freesurfer"
\n      }
\n    ],
\n    [
\n      "ants",
\n      {
\n        "version": "30eabeb002818ce999e2d368920435c457456d47",
\n        "method": "source",
\n        "install_path": "/opt/ants"
\n      }
\n    ],
\n    [
\n      "copy",
\n      [
\n        "code/",
\n        "/opt/"
\n      ]
\n    ],
\n    [
\n      "run",
\n      "if [ ! -f /opt/entrypoint.sh ]; then\\n      echo \"#!/usr/bin/env bash\\nexport FREESURFER_HOME=/opt/freesurfer\\n. /opt/freesurfer/FreeSurferEnv.sh\\n/opt/antsclt \"${@}\"\" >> /opt/entrypoint.sh;\\n      chmod 777 /opt/entrypoint.sh;\\n      fi"
\n    ],
\n    [
\n      "entrypoint",
\n      "/opt/entrypoint.sh \"${@}\""
\n    ]
\n  ]
\n}' > /neurodocker/neurodocker_specs.json

%environment
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export ND_ENTRYPOINT="/neurodocker/startup.sh"
export CONDA_DIR="/opt/miniconda"
export PATH="/opt/ants/bin:$PATH"
export FREESURFER_HOME="/opt/freesurfer"
export ANTSPATH="/opt/ants/bin"
export LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

%files
code/ /opt/

%runscript
/opt/entrypoint.sh "${@}"
