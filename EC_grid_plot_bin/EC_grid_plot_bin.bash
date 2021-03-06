#!/bin/bash
# Plot Vp, Vs or Au for a binary .ijxyz grid file.

function usage {
	echo "Usage: `basename $0` [CIJ_model.ijxyz.bin] (options)" > /dev/stderr
	echo "Options:" > /dev/stderr
# Not implemented yet:
# 	echo "    -x1 [minx1 maxx1]     :  Define dimensions for horizontal axis" > /dev/stderr
# 	echo "    -x2 [minx2 maxx2]     :  Define dimensions for vertical axis" > /dev/stderr
	echo "    -r [density]          :  Normalise constants by density.  Use '1' if already normalised." > /dev/stderr
	echo "    -x|-y|-z [slice]      :  Plot slice at x|y|z = [slice]." > /dev/stderr
	echo "    -Au                   :  Plot Universal Anisotropy Index (default)" > /dev/stderr
	echo "    -c [colour palette]   :  Use alternative GMT colour palette" > /dev/stderr
	echo "    -cflip                :  Flip the colour palette" > /dev/stderr
	echo "    -p                    :  Plot isotropic average of P wave velocity" > /dev/stderr
	echo "    -s                    :  Plot isotropic average of S wave velocity" > /dev/stderr
	echo "    -dVp, -dVs            :  Plot isotropic velocity as deviation from average" > /dev/stderr
	echo "    -title [title]        :  Add custom title to plot [slice number]" > /dev/stderr
	echo "    -o [outfile]          :  Send output to [outfile]" > /dev/stderr
	echo "    -q                    :  Batch mode: don't display image with gv." > /dev/stderr
	echo "    -scale [min max]      :  Provide custom limits for scale" > /dev/stderr
	exit 1
}

file=$1
shift 1
necs=21  # This is only relevant for binary files in terms of input to Au
den=1000

# Defaults: plot Au to temporary location
Au=1
FIG=`mktemp /tmp/plot_model_Au.psXXXXXXXXXX`
 AU=`mktemp /tmp/plot_model_Au.AuXXXXXXXXXX`
 XY=`mktemp /tmp/plot_model_Au.xyXXXXXXXXXX`
CPT=`mktemp /tmp/plot_model_Au.cptXXXXXXXXXX`
GRD=`mktemp /tmp/plot_model_Au.grdXXXXXXXXXX`
trap "rm -f \"$FIG\" \"$AU\" \"$XY\" \"$CPT\" \"$GRD\"" EXIT

if [ $# -eq 0 ]; then usage; fi

# If we want, take a slice through the model at a specified level
while [ -n "$1" ]; do
	case "$1" in
		-r)
			den=$2
			shift 2 ;;
		-x)
			slice=1
			x=$2
			shift 2
			;;
		-y)
			slice=2
			x=$2
			shift 2
			;;
		-z)
			slice=3
			x=$2
			shift 2
			;;
		-scale)
			if [ $# -lt 3 ]; then usage; fi
			scale=1
			minAu=$2
			maxAu=$3
			shift 3
			;;
		-Au|-A|-au|-a)
			Au=1
			shift
			;;
		-c|-cpt)
			cpt="$2"
			shift 2
			;;
		-cflip|-flip)
			flip=1
			shift
			;;
		-p|-P|-vp|-Vp|-vP)
			p=1
			unset Au
			shift
			;;
		-s|-S|-vs|-Vs|-vS)
			s=1
			unset Au
			shift
			;;
		-dVp|-dvp|-dP|-dp)
			p=1; dv=1
			unset Au
			shift ;;
		-dVs|-dvs|-dS|-ds)
			s=1; dv=1
			unset Au
			shift ;;
		-title)
			title="$2"
			shift 2 ;;
		-o)
			OFIG="$2"
			if [ ! -w `dirname "$OFIG"` ]; then
				echo "`basename $0`: Error: output file \"$OFIG\" not writable." > /dev/stderr
				exit 5
			fi
			shift 2
			;;
		-q)
			quiet=1
			shift
			;;
		*)
			usage
			;;
	esac
done

# Get size of box and, if required, slice value
set -- `EC_grid_inquire_bin $file | awk 'NR==5{printf("%s %s ",$2,$3)} \
	NR==6{printf("%s %s ",$2,$3)} NR==7{printf("%s %s ",$2,$3)} \
	NR==10{printf("%s %s %s",$4,$6,$8)}'`
