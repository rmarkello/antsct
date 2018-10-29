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

curl -sSL --retry 5 https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46 | tar zx -C /opt

export PATH="/opt/miniconda-latest/bin:$PATH"
echo "Downloading Miniconda installer ..."
conda_installer="/tmp/miniconda.sh"
curl -fsSL --retry 5 -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash "$conda_installer" -b -p /opt/miniconda-latest
rm -f "$conda_installer"
conda update -yq -nbase conda
conda config --system --prepend channels conda-forge
conda config --system --set auto_update_conda false
conda config --system --set show_channel_urls true
sync && conda clean -tipsy && sync
conda env create -q --name antslct --file /opt/environment.yml
rm -rf ~/.cache/pip/*


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
      echo '#!/bin/bash
. /opt/freesurfer/FreeSurferEnv.sh
/opt/antslct.sh "${@}"' >> /opt/entrypoint.sh;
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
\n      "curl -sSL --retry 5 https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46 | tar zx -C /opt"
\n    ],
\n    [
\n      "copy",
\n      [
\n        "environment.yml",
\n        "/opt/environment.yml"
\n      ]
\n    ],
\n    [
\n      "miniconda",
\n      {
\n        "create_env": "antslct",
\n        "yaml_file": "/opt/environment.yml",
\n        "activate": true
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
\n        "code/antslct.sh",
\n        "/opt"
\n      ]
\n    ],
\n    [
\n      "copy",
\n      [
\n        "code/report.py",
\n        "/opt"
\n      ]
\n    ],
\n    [
\n      "copy",
\n      [
\n        "code/report.tpl",
\n        "/opt"
\n      ]
\n    ],
\n    [
\n      "run",
\n      "if [ ! -f /opt/entrypoint.sh ]; then\\n      echo '"'"'#!/bin/bash\\n. /opt/freesurfer/FreeSurferEnv.sh\\n/opt/antslct.sh \"${@}\"'"'"' >> /opt/entrypoint.sh;\\n      chmod 777 /opt/entrypoint.sh;\\n      fi"
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
export CONDA_DIR="/opt/miniconda-latest"
export PATH="/opt/ants/bin:$PATH"
export ANTSPATH="/opt/ants/bin"
export LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

%files
environment.yml /opt/environment.yml
code/antslct.sh /opt
code/report.py /opt
code/report.tpl /opt

%runscript
/opt/entrypoint.sh "${@}"
