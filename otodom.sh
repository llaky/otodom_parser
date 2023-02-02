#!/bin/bash
#
# @description:
# parsing xml files in the Otodom format and
# mapping the received data to csv format
#
# @author: Denis Romaniko
#

dataFile=$1
fileCountIndex=0
maxRecordsPerFile=50
targetCsvFolder=/home/USER/oferty/csv/
imageFolder=/home/USER/domains/DOMAIN/public_html/images/
dbUser=""
dbUserPassw=""
dbName=""

# common info
websiteUrl=DOMAIN
imageSubFolder="/images/"
area_postfix="㎡"
phone=""
email=""

# arrays of common types
offerTypes=("na sprzedaż" "do wynajęcia" "rynek pierwotny")
objectNames=("Mieszkanie" "Dom" "Działka" "Pokój" "Obiekt użytkowy" "Magazyn" "Garaż")
priceCurrencies=("" PLN EUR GPB USD AED EGP)
provinces=("" "dolnośląskie" "kujawsko-pomorskie" "lubelskie" "lubuskie" "łódzkie" "małopolskie" "mazowieckie" "opolskie" "podkarpackie" "podlaskie" "pomorskie" "śląskie" "świętokrzyskie" "warmińsko-mazurskie" "wielkopolskie" "zachodniopomorskie")
countries=("" "Polska")

# arrays of diffrent extras and usage types
flatExtrasMasks=("balkon" "pomieszczenie użytkowe" "garaż" "piwnica" "ogródek" "taras" "winda" "dwupoziomowe" "oddzielna kuchnia" "klimatyzacja" "tylko dla niepalących")
flatSecurityMasks=("rolety antywłamaniowe" "drzwi / okna antywłamaniowe" "domofon / wideofon" "monitoring / ochrona" "system alarmowy" "teren zamknięty")
flatMediaMasks=("internet" "telewizja" "telefon")
flatBuildingMaterial=("cegła" "drewno" "pustak" "keramzyt" "wielka płyta" "beton" "inne" "silikat" "beton komórkowy")
houseMediaMasks=("prąd" "woda" "gaz" "telefon" "kanalizacja" "szambo" "oczyszczalnia")
houseExtrasMasks=("piwnica" "strych" "garaż" "basen" "internet" "telewizja" "klimatyzacja" "umeblowanie")
houseSecurityMasks=("rolety antywłamaniowe" "drzwi / okna antywłamaniowe" "domofon / wideofon" "monitoring / ochrona" "system alarmowy" "teren zamknięty")
houseHeatingMasks=("ogrzewanie gazowe" "ogrzewanie węglowe" "ogrzewanie biomasa" "pompa ciepła" "kolektor słoneczny" "geotermika" "ogrzewanie olejowe" "ogrzewanie elektryczne" "ogrzewanie miejskie" "ogrzewanie kominkowe" "piece kaflowe")
houseBuildingMaterial=("cegła" "drewno" "pustak" "keramzyt" "wielka płyta" "beton" "inne" "silikat" "beton komórkowy")
terrainType=("budowlana" "rolna" "rekreacyjna" "pod inwestycję" "leśna" "siedliskowa" "")
terrainMediaMasks=("prąd" "woda" "gaz" "telefon" "kanalizacja" "szambo" "oczyszczalnia")
terrainVicinityMasks=("las" "jezioro" "otwarty teren" "góry" "morze")
roomMediaMasks=("internet" "telewizja" "telefon")
roomEquipmentMasks=("pralka" "zmywarka" "lodówka" "kuchenka" "piekarnik" "telewizor")
commPropertyMediaMasks=("prąd" "woda" "gaz" "telefon" "internet" "telewizja" "kanalizacja" "szambo" "oczyszczalnia")
commPropertySecurityMasks=("rolety antywłamaniowe" "drzwi / okna antywłamaniowe" "domofon / wideofon" "monitoring / ochrona" "system alarmowy" "teren zamknięty")
commPropertyExtrasMasks=("witryna" "parking" "dojazd asfaltowy" "winda" "klimatyzacja" "ogrzewanie")
commPropertyUseMasks=("obiekt usługowy" "obiekt biurowy" "obiekt handlowy" "obiekt gastronomiczny" "obiekt przemysłowy" "obiekt hotelowy")
hallMediaMasks=("woda" "prąd" "siła" "kanalizacja" "telefon" "gaz" "internet" "szambo" "oczyszczalnia")
hallSecurityMasks=("rolety antywłamaniowe" "drzwi / okna antywłamaniowe" "domofon / wideofon" "monitoring / ochrona" "system alarmowy" "teren zamknięty")
hallUseMasks=("na magazyn" "na produkcję" "na biuro" "na handel")
garageLocalization=("w budynku" "samodzielny" "przy domu")
garageStructure=("murowany" "blaszak" "drewniany" "wiata")

