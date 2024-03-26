#!/bin/bash

# for each of the available IDPs, loop over and create an entry in the download list
for idp in {0001..3935}; do
    echo "https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k/$idp.txt.gz" >> stats33k_urllist.txt
done

# 4 at a time download?
xargs -n1 -P4 -a stats33k_urllist.txt wget -c -np -nc -q

# THIS WILL DOWNLOAD INTO THE FOLDER WITH THE SCRIPT, NOT SURE HOW I WOULD REDIRECT IF I NEEDED TO REPEAT

## other URLs that could be pulled for each of the 3935 summary stats
# https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k/0001.txt.gz             ## full sample
# https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats/0001.txt.gz                ## 22k training sample
# https://open.win.ox.ac.uk/ukbiobank/big40/release2/repro/0001.txt.gz                ## 11k validation sample
# https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats_disco_sexwise/0001.txt.gz  ## 22k training sample split sex-wise 

# example call
#curl -O -L -C - https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k/0001.txt.gz
