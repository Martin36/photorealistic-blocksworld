#!/bin/bash

# echo "this test will just render the first 5 images of 2 objs, 2 stacks blocksworld."
# read -n 1 -s -r -p "Press any key to continue"

blenderdir=$(echo blender-2.*/)

rm -rf output

gen_data () {
  # Arguments: 
  #  $1 = number of objects
  echo "Generating data for $1 objects"
  $blenderdir/blender -noaudio --background --python render_images.py -- \
        --output-dir      output                          \
        --render-num-samples 50                           \
        --num-samples-per-state 1                         \
        --start-idx          0                            \
        --width 300                                       \
        --height 200                                      \
        --num-transitions 5                               \
        --filename-prefix "b-$1"                          \
        --only-blocks                                     \
        --num-objects $1

}

for i in {2..9}
do
  gen_data $i
done

# $blenderdir/blender -noaudio --background --python render_images.py -- \
#       --output-dir      output                          \
#       --render-num-samples 50                           \
#       --num-samples-per-state 1                         \
#       --start-idx          0                            \
#       --width 300                                       \
#       --height 200                                      \
#       --num-transitions 5                               \
#       --filename-prefix b-2                             \
#       --num-objects 2
#       # --use-gpu 1                                       \


# ./extract_region.py output/scenes/CLEVR_new_000000_pre.json
# ./extract_region.py output/scenes/CLEVR_new_000000_suc.json