# columns headers
headers="ID,Name,Description,Categories,Tags,Featured image,Images,property status,bedrooms,bathrooms,guest,garages,sale_or_rent_price,price_postfix_text,area,area_postfix_text,Address,local-area,latitude,longitude,city,postcode,state,country,phone,email,web,youtub- video,facebook,linkedin,vimeo,Property_ID,Available_From,Year_Built,Exterior_Material"

fileName=$dataFile"_"$fileCountIndex".csv"
touch $fileName
echo $headers > $fileName

# map data from XML to CSV
for index in $(seq `xmllint --xpath "count(//Insertion)" $dataFile`); do
    action=`xmllint --xpath "//Insertion[$index]/Action/text()" $dataFile 2>/dev/null`
	propertyId=`xmllint --xpath "//Insertion[$index]/ID/text()" $dataFile 2>/dev/null`

	#check Action
	if [ $action -ne 0 ]; then
		sqlQuery="UPDATE wp_posts p SET p.post_status = 'trash' WHERE p.ID IN (SELECT post_id FROM wp_postmeta pm WHERE pm.meta_key = 'Property_ID' and pm.meta_value = '${propertyId}');"
		mysql --user="${dbUser}" --password="${dbUserPassw}" --database="${dbName}" --execute="${sqlQuery}"
		rm -f ${imageFolder}${propertyId}*
		continue
	fi

	_id=""
	tags=""
	imageFeat=""
	images=""
	bedrooms=""
	bathrooms=""
	guest=""
	postcode=""
	youtube=""
	facebook=""
	linkedin=""
	vimeo=""
	availableFrom=""
	yearBuilt=""
	exteriorMaterial=""

	sqlCheckIdQuery="SELECT p.ID FROM wp_posts p WHERE p.ID IN (SELECT pm.post_id FROM wp_postmeta pm WHERE pm.meta_key = 'Property_ID' and pm.meta_value = '${propertyId}') AND p.post_status = 'publish';"
	postIds=`mysql --user="${dbUser}" --password="${dbUserPassw}" --database="${dbName}" -se "${sqlCheckIdQuery}"`
	postIdCnt=`wc -w <<< $postIds`
	[ $postIdCnt -ge 1 ] && _id=`echo ${postIds} | cut -d' ' -f${postIdCnt}`

	name=`xmllint --xpath "concat(//Insertion[$index]/Title/text(), '')" $dataFile | tr -d \* | tr \" \' 2>/dev/null`
    description=`xmllint --xpath "concat(//Insertion[$index]/Description/text(), '')" $dataFile | tr -d \* | tr \" \' 2>/dev/null`

	#set featured image and generate a list of all image files
	imagesCnt=`xmllint --xpath "count(//Insertion[$index]/Photos/Photo)" $dataFile 2>/dev/null`
	[ $imagesCnt -gt 0 ] && imageFeat=`xmllint --xpath "concat('$websiteUrl', '$imageSubFolder', //Insertion[$index]/Photos/Photo/File/text())" $dataFile`
	[ $imagesCnt -gt 0 ] && { for imageIndex in $(seq $imagesCnt); do
			[ ! -z "$images" ] && images=${images}","
			image=`xmllint --xpath "concat('$imageSubFolder', //Insertion[$index]/Photos/Photo[$imageIndex]/File/text())" $dataFile`
			images=${images}${image}
		done }

	offerType=`xmllint --xpath "//Insertion[$index]/OfferType/text()" $dataFile 2>/dev/null`
	propertyStatus=${offerTypes[${offerType}]}

	marketType=`xmllint --xpath "//Insertion[$index]/MarketType/text()" $dataFile 2>/dev/null`
	[[ ( $marketType -eq 0 && $offerType -eq 0 ) ]] && propertyStatus=${offerTypes[2]}

	price=`xmllint --xpath "//Insertion[$index]/Price/text()" $dataFile 2>/dev/null`
	currencyCode=`xmllint --xpath "//Insertion[$index]/PriceCurrency/text()" $dataFile 2>/dev/null`
	[ ! -z $currencyCode ] && pricePostfix=${priceCurrencies[${currencyCode}]} || pricePostfix=""

	area=`xmllint --xpath "//Insertion[$index]/Area/text()" $dataFile 2>/dev/null`

	address=`xmllint --xpath "concat(//Insertion[$index]/Street/text(), '')" $dataFile 2>/dev/null`
	localArea=`xmllint --xpath "concat(//Insertion[$index]/Quarter/text(), '')" $dataFile 2>/dev/null`
	latitude=`xmllint --xpath "//Insertion[$index]/GeoMarker/Latitude/text()" $dataFile 2>/dev/null`
	longitude=`xmllint --xpath "//Insertion[$index]/GeoMarker/Longitude/text()" $dataFile 2>/dev/null`
	city=`xmllint --xpath "concat(//Insertion[$index]/City/text(), '')" $dataFile 2>/dev/null`

	provinceCode=`xmllint --xpath "//Insertion[$index]/Province/text()" $dataFile 2>/dev/null`
	[ ! -z $provinceCode ] && state=${provinces[${provinceCode}]} || state=""

	countryCode=`xmllint --xpath "//Insertion[$index]/Country/text()" $dataFile 2>/dev/null`
	[ ! -z $countryCode ] && country=${countries[${countryCode}]} || country=""

	# detemine a category of a property and extract its specific data
    categoryCode=`xmllint --xpath "//Insertion[$index]/ObjectName/text()" $dataFile`
	category=${objectNames[${categoryCode}]}
	case $categoryCode in
		0)
			mediaMaskCnt=`xmllint --xpath "count(//Insertion[$index]/FlatDetails/MediaMask/value)" $dataFile`
			[ $mediaMaskCnt -gt 0 ] && { for mediaIndex in $(seq $mediaMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/FlatDetails/MediaMask/value[$mediaIndex]/text()" $dataFile`
					tags=${tags}${flatMediaMasks[${value}]}
				done }
			extrasMaskCnt=`xmllint --xpath "count(//Insertion[$index]/FlatDetails/ExtrasMask/value)" $dataFile`
			[ $extrasMaskCnt -gt 0 ] && { for extrasIndex in $(seq $extrasMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/FlatDetails/ExtrasMask/value[$extrasIndex]/text()" $dataFile`
					tags=${tags}${flatExtrasMasks[${value}]}
				done }
			securityMaskCnt=`xmllint --xpath "count(//Insertion[$index]/FlatDetails/SecurityMask/value)" $dataFile`
			[ $securityMaskCnt -gt 0 ] && { for securityIndex in $(seq $securityMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/FlatDetails/SecurityMask/value[$securityIndex]/text()" $dataFile`
					tags=${tags}${flatSecurityMasks[${value}]}
				done }
			exteriorMaterialCode=`xmllint --xpath "//Insertion[$index]/FlatDetails/BuildingMaterial/text()" $dataFile 2>/dev/null`
			[ ! -z $exteriorMaterialCode ] && exteriorMaterial=${flatBuildingMaterial[${exteriorMaterialCode}]} || exteriorMaterial=""
			bedrooms=`xmllint --xpath "//Insertion[$index]/FlatDetails/RoomsNum/text()" $dataFile 2>/dev/null`
			availableFrom=`xmllint --xpath "//Insertion[$index]/FlatDetails/FreeFrom/text()" $dataFile 2>/dev/null`
			yearBuilt=`xmllint --xpath "//Insertion[$index]/FlatDetails/BuildYear/text()" $dataFile 2>/dev/null`
		;;
		1)
			mediaMaskCnt=`xmllint --xpath "count(//Insertion[$index]/HouseDetails/MediaMask/value)" $dataFile`
			[ $mediaMaskCnt -gt 0 ] && { for mediaIndex in $(seq $mediaMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/HouseDetails/MediaMask/value[$mediaIndex]/text()" $dataFile`
					tags=${tags}${houseMediaMasks[${value}]}
				done }
			extrasMaskCnt=`xmllint --xpath "count(//Insertion[$index]/HouseDetails/ExtrasMask/value)" $dataFile`
			[ $extrasMaskCnt -gt 0 ] && { for extrasIndex in $(seq $extrasMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/HouseDetails/ExtrasMask/value[$extrasIndex]/text()" $dataFile`
					tags=${tags}${houseExtrasMasks[${value}]}
				done }
			securityMaskCnt=`xmllint --xpath "count(//Insertion[$index]/HouseDetails/SecurityMask/value)" $dataFile`
			[ $securityMaskCnt -gt 0 ] && { for securityIndex in $(seq $securityMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/HouseDetails/SecurityMask/value[$securityIndex]/text()" $dataFile`
					tags=${tags}${houseSecurityMasks[${value}]}
				done }
			heatingMaskCnt=`xmllint --xpath "count(//Insertion[$index]/HouseDetails/HeatingMask/value)" $dataFile`
			[ $heatingMaskCnt -gt 0 ] && { for heatingIndex in $(seq $heatingMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/HouseDetails/HeatingMask/value[$heatingIndex]/text()" $dataFile`
					tags=${tags}${houseHeatingMasks[${value}]}
				done }
			exteriorMaterialCode=`xmllint --xpath "//Insertion[$index]/HouseDetails/BuildingMaterial/text()" $dataFile 2>/dev/null`
			[ ! -z $exteriorMaterialCode ] && exteriorMaterial=${houseBuildingMaterial[${exteriorMaterialCode}]} || exteriorMaterial=""
			bedrooms=`xmllint --xpath "//Insertion[$index]/HouseDetails/RoomsNum/text()" $dataFile 2>/dev/null`
			availableFrom=`xmllint --xpath "//Insertion[$index]/HouseDetails/FreeFrom/text()" $dataFile 2>/dev/null`
			yearBuilt=`xmllint --xpath "//Insertion[$index]/HouseDetails/BuildYear/text()" $dataFile 2>/dev/null`
		;;
		2)
			mediaMaskCnt=`xmllint --xpath "count(//Insertion[$index]/TerrainDetails/MediaMask/value)" $dataFile`
			[ $mediaMaskCnt -gt 0 ] && { for mediaIndex in $(seq $mediaMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/TerrainDetails/MediaMask/value[$mediaIndex]/text()" $dataFile`
					tags=${tags}${terrainMediaMasks[${value}]}
				done }
			vicinityMaskCnt=`xmllint --xpath "count(//Insertion[$index]/TerrainDetails/VicinityMask/value)" $dataFile`
			[ $vicinityMaskCnt -gt 0 ] && { for vicinityIndex in $(seq $vicinityMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/TerrainDetails/VicinityMask/value[$vicinityIndex]/text()" $dataFile`
					tags=${tags}${terrainVicinityMasks[${value}]}
				done }
			terrainTypeCode=`xmllint --xpath "//Insertion[$index]/TerrainDetails/Type/text()" $dataFile 2>/dev/null`
			[ ! -z $terrainTypeCode ] && { 
				[ ! -z "$tags" ] &&  tags=${tags}","
				tags=${tags}${terrainType[${terrainTypeCode}]} 
			}
		;;
		3)
			mediaMaskCnt=`xmllint --xpath "count(//Insertion[$index]/RoomDetails/MediaMask/value)" $dataFile`
			[ $mediaMaskCnt -gt 0 ] && { for mediaIndex in $(seq $mediaMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/RoomDetails/MediaMask/value[$mediaIndex]/text()" $dataFile`
					tags=${tags}${roomMediaMasks[${value}]}
				done }
			equipmentMasksCnt=`xmllint --xpath "count(//Insertion[$index]/RoomDetails/EquipmentMask/value)" $dataFile`
			[ $equipmentMasksCnt -gt 0 ] && { for equipIndex in $(seq $equipmentMasksCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/RoomDetails/EquipmentMask/value[$equipIndex]/text()" $dataFile`
					tags=${tags}${roomEquipmentMasks[${value}]}
				done }
			bedrooms=`xmllint --xpath "//Insertion[$index]/RoomDetails/RoomsNum/text()" $dataFile 2>/dev/null`
			availableFrom=`xmllint --xpath "//Insertion[$index]/RoomDetails/FreeFrom/text()" $dataFile 2>/dev/null`
		;;
		4)
			mediaMaskCnt=`xmllint --xpath "count(//Insertion[$index]/CommercialPropertyDetails/MediaMask/value)" $dataFile`
			[ $mediaMaskCnt -gt 0 ] && { for mediaIndex in $(seq $mediaMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/CommercialPropertyDetails/MediaMask/value[$mediaIndex]/text()" $dataFile`
					tags=${tags}${commPropertyMediaMasks[${value}]}
				done }
			extrasMaskCnt=`xmllint --xpath "count(//Insertion[$index]/CommercialPropertyDetails/ExtrasMask/value)" $dataFile`
			[ $extrasMaskCnt -gt 0 ] && { for extrasIndex in $(seq $extrasMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/CommercialPropertyDetails/ExtrasMask/value[$extrasIndex]/text()" $dataFile`
					tags=${tags}${commPropertyExtrasMasks[${value}]}
				done }
			securityMaskCnt=`xmllint --xpath "count(//Insertion[$index]/CommercialPropertyDetails/SecurityMask/value)" $dataFile`
			[ $securityMaskCnt -gt 0 ] && { for securityIndex in $(seq $securityMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/CommercialPropertyDetails/SecurityMask/value[$securityIndex]/text()" $dataFile`
					tags=${tags}${commPropertySecurityMasks[${value}]}
				done }
			useMaskCode=`xmllint --xpath "//Insertion[$index]/CommercialPropertyDetails/PropertyUseMask/text()" $dataFile 2>/dev/null`
			[ ! -z $useMaskCode ] && { 
				[ ! -z "$tags" ] &&  tags=${tags}","
				tags=${tags}${commPropertyUseMasks[${useMaskCode}]} 
			}
			availableFrom=`xmllint --xpath "//Insertion[$index]/CommercialPropertyDetails/FreeFrom/text()" $dataFile 2>/dev/null`
			yearBuilt=`xmllint --xpath "//Insertion[$index]/CommercialPropertyDetails/BuildYear/text()" $dataFile 2>/dev/null`
		;;
		5)
			mediaMaskCnt=`xmllint --xpath "count(//Insertion[$index]/HallDetails/MediaMask/value)" $dataFile`
			[ $mediaMaskCnt -gt 0 ] && { for mediaIndex in $(seq $mediaMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/HallDetails/MediaMask/value[$mediaIndex]/text()" $dataFile`
					tags=${tags}${hallMediaMasks[${value}]}
				done }
			securityMaskCnt=`xmllint --xpath "count(//Insertion[$index]/HallDetails/SecurityMask/value)" $dataFile`
			[ $securityMaskCnt -gt 0 ] && { for securityIndex in $(seq $securityMaskCnt); do
					[ ! -z "$tags" ] && tags=${tags}","
					value=`xmllint --xpath "//Insertion[$index]/HallDetails/SecurityMask/value[$securityIndex]/text()" $dataFile`
					tags=${tags}${hallSecurityMasks[${value}]}
				done }
			useMaskCode=`xmllint --xpath "//Insertion[$index]/HallDetails/PropertyUseMask/text()" $dataFile 2>/dev/null`
			[ ! -z $useMaskCode ] && { 
				[ ! -z "$tags" ] &&  tags=${tags}","
				tags=${tags}${hallUseMasks[${useMaskCode}]} 
			}
		;;
		6)
			localCode=`xmllint --xpath "//Insertion[$index]/GarageDetails/Localization/text()" $dataFile 2>/dev/null`
			[ ! -z $localCode ] && { 
				[ ! -z "$tags" ] &&  tags=${tags}","
				tags=${tags}${garageLocalization[${localCode}]} 
			}
			structureCode=`xmllint --xpath "//Insertion[$index]/GarageDetails/Structure/text()" $dataFile 2>/dev/null`
			[ ! -z $structureCode ] && { 
				[ ! -z "$tags" ] &&  tags=${tags}","
				tags=${tags}${garageStructure[${structureCode}]} 
			}
		;;
	esac

	# put a record to CSV file
    echo $_id,\"$name\",\"$description\",$category,\"$tags\",$imageFeat,\"$images\",$propertyStatus,$bedrooms,$bathrooms,$guest,$garages,$price,$pricePostfix,$area,$area_postfix,$address,$localArea,$latitude,$longitude,$city,$postcode,$state,$country,$phone,$email,$websiteUrl,$youtube,$facebook,$linkedin,$vimeo,$propertyId,$availableFrom,$yearBuilt,$exteriorMaterial >> $fileName

	# create new CSV file if maxRecords is reached
	[ $((index % maxRecordsPerFile)) -eq 0 ] && {
		php -f /home/etalonej/oferty/run/csv_save_db_my.php $fileName
		mv -f "${fileName}" "${targetCsvFolder}"
		fileCountIndex=$((index / maxRecordsPerFile))
		fileName=$dataFile"_"$fileCountIndex".csv"
		touch $fileName
		echo $headers > $fileName
	}
done

# import CSV data to Wordpress based site
php -f /home/etalonej/oferty/run/csv_save_db_my.php $fileName
mv -f "${fileName}" "${targetCsvFolder}"
