#!/bin/bash
#
# Script to create NetCDF files from BAM_1D binary files
# -------------------------------- WARNING ------------------------------
#
# Not method was found to change endianness of the input binary before write the NetCDF file. 
# input binary is in Big_Endian byte ordering
#
# Usage:
# -
# - Change Levels below in cat command
# - copy all binary and ctl files to a folder
# - ./CreateNetCDFs.sh <FOLDER> <YEAR> <NUM_LEVELS>
#
# Exampĺe
#   ./CreateNetCDFs.sh ./ 2015 64
#
# -------------------------------- WARNING ------------------------------
# Enver Ramirez 
# April 12, 2019 
# December 19, 2019
# January 07, 2020 (modified to be used in GASS/DCP hindcast experiments)
# 2021 end - Improvements, bug fixes and generating one netcdf for all files

# 28 Levels
# levels    = 998.784000 988.730240 972.824605 953.129583 928.950021 899.602751 864.484507 823.111877 775.316067 721.306823 661.797274 597.985963 531.569824 464.520455 398.908336 336.604190 279.136157 227.510011 182.237129 143.358463 110.562392 83.326551 60.986749 42.859819 28.271579 16.608779 7.329076 3.664538

# 64 Levels
# levels    = 1.000000 0.994668 0.988625 0.981788 0.974066 0.965363 0.955574 0.944595 0.932317 0.918626 0.903418 0.886590 0.868054 0.847732 0.825573 0.801550 0.775667 0.747971 0.718548 0.687530 0.655095 0.621462 0.586895 0.551686 0.516152 0.480622 0.445422 0.410871 0.377259 0.344848 0.313859 0.284469 0.256807 0.230960 0.206973 0.184849 0.164563 0.146060 0.129264 0.114086 0.100424 0.088171 0.077216 0.067450 0.058766 0.051062 0.044241 0.038214 0.032894 0.028206 0.024081 0.020455 0.017270 0.014474 0.012024 0.009875 0.007994 0.006347 0.004905 0.003644 0.002543 0.001579 0.000736 0.000368


fdir=$1
year=$2
vertRes=$3

cat > newzaxis << eof
zaxistype = pressure
size      = ${vertRes}
name      = lev
longname  = pressure
units     = mb
levels    = 1.000000 0.994668 0.988625 0.981788 0.974066 0.965363 0.955574 0.944595 0.932317 0.918626 0.903418 0.886590 0.868054 0.847732 0.825573 0.801550 0.775667 0.747971 0.718548 0.687530 0.655095 0.621462 0.586895 0.551686 0.516152 0.480622 0.445422 0.410871 0.377259 0.344848 0.313859 0.284469 0.256807 0.230960 0.206973 0.184849 0.164563 0.146060 0.129264 0.114086 0.100424 0.088171 0.077216 0.067450 0.058766 0.051062 0.044241 0.038214 0.032894 0.028206 0.024081 0.020455 0.017270 0.014474 0.012024 0.009875 0.007994 0.006347 0.004905 0.003644 0.002543 0.001579 0.000736 0.000368
eof

#ls $fdir/*.L${vertRes}.ctl > lista
#ls "${fdir}/"*.L${vertRes}.ctl > lista
#ls ${fdir}/???????????????????????????F*L${vertRes}.ctl > lista

# Denis - bug lista de argumentos muito longa
#ls ${fdir}/GFCTNMC????????????????????F*L${vertRes}.ctl > lista
find ${fdir} -name "GFCTNMC${year}????????????????F*L${vertRes}.ctl" -print0 | xargs -0 >> lista


tdef=`more ${fdir}/GFCTNMC${year}??????F.fct.T062L${vertRes}.ctl |grep TDEF |awk '{print $4}'`

# Denis
tdef=${tdef:3:9}

year=$(date -d "${tdef}" +%Y)

# Denis
# dayOfYear=`expr $(date -d "${tdef}" +%j) + 1`
dayOfYear=`expr $(date -d "${tdef}" +%j)`
month=`expr $(date -d "${tdef}" +%m)`

echo $tdef $year ${dayOfYear} ${month}

idx=${dayOfYear}
for x in `cat lista`
do
newfile=`basename $x ctl`
echo $newfile
sed -i 's/OPTIONS SEQUENTIAL YREV/OPTIONS SEQUENTIAL YREV BIG_ENDIAN/g' ${x}
cdo -f nc import_binary ${x} tmp.nc
cdo setzaxis,newzaxis tmp.nc tmp2.nc
cdo -r settaxis,${year}-01-01t00:00:00 tmp2.nc tmp.nc
cdo setmissval,-9.99e+08 tmp.nc tmp2.nc

# Denis
# ncap2 -O -s 'time={'$idx'}' tmp2.nc ${newfile}nc
echo $idx
ncap2 -O -s '@units="hours since '${year}'-1-1 00:00:00";time=udunits(time,@units);time@units=@units;time={'$idx'}' tmp2.nc ${newfile}nc
rm tmp.nc tmp2.nc
idx=`expr $idx + 1`

#if [ $idx -gt 9 ] ; then break; fi
done
cdo cat GFCTNMC${year}*F.fct.T062L28.nc GFCTNMC${year}.fct.T062L28___ALL.nc
rm newzaxis lista






































