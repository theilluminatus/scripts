#!/bin/bash
# Quickly split a list of EHentai / EXHentai galleries into files containing
# Links to removed galleries or active ones.

GALLERIES=(
'url'
'url'
'url'
)

echo ""
for gallery in "${GALLERIES[@]}"; do
	download_html=$(curl "$gallery")

	if [[ $download_html == *"Gallery Not Available"* ]]; then
        echo "Missing"
        echo $gallery >> './missing.txt'
    else
        echo "Found"
        echo $gallery >> './found.txt'
    fi

	echo ""
done

echo ""
echo "done"
echo ""