minx=$1; maxx=$2
miny=$3; maxy=$4
minz=$5; maxz=$6
dx=$7; dy=$8; dz=$9

# If no slice specified, default to first slice in y direction
if [ -z "$slice" ]; then
	slice=2
	x=$miny
fi

# Get the relevant properties for the combination of slices.
# (Using arrays and modulo division would be easier but requires more thought.)
if [ $slice -eq 1 ]; then
	x1=2; x2=3; dx1=$dy; dx2=$dz; dx3=$dx; minx1=$miny; maxx1=$maxy; minx2=$minz; maxx2=$maxz; minx3=$minx; maxx3=$maxx
elif [ $slice -eq 2 ]; then
	x1=1; x2=3; dx1=$dx; dx2=$dz; dx3=$dy; minx1=$minx; maxx1=$maxx; minx2=$minz; maxx2=$maxz; minx3=$miny; maxx3=$maxy
elif [ $slice -eq 3 ]; then
	x1=1; x2=2; dx1=$dx; dx2=$dy; dx3=$dz; minx1=$minx; maxx1=$maxx; minx2=$miny; maxx2=$maxy; minx3=$minz; maxx3=$maxz
fi

# 'Snap' the desired slice point to the true grid value below x
x=`printf "%0.0f" $x`  # Force to be integer
badx=`echo $x ${minx3} ${maxx3} | awk '$1<$2{print "1"} $1>$3{print "1"}'`
if [ -n "$badx" ]; then 
	echo "plot_model_Au_bin: slice must be within range ${minx3} ${maxx3}" > /dev/stderr
	exit 4
fi
#x=$[$x-(($x-(${minx3}))%${dx3})]    # Remove remainder when divided by dx
x=`echo $x $minx3 $dx3 | awk '{print $1- ($1-$2)%$3}'`

# Maximum dimension on plot / cm
maxdim=12
# Calculate size of plot
dims=`echo $minx1 $maxx1 $minx2 $maxx2 $maxdim |\
	awk '{if (($4-$3)<($2-$1)) {print $5,$5*($4-$3)/($2-$1)} \
				else {print $5*($2-$1)/($4-$3),$5}}'`
width=`echo $dims | awk '{print $1}'`
height=`echo $dims | awk '{print $2}'`

# Calculate anisotropy for the  desired slice
# Simultaneously create x-y values for plotting
if [ -n "$Au" ]; then
	EC_grid_bin_dump $file $necs |\
		awk -v x=$x -v x1=${x1} -v x2=${x2} '$'$slice'==x{print $'${x1}',$'${x2}' > "'"$XY"'"; \
		$1=""; $2=""; $3=""; print $0}' | Au $necs | grep -v "redundant" > "$AU"
elif [ -n "$p" ]; then  # Vp with dummy density
	EC_grid_bin_dump $file 36 |\
		awk -v x=$x -v x1=${x1} -v x2=${x2} -v den=$den '$'$slice'==x{print $'${x1}',$'${x2}' > "'"$XY"'"; \
			$1=""; $2=""; $3=""; print $0,den}' | CIJ_iso_av |\
			awk '{print sqrt($1)/1000}'  > "$AU"
elif [ -n "$s" ]; then # Vs with dummy density
	EC_grid_bin_dump $file 36 |\
		awk -v x=$x -v x1=${x1} -v x2=${x2} -v den=$den '$'$slice'==x{print $'${x1}',$'${x2}' > "'"$XY"'"; \
			$1=""; $2=""; $3=""; print $0,den}' | CIJ_iso_av |\
		awk '{print sqrt($22)/1000}' > "$AU"
fi

# Convert to percentage deviation if plotting relative velocities
if [ -n "$dv" ]; then
	meanAu=`awk '$1!="NaN" && $1 >= 0 && $2!="redundant" {n+=1; sum+=$1} END{print sum/n}' "$AU"`
	awk -v mean=$meanAu '$1!="NaN"{print 100*($1-mean)/mean}$1=="NaN"{print}' "$AU" > "${AU}.temp"
	mv "${AU}.temp" "$AU"
fi

# EC_grid_bin_dump $file 36 |\
# 	awk -v x=$x -v x1=${x1} -v x2=${x2} -v den=$den '$'$slice'==x{print $'${x1}',$'${x2}' > "'"$XY"'"; \
# 		$1=""; $2=""; $3=""; print $0,den}' > "$AU"

