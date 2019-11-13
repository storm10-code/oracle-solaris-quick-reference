#!/bin/bash
#
# Requires packages: libstdc++.i686
#   yum -y install glibc.i686
#   yum -y install libstdc++.i686

export TZ="UTC"

default_path=/var/tmp/axiom
parser="${default_path}/bin/axiomstatsparser"
formatter="${default_path}/bin/axiomstatsformatter"
statsloc="${default_path}/stats"
array_list="${default_path}/array_list.txt"

move() {
  for array in $(cat ${array_list}| grep -v ^#)
  do
     if [ -f ${default_path}/.axiom_file_bundle.list.${array} ]; then
         touch ${default_path}/.axiom_file_bundle.list.${array}
         chmod 444 ${default_path}/.axiom_file_bundle.list.${array}
     fi
     rm -f ${default_path}/.axiom_file_bundle.list.${array}
     ls ${statsloc}/[pa]m_$array* >> ${default_path}/.axiom_file_bundle.list.${array}
     for bundles in $(cat ${default_path}/.axiom_file_bundle.list.${array})
     do
         mv ${bundles} ${statsloc}/${array}/
     done
  done
}

extract_and_run_parser() {
   for array in $(cat ${array_list}| grep -v ^#)
   do
     # this is the temporary working directory
     # it will get deleteed do not put anything is here yourself
     if [ ! -d ${statsloc}/${array}/temp ]; then
         mkdir ${statsloc}/${array}/temp
     fi
     rm -f ${statsloc}/${array}/temp/.axiom_file_bundle.list.${array}
     ls ${statsloc}/${array}/[pa]m_$array* >> ${statsloc}/${array}/temp/.axiom_file_bundle.list.${array}
     for bundles in $(cat ${statsloc}/${array}/temp/.axiom_file_bundle.list.${array})
     do
       date_id="$(echo $bundles | awk -F- '{print $2}' | cut -c1-6)"
       file_id="$(echo $bundles | awk -F- '{print $1}')"
       tar xf ${bundles} -C ${statsloc}/${array}/temp
       # work on each file in-turn
       for file_stat in $(ls ${statsloc}/${array}/temp/*tar.gz)
       do
         tar -zxf ${file_stat} -C ${statsloc}/${array}/temp
       done
       # clean-up old tar.gz files
       rm -f  ${statsloc}/${array}/temp/*tar.gz
       if  [ ! -d ${statsloc}/${array}/sps ]; then
            mkdir ${statsloc}/${array}/sps
            chmod 444 ${statsloc}/${array}/sps
       fi
       filename=$(basename ${file_id})
       $parser -i=${statsloc}/${array}/temp/PillarStatistics -o=${statsloc}/${array}/sps/${filename}_perfstats_${date_id}.sps
       #mv ${file_id}_perfstats_${date_id}.sps ${statsloc}/${array}/sps
       rm -rf ${statsloc}/${array}/temp/*
     done
   done
}

formatter() {
   # this directory is where we dump the final report
   if [ ! -d ${statsloc}/${array}/report ]; then
       mkdir ${statsloc}/${array}/report
       chmod 444 ${statsloc}/${array}/report
   fi
   #
   for array in $(cat ${array_list}| grep -v ^#)
   do
      rm -f ${statsloc}/${array}/sps/.axiomsps.list.${array}
      ls ${statsloc}/${array}/sps/[pa]m_$array* >> ${statsloc}/${array}/sps/.axiomsps.list.${array}
      for sps in $(cat ${statsloc}/${array}/sps/.axiomsps.list.${array})
      do
        # sps data format YYMMDD
        # report data format MMDDYY:HH:MM:SS
        date_sps="$(echo $sps | awk -F_ '{print $5}' | cut -c1-6)"
        file_sps="$(echo $sps | awk -F_ '{print $2"_"$3}')"
        pm="$(basename ${sps} | cut -c1-2)"
        day="$(echo $date_sps | cut -c5-6)"
        month="$(echo $date_sps | cut -c3-4)"
        year="$(echo $date_sps | cut -c1-2)"
        # is the day in the evening (pm)
        if [ "${pm}" == "pm" ]; then
            $formatter -i=${sps} -c=SAN -s=LUN -t=UI -T=${month}${day}${year}:12:00:00,${month}${day}${year}:23:59:00 -o=${statsloc}/${array}/report/${file_sps}_${day}${month}${year}_1200-2359_SANLun-UI.csv
            sed 's/......../&,/' ${statsloc}/${array}/report/${file_sps}_${day}${month}${year}_1200-2359_SANLun-UI.csv | sed 's/ //g' | awk -F, '(index($8, "1") != 0) {print}' > ${statsloc}/${array}/report/${file_sps}_${day}${month}${year}_1200-2359_SANLun-UI-cleanup.csv
        # otherwise it is morning (am)
        else
            $formatter -i=${sps} -c=SAN -s=LUN -t=UI -T=${month}${day}${year}:00:00:00,${month}${day}${year}:12:00:00 -o=${statsloc}/${array}/report/${file_sps}_${day}${month}${year}_0000-1159-SANLun-UI.csv
            sed 's/......../&,/' ${statsloc}/${array}/report/${file_sps}_${day}${month}${year}_0000-1159-SANLun-UI.csv | sed 's/ //g' | awk -F, '(index($8, "1") != 0) {print}' > ${statsloc}/${array}/report/${file_sps}_${day}${month}${year}_0000-1159-SANLun-UI-cleanup.csv
        fi
     done
   done
}

create_dir() {
 for array in $(cat ${array_list}|grep -v ^#)
 do
   if [ ! -d ${statsloc}/${array} ]; then
       mkdir ${statsloc}/${array}
   fi
 done
}

###########
# functions
create_dir
move
extract_and_run_parser
formatter
