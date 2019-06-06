#!/bin/bash

# path to the file with project names map like:
#       Juniper/contrail-test-runner tungstenfabric/test-runner
#        ....
#   convertion from 
#       Juniper contrail-test-runner tungstenfabric test-runner
#     to
#       Juniper/contrail-test-runner tungstenfabric-infra/periodic-nightly
#
#       awk '{print($1"/"$2" "$3"/"$4)}' tr_map | sort -k 1 -r > tr_map_p
projects_file=$1

# path to dir where to replace names
target_dir=$2

[ -z "$projects_file" ] && {
    echo "ERROR: first arg must be path to the file with projects names map"
    exit -1
}

[ -z "$target_dir" ] && {
    echo "ERROR: send arg must be path to the target dir"
    exit -1
}


hacks_file="roles/contrail-controller-hacks/tasks/main.yaml"

while IFS= read -r project ; do

    src_name=$(echo "$project" | cut -d ' ' -s -f 1)
    dst_name=$(echo "$project" | cut -d ' ' -s -f 2)

    [[ -z "$src_name" || -z "$dst_name" ]] && {
        echo "ERROR: wrong project map format: $project"
        continue
    }
    
    src_name_rgex=$(echo "$src_name" | sed 's/\//\\\//g' | sed 's/\-/\\\-/g')
    dst_name_rgex=$(echo "$dst_name" | sed 's/\//\\\//g' | sed 's/\-/\\\-/g')
    files=$(grep -r "$src_name_rgex" ./ | grep -v "$projects_file" | grep -v "replace\.sh" | awk -F ':' '{print($1)}' | sort | uniq | sed 's/^\.\/\///g')

    for f in $files ; do
        echo $src_name_rgex
        echo $dst_name_rgex
        sed "s/$src_name_rgex/$dst_name_rgex/g" $target_dir/$f > ./tmp.sed.file && {
            mv ./tmp.sed.file $target_dir/$f
        } || {
            echo "ERROR: Failed to replace $src_name  => $dst_name"
            rm -f ./tmp.sed.file
        }
    done

    prj=$(echo "$src_name" | cut -d '/' -s -f 2 | sed 's/\//\\\//g' | sed 's/\-/\\\-/g')
    dst_prj=$(echo "$dst_name" | cut -d '/' -s -f 2 | sed 's/\//\\\//g' | sed 's/\-/\\\-/g')
    sed "s/$prj/$dst_prj/g" $hacks_file > ./tmp.sed.file && {
            mv ./tmp.sed.file $hacks_file
        } || {
            echo "ERROR: Failed to replace $prj  => $dst_prj"
            rm -f ./tmp.sed.file
        }

done < $projects_file


sed 's/Juniper/tungstenfabric/g' $hacks_file > ./tmp.sed.file && {
            mv ./tmp.sed.file $hacks_file
        } || {
            echo "ERROR: Failed to replace Juniper  => tungstenfabric"
            rm -f ./tmp.sed.file
        }
