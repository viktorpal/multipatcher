#!/bin/bash

#	=== USAGE ===
# 1st arg ABSOLUTE path of the source
# 2nd arg ABSOLUTE path of the destination
# 3rd arg PERCENT of the validation sample images


args=("$@")
source_path=${args[0]}
dest_path=${args[1]}
P=${args[2]}

if [ "$#" -lt 1 ]; then
	echo "Provide the absolute path for directory as the first argument"
elif [ "$#" -lt 2 ]; then
	echo "Provide the absolute path for directory destination path"	
elif [ "$#" -lt 3 ]; then
	echo "Provide the size in percentage of the validation set"
else

	mkdir $dest_path

	if [ -d "$source_path" ]; then
    		echo "directory"
	elif [[ $source_path =~ \.zip$ ]]; then
		echo "zip?"
		unzip $source_path
		rm $source_path
	else
		echo "else"
	fi

	mkdir $dest_path/dataset
	mkdir $dest_path/dataset/train
	mkdir $dest_path/dataset/train/images
	mkdir $dest_path/dataset/train/labels
	mkdir $dest_path/dataset/val
	mkdir $dest_path/dataset/val/images
	mkdir $dest_path/dataset/val/labels

	temp_file=$(mktemp)
	M=$(ls -1 $source_path/images | wc -l)
	N=$(echo "($M*$P*0.01+0.5)/1" | bc)
	echo "Validation set size: $N, total size: $M"
	ls $source_path/images | sort -R | tail -$N > $temp_file

	cp $source_path/images/** $dest_path/dataset/train/images
	cp $source_path/labels/** $dest_path/dataset/train/labels

	# we have copied every file to the learning set, now remove those which will be in the validation set
	cat $temp_file | while read file; do
		rm $dest_path/dataset/train/images/$file
		filename=$(basename "$file" .png)
		rm $dest_path/dataset/train/labels/$filename*
	done
   
	cd $source_path/images
	cat $temp_file | while read file; do
		cp $source_path/images/$file $dest_path/dataset/val/images/
	done
	cd $dest_path/dataset/val/images
	for x in `ls *.png` ; do
  		x=${x%.png}
		cp $source_path/labels/"$x.txt" $dest_path/dataset/val/labels
	done

	rm $temp_file
fi















