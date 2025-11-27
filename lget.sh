#!/bin/bash

ROOT_URL=$1
ROOT_URL="${ROOT_URL%/}"
ROOT_HOSTNAME="${ROOT_URL#*//}"
ROOT_DIRECTORY=./$ROOT_HOSTNAME

mkdir -p $ROOT_DIRECTORY

# okay, parametrii sunt:
# $1 - path (exemplu: articol/fmi)
# $2 - url la resursa
function parse-file {
    resource_path=$1
    resource_url=$2

    if grep -Fqx "$resource_url" "$ROOT_DIRECTORY/visited.txt" 2> /dev/null; then
        return
    fi
    echo $resource_url >> "$ROOT_DIRECTORY/visited.txt"

    resource_directory=$ROOT_DIRECTORY/$resource_path
    if [[ "$resource_path" == "./" ]]; then
        resource_directory=$ROOT_DIRECTORY
    fi

    # -P e pentru prefix
    # -x este sa creeze el singur subdirectories (dont try it yourself, nu stii care sunt foldere si care sunt fisiere)
    # -nH ca sa nu imi creeze iar folder cu hostname 
    # also, nesimtitii au decis ca progress barul sa fie scris pe stderr
    # al doilea cut e necesar sa scap de ghilimeaua de la sfarsit
    file_name=`wget -P $ROOT_DIRECTORY -x -nH $resource_url 2>&1 | grep "Saving to:" | sed 's/.*‘//; s/’.*//' | xargs basename 2>/dev/null`

    if [[ "$file_name" != *".html" ]]; then
        return
    fi

    while read line; do
        # link extern
        if ([[ "$line" == "http://"* ]] || \
            [[ "$line" == "https://"* ]]) && \
            [[ "${line#*//}" != "$ROOT_HOSTNAME"* ]]; then 
            continue
        fi

        # plecam de la premiza ca e link intreg
        promise=$line

        # daca e link relativ la root, ii adaugam ROOT_HOSTNAME
        if [[ "$line" == "/"* ]]; then
            # http este mai sigur
            # daca exista https, atunci vom primi redirect cu 301 Moved Permanently, iar wget se va duce automat pe pagina securizata
            # daca nu exista, atunci descarca pur si simplu pagina
            # https da direct eroare daca nu exista
            # EXEMPLU : Connecting to instagram.com (instagram.com)|185.60.218.174|:443... connected.
                        # HTTP request sent, awaiting response... 301 Moved Permanently
            promise=http://$ROOT_HOSTNAME$line
        # altfel e link relativ la calea curenta
        elif [[ "$line" != "http://$ROOT_HOSTNAME"* ]] && \
            [[ "$line" != "https://$ROOT_HOSTNAME"* ]]; then
            promise=http://$resource_url/$line
        fi

        echo $promise >> $ROOT_DIRECTORY/dupes.txt
    done < <(grep -ohiE '(href|src)="[^"]*"' $resource_directory/$file_name 2> /dev/null | cut -d'"' -f2)

    # elimina duplicatele
    sort -u "$ROOT_DIRECTORY/dupes.txt" 2> /dev/null >> "$ROOT_DIRECTORY/promises.txt"
    
    # sterge tot
    > $ROOT_DIRECTORY/dupes.txt
}

if [[ ! -f "$ROOT_DIRECTORY/promises.txt" ]]; then
    parse-file "./" $ROOT_URL
else
    cat $ROOT_DIRECTORY/promises.txt > $ROOT_DIRECTORY/promises.lock.txt
    rm $ROOT_DIRECTORY/promises.txt 2> /dev/null
    while read line; do 
        resource_hostname="${line#*//}"
        resource_path="${resource_hostname#*/}"
        parse-file $resource_path $line 
    done < $ROOT_DIRECTORY/promises.lock.txt
fi
