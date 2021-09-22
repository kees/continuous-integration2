#!/usr/bin/env bash

if [[ -n ${GITHUB_ACTIONS} ]]; then
    repo=${GITHUB_WORKSPACE}
else
    repo=$(dirname "$(readlink -f "${0}")")
fi

function update_series_commands() {
    echo
    echo "$ ls -1 ${folder}/*.patch | sed \"s;${folder}/;;\" > ${folder}/series"
}

for folder in "${repo}"/patches/*; do
    series=${folder}/series

    # First, make sure series file is not missing
    if [[ ! -f ${series} ]]; then
        echo "${folder} exists but ${series} doesn't?"
        echo
        echo "Generate it with the following commands:"
        update_series_commands
        exit 1
    fi

    # Next, check that all of the patches in the series file exist (removed a
    # patch, did not update series file)
    while IFS= read -r patch; do
        if [[ ! -f ${folder}/${patch} ]]; then
            echo "${folder} does not contain ${patch} but it is in ${series}?"
            echo
            echo "Update the series file:"
            update_series_commands
            exit 1
        fi
    done <"${series}"

    # Lastly, make sure that all of the patches in the patches folder are in
    # the series file (removed from series file, did not remove patch file)
    for patch in "${folder}"/*.patch; do
        patch=$(basename "${patch}")
        if ! grep -q "${patch}" "${series}"; then
            echo "${series} contains ${patch} but it does not exist in ${folder}?"
            echo
            echo "Update the series file:"
            update_series_commands
            exit 1
        fi
    done
done

echo "All patch file checks pass!"
exit 0