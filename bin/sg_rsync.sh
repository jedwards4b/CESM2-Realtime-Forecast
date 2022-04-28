#!/bin/bash

sourceDir='/glade/campaign/cesm/development/cross-wg/S2S/CESM2/S2SHINDCASTS/p1/zg_500'
destDir='/ftp/pub/jedwards/S2SHINDCASTS/p1/zg_500'

ssh jedwards@burnt.cgd.ucar.edu "mkdir -p $destDir"
rsync -azvh $sourceDir/ jedwards@burnt.cgd.ucar.edu:$destDir

