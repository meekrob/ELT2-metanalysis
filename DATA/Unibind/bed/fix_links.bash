#!/usr/bin/env bash

for potentially_fucked in $(find . -type l -not -name '.*')
do
    echo $potentially_fucked
    lnk=$(readlink $potentially_fucked)
    cd $(dirname $potentially_fucked)
    
    if [ ! -e $lnk ]
    then # it is fucked
        actually_fucked=$(basename $potentially_fucked)
        potentially_not_fucked="../$lnk"
        if [ -e $potentially_not_fucked ]
        then
            echo "$potentially_not_fucked is alright"
            mv $actually_fucked .fucked_$actually_fucked
            ln -sv $potentially_not_fucked $actually_fucked # name will no longer be fucked
        else
            echo "link $potentially_not_fucked still fucked" 1>&2
            exit 1
        fi
    else
        echo "$lnk for $potentially_fucked wasn't fucked"
        #cd ..
        #continue
    fi
    
    cd ..

    #break
done
