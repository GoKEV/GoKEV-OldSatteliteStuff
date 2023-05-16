#!/usr/bin/perl

$subfile = "subman_available.txt";

open SUBFILE, "< $subfile" or do { print "CANNOT OPEN $subfile\n\n"; };

$ntpawyt = 0;
while (chomp(my $line=<SUBFILE>)) {
	if ($line =~ /^Subscription Name/){
		$outfile = "GoKEV_" . $skunicename . "_ENDS_" . $endsnice . ".txt";

		print "$subnicename ($skunicename)\n\t$poolnicename ENDS $endsnice\n\t$outfile\n\n";

		open OUTFILE, "> $outfile" or do { print "CANNOT OPEN $outfile\n\n"; };
		print OUTFILE $sub_text;
		close OUTFILE;

		$subname = $line;
		($subnicename = $line) =~ s/^Subscription Name\:[^a-zA-Z]+(.*)$/$1/g;
		$subnicename =~ s/[^a-zA-Z]/_/g;
		$subnicename =~ s/_+/_/g;
		$sub_text = $line . "\n";
	}else{
		$sub_text .= $line . "\n";
	}

	if ($line =~ /^Ends/){
		($endsnice = $line) =~ s/[^0-9]/_/g;
		$endsnice =~ s/_+/_/g;
		$endsnice =~ s/^_//g;

	}

	if ($line =~ /^SKU/){
		$skuname = $line;
		($skunicename = $line) =~ s/^SKU\:[^a-zA-Z]+(.*)$/$1/g;
		$skunicename =~ s/[^a-zA-Z0-9]/_/g;
		$skunicename =~ s/_+/_/g;

	}


	if ($line =~ /^Pool ID/){
		$poolname = $line;
		($poolnicename = $line) =~ s/^Pool ID\:[^a-zA-Z]+(.*)$/$1/g;
		$poolnicename =~ s/[^a-zA-Z0-9]/_/g;
		$poolnicename =~ s/_+/_/g;

	}



}


close SUBFILE;

