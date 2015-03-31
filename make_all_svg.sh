#!/bin/bash
for I in svg_creators/*
do
    F=`perl -E '$_=shift; s!svg_creators/(.*)\.pl!$1.svg!; print' $I`
    echo "Doing $I > $F . . ."
    perl $I > $F
done
