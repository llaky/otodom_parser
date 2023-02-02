#!/bin/bash
#
# @description:
# control script for parsing incoming zip archives on FTP and
# for scheduled launch
#
# @author: Denis Romaniko
#

#date +'%Y-%m-%d %H:%M'
workFolder=/home/USER/domains/DOMAIN/public_ftp/
otodomSh=/home/USER/oferty/run/otodom.sh
imageFolder=/home/USER/domains/DOMAIN/public_html/images/
targetFolder=/home/USER/oferty/xml/
targetTmpFolder=/home/USER/tmp/

cd $workFolder

for file in *.zip; do
	## instead of `mv -f "${file}" "${targetTmpFolder}${file}_ok"` do `rm -f "${file}"`
	unzip -oqq "${file}" -d "${imageFolder}" && rm -f "${file}" || mv -f "${file}" "${targetTmpFolder}${file}_failed"
	dataFile="${imageFolder}dane.xml"
	targetFile="${file%%.zip}.xml"
	[ -f "${dataFile}" ] && mv -f "${dataFile}" "${targetFolder}${targetFile}" || echo "error $file"
	$otodomSh "${targetFolder}${targetFile}"
done
