#!/usr/bin/env bash

read -r -d '' ENTRYPOINT << EOM
#!/usr/bin/env bash
. /opt/freesurfer/FreeSurferEnv.sh
/opt/antsclt.sh "\${@}"
EOM

ants_ver="30eabeb002818ce999e2d368920435c457456d47"
data="https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46"

generate_singularity() {
docker run --rm kaczmarj/neurodocker:master generate singularity \
    --base ubuntu:18.04 \
    --pkg-manager apt \
    --install bc wget \
    --run "mkdir -p /data /output" \
    --run "curl -sSL --retry 5 ${data} | tar zx -C /opt" \
    --miniconda install_path="/opt/miniconda" env_name="antsclt" \
      conda_install="python=3.6.2 click=6.7 funcsigs=1.0.2 \
                     future=0.16.0 jinja2=2.10 matplotlib=2.1.1 \
                     mock=2.0.0 nibabel=2.2.1 numpy=1.14.0 \
                     packaging=16.8 pandas=0.21.0 prov=1.5.1 \
                     pydot=1.2.3 pydotplus=2.0.2 pytest=3.3.2 \
                     python-dateutil=2.6.1 seaborn=0.8.1 \
                     scikit-learn=0.19.1 scipy=1.0.0 simplejson=3.12.0 \
                     traits=4.6.0" \
      pip_install="nilearn==0.3.1 niworkflows==0.3.1 svgutils==0.3.0" \
      activate=true \
    --freesurfer version=6.0.0-min install_path="/opt/freesurfer" \
    --ants version=${ants_ver} method=source install_path="/opt/ants" \
    --copy code/antsclt.sh /opt \
    --copy code/report.py /opt \
    --copy code/report.tpl /opt \
    --run "if [ ! -f /opt/entrypoint.sh ]; then
      echo '${ENTRYPOINT}' >> /opt/entrypoint.sh;
      chmod 777 /opt/entrypoint.sh;
      fi" \
    --entrypoint "/opt/entrypoint.sh \"\${@}\""
}

generate_singularity > Singularity