# Calculate minimum/maxmimum Au/Vp/Vs; NaNs mean Au=0.  Stop if no anisotropy present.
if [ -z "$scale" ]; then
	if [ -z "$dv" ]; then
		# Plotting absolute values
		minmax=`awk 'BEGIN{min=1e36;max=0} \
				$1<min && $1!="NaN" {min=$1; if ($1<0) min=0} \
				$1>max && $1!="NaN" {max=$1}\
				$1=="NaN" {min=0} \
				$1<0 || $1=="redundant" {l=1; min=0} \
				END{if (l==1) print "Warning: Some constants not as expected: some some nodes contain liquid?" > "/dev/stderr" ;\
					print min,max}' "$AU"`
		minAu=`echo $minmax | awk '{printf("%5.3e",$1)}'`
		maxAu=`echo $minmax | awk '{printf("%5.3e",$2)}'`
	else
		# Plotting percentage variation from mean
		minmax=`awk 'function abs(x){if (x<0) return -x; else return x}
				BEGIN {max=-1e36}
				abs($1)>max && $1!="NaN" {max=abs($1)}
				$1=="redundant" {l=1}
				END {if (l==1) print "Warning: Some constants not as expected: some nodes contain liquid?" > "/dev/stderr"
					print max}' "$AU"`
		maxAu=`echo $minmax | awk '{printf("%5.1e",$1)}'`
		minAu=-$maxAu
	fi
	dAu=`echo $minmax | awk '{printf("%5.3e",($2-$1)/3)}'`
fi

# Isotropic case for Au
if [[ "$minmax" == "0 0" || "$maxAu" == "0.000e+00" ]]; then
	echo "`basename $0`: Whole slice is isotropic!" > /dev/stderr
	minAu=0
	maxAu=1
	dAu=0.33
fi

# Uniform Au or velocity for Vp / Vs
if [[ "$minAu" == "$maxAu" ]]; then
	[ -n "$Au" ] && phrase=Au || phrase=velocity
	echo "`basename $0`: Whole slice has same $phrase: $minAu" > /dev/stderr
	minAu=`echo $minAu | awk '{print 0.95*$1}'`
	maxAu=`echo $maxAu | awk '{print 1.05*$1}'`
	dAu=`echo $minAu $maxAu | awk '{printf("%5.3e",($2-$1)/3)}'`
fi

# Make the colour scheme
if [ -n "$Au" ]; then C="hot"; [ -z "$cpt" ] && flip=1; fi
[ -n "$p" -o -n "$s" ] && C="seis"
[ -n "$cpt" ] && C="$cpt"
[ -n "$flip" ] && I=-I
dAu=`echo $minAu $maxAu | awk '{printf("%0.3e",($2-$1)/3)}'`
makecpt -C$C $I -T$minAu/$maxAu/$dAu -D -Z > "$CPT"

# Set title if not done on command line
[ -z "$title" ] && title="@%2%x@%%@-$slice@- = $x"

# Create the plot
gmtset PAPER_MEDIA a4+
paste "$XY" "$AU" |\
	xyz2grd -R${minx1}/${maxx1}/${minx2}/${maxx2} -I${dx1}/${dx2} -G"$GRD"

gmtset HEADER_OFFSET 14p
grdimage "$GRD" -R${minx1}/${maxx1}/${minx2}/${maxx2} \
	-JX${width}c/${height}c -C"$CPT" -P \
	-Ba1000:"@%2%x@%%@-${x1}":/a100:"@%2%x@%%@-${x2}"::."$title":NseW -K > "$FIG"

# Add the scale
[ -n "$Au" ] && label='@%2%A@+U@+'
[ -n "$p" -a -z "$dv" ]  && label='@%2%V@%%@-P@- / km s@+-1'
[ -n "$s" -a -z "$dv" ]  && label='@%2%V@%%@-S@- / km s@+-1'
[ -n "$p" -a -n "$dv" ]  && label="@~d@~@%2%V@%%@-P@- / %"
[ -n "$s" -a -n "$dv" ]  && label="@~d@~@%2%V@%%@-S@- / %"
psscale -D`echo $width/2 | bc -l`c/-1c/8c/0.5ch -A -C"$CPT" -O -S -B/:"$label": \
	>> "$FIG"

if [ -z "$quiet" ]; then  # Don't bring up figure in batch mode
	gv --scale=2 "$FIG" 2>/dev/null
fi

# Save figure to desired location
[ -n "$OFIG" ] && cp "$FIG" "$OFIG"


exit 0
