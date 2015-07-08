#!/bin/bash

# The yaml-parsing 'parse_yaml' function here was created by Piotr Kuczynski:
# https://gist.github.com/pkuczynski/8665367#file-parse_yaml-sh
#
# It converts:
#   ---
#   this:
#       that: other
#       another: more
#
# To:
#   this__that="other"
#   this__another="more"
#

function parse_yaml {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    echo $(sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
    awk -F$fs '{
       indent = length($1)/2;
       vname[indent] = $2;
       for (i in vname) {if (i > indent) {delete vname[i]}}
       if (length($3) > 0) {
           vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
           printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
       }
    }')
}

# A line of parsed yaml:
# test__shared__work_home="/home/U008/mwham/"
#   ^left-hand-side tag^     ^actual data^


function retrieve_element {
    local input_yaml=$1
    local environment=$2
    local domain=$3
    local element=$4
    # example: $regexp='production_+proctrigger_+age_cutoff'
    local regexp=$environment'_+'$domain'_+'$element
    # get parsed yaml            # isolate element    # remove lhs tag        # remove quotes   # remove comments
    echo $(parse_yaml $input_yaml | sed -r 's/ /\n/g' | grep -E $regexp | sed -nr s/$regexp=//p | sed -r 's/"//g' | sed -r 's/ *#.*$//g')
}

