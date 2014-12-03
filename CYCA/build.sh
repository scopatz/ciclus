#!/bin/bash
set -x 
set -e

`pwd`/CYCL/build.sh
PATH=$PATH:`pwd`/install/bin
UNAME=$(uname)
cycamore_tar_dir="cycamore-1.2.0"
anaconda/bin/conda list

# force cycamore to build with local cyclus
vers=`anaconda/bin/conda list | grep cyclus`
read -a versArray <<< $vers
if [[ "${UNAME}" == 'Linux' ]]; then
  sed -i  "s/- cyclus/- cyclus ${versArray[1]}/g" cycamore/meta.yaml
else
  sed -i '' "s/- cyclus/- cyclus ${versArray[1]}/g" cycamore/meta.yaml
fi

# force cycamore to build with local cyclus
vers=`cat cycamore/meta.yaml | grep version`
read -a versArray <<< $vers

anaconda/bin/conda build --no-test cycamore 
anaconda/bin/conda install --use-local cycamore=${versArray[1]}

# Setup workdir for later use
if [ -d "anaconda/conda-bld/work/${cycamore_tar_dir}" ]; then
  export WORKDIR="anaconda/conda-bld/work/${cycamore_tar_dir}"
else  
  export WORKDIR="anaconda/conda-bld/work"
fi

cp -r "${WORKDIR}/tests" cycatest


# Build Docs
if [[  "${UNAME}" == 'Linux' ]]; then
  origdir="$(pwd)"
  cd "${WORKDIR}/build"
  make cycamoredoc | tee doc.out
  line=$(grep -i warning doc.out | wc -l)
  if [ $line -ne 0 ]; then
    exit 1
  fi
  ls -l
  mv doc "${origdir}/cycamoredoc"
  cd "$origdir"
  tar -czf results.tar.gz anaconda cyclusdoc cycamoredoc
else
  tar -czf results.tar.gz anaconda 
fi

