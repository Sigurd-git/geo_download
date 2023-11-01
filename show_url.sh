function download_supp_files() {
    local GSE="$1"
	local subseries
	local output_dir="./$GSE"
	mkdir -p $output_dir
	
	if [ ! -f "$output_dir/${GSE}_family.xml" ]; then cd $output_dir; download_miniml_file "$GSE"; cd ..; fi
	if has_subseries ${GSE}_family.xml; then
		subseries=$(grep "SuperSeries of" ${GSE}_family.xml | grep -oP '(?<=target=")GSE[0-9]+')
		echo "The SuperSeries $GSE contains SubSeries: $(echo -n $subseries)"
		for sub_accession in $subseries; do
			local sub_dir="$output_dir/$sub_accession"
			mkdir -p "$sub_dir"
			cd $sub_dir
			download_miniml_file "$sub_accession"
			echo $sub_accession $sub_dir
			for miniml_file in "$sub_dir"/*xml; do
				urls=($(awk -F'[<>]' '/<Supplementary-Data type=".*">/ {getline; if ($0 ~ /series/) print}' "$miniml_file"))
				for url in "${urls[@]}"; do
					# wget -P "$sub_dir" "$url"
                    echo $url
				done
			cd .. 
			done
		done
	fi
	for miniml_file in "$output_dir"/*.xml; do
		urls=($(awk -F'[<>]' '/<Supplementary-Data type=".*">/ {getline; if ($0 ~ /series/) print}' "$miniml_file"))
		for url in "${urls[@]}"; do
			#wget -P "$output_dir" "$url"
			# wget --no-check-certificate -P "$output_dir" "$url"
            echo $url
		done
	done
	find "$output_dir" -type f -name '*.xml.tgz' -exec rm {} \;
	echo "Removed gzipped XML files"
}

function download_miniml_file() {
    local GSE=$1
    local stub="${GSE%???}nnn" # Replace the last three characters of the accession with "nnn"
    local url="https://ftp.ncbi.nlm.nih.gov/geo/series/$stub/$GSE/miniml/$GSE""_family.xml.tgz"
    local output_file="${GSE}_family.xml.tgz"
    echo "Downloading MINiML file for accession $GSE..."
    curl -OJL "$url"

    if [ $? -eq 0 ]; then
        echo "Downloaded MINiML file successfully."
        tar -xvzf "$output_file"
        echo "Extracted MINiML file: ${GSE}_family.xml"
    else
        echo "Failed to download MINiML file for accession $GSE."
    fi

}

function has_subseries() {
	local xml_file="$1"
	local subseries
	subseries=$(grep "SuperSeries of" "$xml_file" | grep -oP '(?<=target=")GSE[0-9]+')
	if [[ -z $subseries ]]; then
		return 1
	else
		return 0
	fi
}