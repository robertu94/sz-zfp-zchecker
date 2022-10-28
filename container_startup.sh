#!/usr/bin/env bash
. /app/spack/share/spack/setup-env.sh
spack env activate /app

if [ -d /zchecker/compressor-install/lib ]; then
  export LD_LIBRARY_PATH=/zchecker/compressor-install/lib:$LD_LIBRARY_PATH
fi
