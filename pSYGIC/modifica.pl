#!/usr/bin/perl

use strict;
my $buffer;
my $dumpfile;

my @patchlist = (['30308de52c308de5443091e5020053e1df0000da0090e0e30c908de50270a0e128408de20731a0e13c1096e50400a0e1',16,'020053e1'],
                 ['0020a0e3..fd01eb000050e3bc0000ba24008de2241086e2..fe01eb00309be520308de5',15,'ea'],
                 ['017087e2443096e5070053e130ffffca0c309de5010073e30a00000a08009de5',12,'070053e1',24,'070053e1']
                );

my $file = '/opt/sygic/Drive/Maemo/drive';

if($ARGV[0] ne '') {
    $file = $ARGV[0];
}

open my $fh, '+<', $file or die "open failed: $!\n";

# Dump file in format hex
while ( sysread($fh, $buffer, 4096) ) {
    my @list = unpack('H8192', $buffer);
    $dumpfile .= sprintf("%-8192s", $list[0]);
}

# For each patch search the position, seek in the file and write new data
foreach my $arr (@patchlist) {
    $dumpfile =~ /@$arr[0]/g;
    for(my $ndx=1;$ndx<@$arr;$ndx+=2) {
        if(defined(pos($dumpfile))) {
            my $offset = ((pos($dumpfile) - length(@$arr[0])) / 2) + @$arr[$ndx];
            $buffer = pack('H' . length(@$arr[$ndx+1]),@$arr[$ndx+1]);
            seek($fh,$offset,0);
            syswrite($fh,$buffer);
        }else{
            print "Seguenza di byte non trovata: è il file sbagliato, oppure la patch non funziona più oppure il file è stato già modificato\n";
            print "Pattern not found: maybe wrong file or the patch don't work or already patched file\n";
        }
    }
}

close $fh or die "close failed: $!\n"; 

