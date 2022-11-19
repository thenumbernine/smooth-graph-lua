This is a script that works with my gnuplot lua library for taking any input and creating a plot with multiple smoothed layers so you can see what successives smoothing looks like.
Usage:

	smooth_graph.lua datafile.txt sigma [outfile.svg]

Notice if outfile is omitted then it will run in persistent mode.
