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
    ($formid2form{$1}{lang}, $formid2form{$1}{is_reconstructed}, $formid2form{$1}{word}, $formid2form{$1}{sense}) = split /\t/, $_;
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

my $n;
for my $to (sort keys %rels) {
  $n++;
  print "<entry xml:id=\"".$formid2form{$to}{lang}.":".$formid2form{$to}{word}.":".$formid2form{$to}{sense}."\" xml:lang=\"".$formid2form{$to}{lang}."\">\n";
  print "  <form type=\"lemma\">\n";
  print "    <orth>".$formid2form{$to}{word}."</orth>\n";
  print "  </form>\n";
  if ($formid2form{$to}{sense} ne "") {
    print "  <sense>\n";
    print "    <cit type=\"translation\" xml:lang=\"en\">\n";
    print "      <oRef>".$formid2form{$to}{sense}."<oRef>\n";
    print "    </cit>\n";
    print "  </sense>\n";
  }
  rec_print_etym($to,2,0);#1);
  print "</entry>\n";
}

sub rec_print_etym {
  my $tfid = shift;
  my $offset = shift;
  my $show_cognates = shift;
  my $nb_etyms;
  for (keys %{$rels{$tfid}}) {
    $nb_etyms++ if $show_cognates || !defined($rels{$tfid}{$_}{cog});
  }
  if ($nb_etyms > 1) {
    print (" "x$offset);
    print "<etym type=\"alt\">\n";
    $offset += 2;
  }
  for my $sfid (sort keys %{$rels{$tfid}}) {
    next unless $show_cognates || !defined($rels{$tfid}{$sfid}{cog});
    my $rel;
    for (keys %{$rels{$tfid}{$sfid}}) {
      $rel = $_;
      last;
    }
    next if $rel eq "";
    my @sfid_components = ();
    if ($sfid > 0) {
      push @sfid_components, $sfid;
    } else {
      for (0..$#{$compoundingid2compound{$sfid}}) {
	push @sfid_components, $compoundingid2compound{$sfid}[$_];
      }
    }
    print (" "x$offset);
    print "<etym type=\"".reltype2value($rel)."\">\n";
    $offset += 2;
    for my $sfid_c (@sfid_components) {
      print (" "x$offset);
      print "<cit type=\"etymon\">\n";
      $offset += 2;
      print (" "x$offset);
      print "<oRef xml:lang=\"".$formid2form{$sfid_c}{lang}."\">".$formid2form{$sfid_c}{word}."</oRef>\n";;
      if ($formid2form{$sfid_c}{sense} ne "") {
	print (" "x$offset);
	print "<gloss>".$formid2form{$sfid_c}{sense}."</gloss>\n";
      }
      if (defined($rels{$sfid_c})) {
	if ($offset > 60) {
	  print "<!-- WARNING: POSSIBLE LOOP HERE -->\n";
	} else {
	  rec_print_etym($sfid_c,$offset,0);
	}
      }
      $offset -= 2;
      print (" "x$offset);
      print "</cit>\n";
    }
    $offset -= 2;
    print (" "x$offset);
    print "</etym>\n";
  }
  if ($nb_etyms > 1) {
    $offset -= 2;
    print (" "x$offset);
    print "</etym>\n";
  }
}


sub reltype2value {
  my $rt = shift;
  return "inheritance" if $rt eq "inh";
  return "borrowing" if $rt eq "bor";
  return "suffixalDerivation" if $rt eq "der(s)";
  return "prefixalDerivation" if $rt eq "der(p)";
  return "derivation" if $rt eq "der";
  return "inflection" if $rt eq "infl";
  return "compound" if $rt eq "cmpd";
  return "compound+borrowing" if $rt eq "cmpd+bor";
  return "cognate" if $rt eq "cog";
  return "alternativeForm" if $rt eq "altform";
  return "__ERROR__($rt)";
  die $rt;
}
