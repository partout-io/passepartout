#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
openapi=`realpath app-cross/openapi.yaml`
models_dir=`realpath app-android/app`
package_name=com.algoritmico.passepartout.abi.models

# Clean up
rm -rf $models_dir/src/main/kotlin/com/algoritmico/passepartout/abi/models

# Enter package
pushd app-cross/partout

# Generate Partout models
scripts/build.sh -gen-models

# Generate Passepartout models
for language in "kotlin"; do
    echo "Generate $language models..."
    scripts/gen-models.sh \
        $openapi \
        $language \
        $models_dir \
        $package_name
done

# Exit package
popd
