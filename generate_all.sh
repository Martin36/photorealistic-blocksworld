#!/bin/bash

# Render all scenes with a given number of objects and stacks.
#
# generate_all.sh [objs] [num_images] [num_jobs] [gpu] [suffix]
#
#   objs:   specity the number of objects, default = 2
# 
#   num_images:  The number of images to be rendered in total.
#
#   num_jobs: how many jobs to use (default: 1). When the number is larger than 1, it switches to the distributed mode.
# 
#   gpu:  if true, use the gpu. default : true.
#
#   suffix:  arbitrary string to be attached to the name of the output directory.
# 
#
# Use it like: parallel ./generate_all.sh {} 30000 true 50 ::: 3 4 5 6
#
# You can modity the "submit" variable in the source code to
# customize the job submission commands for the job scheduler in your cluster.

export objs=${1:-3}         ; shift 1
export num_images=${1:-200} ; shift 1
export num_jobs=${1:-1}     ; shift 1
export gpu=${1:-true}       ; shift 1
export suffix=$1            ; shift 1

if [ $num_jobs -lt 1 ]
then
    export distributed=true
else
    export distributed=false
fi
export dir="blocks-$objs$suffix"
export proj=$(date +%Y%m%d%H%M)-render-$dir
export use_gpu=""
if $gpu
then
    export use_gpu="--use-gpu 1"
fi
  

submit="jbsub -mem 4g -cores 1+1 -queue x86_1h -proj $proj"

job (){
    output_dir=$1
    start_idx=$2
    num_images=$3
    blenderdir=$(echo blender-2.*/)
    $blenderdir/blender -noaudio --background --python render_images.py -- \
                        --render-num-samples 300 \
                        --width 300              \
                        --height 200             \
                        --num-objects $objs      \
                        $use_gpu                 \
                        --output-dir $output_dir \
                        --start-idx $start_idx   \
                        --num-images $num_images
    ./extract_all_regions_binary.py --out $output_dir-objs.npz --resize 32 32 $output_dir
    ./extract_all_regions_binary.py --out $output_dir-bgnd.npz --resize 32 32 --include-background $output_dir
    ./extract_all_regions_binary.py --out $output_dir-flat.npz --resize 100 150 --include-background --exclude-objects $output_dir
}

export -f job
# for parallel to recognize the shell function
export SHELL=/bin/bash

if $distributed
then
    num_images_per_job=$((num_images/num_jobs))
    parallel "$submit job $dir/{} {} $num_images_per_job" ::: $(seq 0 $num_images_per_job $((num_images-num_images_per_job)))
    echo "Run the following command when all jobs have finished:"
    echo "./merge-npz.py --out $dir-objs.npz $dir/*-objs.npz"
    echo "./merge-npz.py --out $dir-bgnd.npz $dir/*-flat.npz"
    echo "./merge-npz.py --out $dir-flat.npz $dir/*-flat.npz"
else
    job $dir 0 $num_images
fi
