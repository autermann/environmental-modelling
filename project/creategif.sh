#!/bin/sh
for model in {1..4}; do
	for run in {1..5}; do
		echo "Creating GIF for run $run of model $model"
		ls -1 out/images/model$model/run$run/* \
			| sort -V \
			| xargs gifsicle --delay=10 --output out/images/animation-$model-$run.gif
	done &
done
