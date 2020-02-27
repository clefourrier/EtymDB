#!/usr/bin/perl

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use utf8;
use alLanguageNameConverter;
use strict;

my (%formid2form, %compoundingid2compound, %rels);

while (<>) {
  chomp;
  my $origline = $_;
  if (s/^([0-9]+)\t//) {
    ($formid2form{$1}{lang}, $formid2form{$1}{is_reconstructed}, $formid2form{$1}{form}, $formid2form{$1}{sense}) = split /\t/, $_;
  } elsif (s/^(-[0-9]+)//) {
    my $id = $1;
    while (s/\t([0-9]+)//) {
      push @{$compoundingid2compound{$id}}, $1;
    }
    die "<$_>[$origline]" unless $_ eq "";
  } else {
    my ($rel, $to, $from) = split /\t/, $_;
    $rels{$to}{$from}{$rel} = 1;
  }
}

for my $to (sort keys %rels) {
  for my $from (sort keys %{$rels{$to}}) {
    for my $rel (sort keys %{$rels{$to}{$from}}) {
      print id2txt($to)." ".reltype2txt($rel)." ".id2txt($from)."\n";
    }
  }
}


sub id2txt {
  my $id = shift;
  my $r;
  if ($id > 0) {
    $r = formid2txt($id);
  } else {
    for (0..$#{$compoundingid2compound{$id}}) {
      $r .= " + " unless $r eq "";
      $r .= formid2txt($compoundingid2compound{$id}[$_]);
    }
  }
  return $r;
}

sub formid2txt {
  my $fid = shift;
  my $r;
  $r = $formid2form{$fid}{lang}.": ";
  $r .= wikicode2abbr($formid2form{$fid}{lang},1) || "??";
  $r .= " <i>";
  $r .= "*" if $formid2form{$fid}{is_reconstructed};
  $r .= $formid2form{$fid}{form};
  $r .= "</i>";
  if ($formid2form{$fid}{sense}) {
    $r .= " ";
    $r .=  "‘".$formid2form{$fid}{sense}."’";
  }
  return $r;
}

sub reltype2txt {
  my $rt = shift;
  return "<" if $rt eq "inh";
  return "<-" if $rt eq "bor";
  return "<s" if $rt eq "der(s)";
  return "<p" if $rt eq "der(p)";
  return "<d" if $rt eq "der";
  return "<i" if $rt eq "infl";
  return "<c" if $rt eq "cmpd";
  return "<cb" if $rt eq "cmpd+bor";
  return "//" if $rt eq "cog";
  return "~" if $rt eq "altform";
  return "__ERROR__";
  die $rt;
}
