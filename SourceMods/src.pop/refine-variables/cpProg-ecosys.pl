#!/usr/bin/perl

#  usage: files.perl < list

 while(<>)
 {
         @vars = split(/\s+/,$_);
         $ivar = @vars[0];
	 #print("ivar = $ivar\n");
         print("grep \'^$ivar :\' ecosys_diagnostics\n");
 }
