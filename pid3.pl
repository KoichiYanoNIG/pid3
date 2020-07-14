#!/usr/bin/perl -w

if (@ARGV != 2) {
    print "usage: pid.pl <reference_genome> <sam>\n";
    exit;
}

open FH, $ARGV[0];
while (<FH>) {
    if (substr ($_, 0, 1) eq '>') {
        ($name) = />(\S+)/;
    }else {
        chomp;
        $seq{$name} .= uc $_;
    }
}
close FH;

%ck = ("CT", 1, "TC", 1, "AG", 1, "GA", 1);

open FH, $ARGV[1];
while (<FH>) {
    last if substr ($_, 0, 1) ne '@';
}

print "name\tFLAG\talignment_length\tmatch\ttransition\ttransversion\tinsertion\tdeletion\n";
do {
    @buf = split/\t/;
    $seq1 = $seq2 = undef;

    $pos1 = $buf[3]-1;
    $pos2 = 0;
    $ins = $del = 0;
    while ($buf[5] =~ /(\d+)([MDI])/g) {
        if ($2 eq 'M') {
            $seq1 .= substr ($seq{$buf[2]}, $pos1, $1);
            $seq2 .= substr ($buf[9], $pos2, $1);
            $pos1 += $1;
            $pos2 += $1;
        }elsif ($2 eq 'D') {
            $seq1 .= substr ($seq{$buf[2]}, $pos1, $1);
            $pos1 += $1;
            for ($i = 0; $i < $1; ++$i) {
                $seq2 .= '-';
            }
            $del += $1;
        }else {
            for ($i = 0; $i < $1; ++$i) {
                $seq1 .= '-';
            }
            $seq2 .= substr ($buf[9], $pos2, $1);
            $pos2 += $1;
            $ins += $1;
        }
    }

    $len = length $seq1;
    $ma = $trs = $trv = 0;
    for ($i = 0; $i < $len; ++$i) {
        $c1 = substr ($seq1, $i, 1);
        $c2 = substr ($seq2, $i, 1);
        if ($c1 eq $c2) { ++$ma; }
        elsif (defined $ck{$c1.$c2}) { ++$trs; }
        else { ++$trv; }
    }

    print $buf[0],"\t",$buf[1],"\t",$len,"\t",$ma,"\t",$trs,"\t",$trv,"\t",$ins,"\t",$del,"\n";
}while (<FH>);
close FH;
