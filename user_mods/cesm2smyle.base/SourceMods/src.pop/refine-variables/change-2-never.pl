#!/usr/bin/perl

#  usage: files.perl < list
my $filename1 = "./ecosys_diagnostics";
my $filename2 = "./ddonlyclean";

open(my $fh1, '<:encoding(UTF-8)', $filename1)
        or die "Could not open file '$filename1' $!";
open(my $fh2, '<:encoding(UTF-8)', $filename2)
        or die "Could not open file '$filename2' $!";

while (my $row1 = <$fh1>) {
        chomp $row1;
        @vars = split(/\s+/,$row1);
        $fc1 = @vars[0];
	#print("$fc1\n");
	seek $fh2, 0, 0;
	$tmp = $row1;
	while (my $row2 = <$fh2>) {
        	chomp $row2;
        	@vars2 = split(/\s+/,$row2);
        	$fc2 = @vars2[1];
		#print("$fc2\n");
		if ($fc1 eq $fc2 ) {
			#print("$fc1 and $fc2 ===========\n");
			#print("$fc1 : never_average\n");
			$tmp = "$fc1 : never_average";
			last;
		}
	}
	$prow = $tmp;
	print("$prow\n");
}