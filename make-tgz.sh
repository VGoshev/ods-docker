#!/bin/sh -x
#Make tar.gz archive of this folder for easier distribution

tar cvzf ../ODS-Dockerfile.tgz --exclude='*.tgz' --exclude='*/*.tar.bz2' ./
