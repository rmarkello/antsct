#!/usr/bin/env bash

# This script will generate a Singularity recipe file that can be built with:
#
#     $ sudo singularity build antslct.simg Singularity
#
# and then used to run the ANTs longitudinal cortical thickness pipeline.

read -r -d '' ENTRYPOINT << EOM
#!/usr/bin/env bash
. /opt/freesurfer/FreeSurferEnv.sh
/opt/antslct.sh "\${@}"
EOM

ants_ver="30eabeb002818ce999e2d368920435c457456d47"
data="https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46"

generate_singularity() {
docker run --rm kaczmarj/neurodocker:0.4.0 generate singularity               \
    --base ubuntu:18.04                                                       \
    --pkg-manager apt                                                         \
    --install bc wget                                                         \
    --run "mkdir -p /data /output"                                            \
    --run "curl -sSL --retry 5 ${data} | tar zx -C /opt"                      \
    --copy environment.yml /opt/environment.yml                               \
    --miniconda                                                               \
      create_env=${tag}                                                       \
      yaml_file=/opt/environment.yml                                          \
      activate=true                                                           \
    --freesurfer                                                              \
      version=6.0.0-min                                                       \
      install_path="/opt/freesurfer"                                          \
    --ants version=${ants_ver} method=source install_path="/opt/ants"         \
    --copy code/antslct.sh /opt                                               \
    --copy code/report.py /opt                                                \
    --copy code/report.tpl /opt                                               \
    --run                                                                     \
      "if [ ! -f /opt/entrypoint.sh ]; then
      echo '${ENTRYPOINT}' >> /opt/entrypoint.sh;
      chmod 777 /opt/entrypoint.sh;
      fi"                                                                     \
    --entrypoint "/opt/entrypoint.sh \"\${@}\""
}

generate_singularity > Singularity