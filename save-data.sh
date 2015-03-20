#!/bin/bash
now=$(date +%-m-%d-%y\ %H:%M)
now+="PST.txt"
ruby get-bet-rois.rb > data/"${now}"
