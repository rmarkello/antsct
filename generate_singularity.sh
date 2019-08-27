#!/usr/bin/env bash
#
# Description:
#
#     This script will generate a Singularity recipe that can be built with:
#
#         $ sudo singularity build antslct.simg Singularity
#
#     and then used to run the ANTs longitudinal cortical thickness pipeline.
#     This script requires Docker and assumes it is accessible from the command
#     line.
#
# Usage:
#
#     bash generate_singularity.sh

read -r -d '' ENTRYPOINT << EOM
#!/bin/bash
/opt/antslct.sh "\${@}"
EOM

data="https://ndownloader.figshare.com/files/10454170?private_link=5d9349701c771e8d8d46"

generate_singularity() {
singularity --quiet exec docker://kaczmarj/neurodocker:0.5.0                  \
    /usr/bin/neurodocker generate singularity                                 \
    --base ubuntu:18.04                                                       \
    --pkg-manager apt                                                         \
    --install bc wget                                                         \
    --run "mkdir -p /data /output"                                            \
    --run "curl -sSL --retry 5 ${data} | tar zx -C /opt"                      \
    --copy environment.yml /opt/environment.yml                               \
    --miniconda                                                               \
      create_env=antslct                                                      \
      yaml_file=/opt/environment.yml                                          \
      activate=true                                                           \
    --ants version=2.3.1 install_path="/opt/ants/bin"                         \
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

printf "\nSingularity recipe file created and saved to:\n\n"
printf "    $PWD/Singularity\n\n"
printf "To generate a Singularity container from this recipe simply run:\n\n"
printf "    $ sudo singularity build antslct.simg $PWD/Singularity\n\n"
