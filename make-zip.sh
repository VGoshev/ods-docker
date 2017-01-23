#!/bin/sh -x
#Make .zip archive of this folder for easier distribution

#tar cvzf ../ODS-Dockerfile.tgz --exclude='*.tgz' --exclude='*/*.tar.bz2' ./
zip --exclude '*/*.tar.bz2' -r ../ODS-Dockerfile.zip .
