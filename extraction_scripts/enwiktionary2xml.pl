#!/usr/bin/perl

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use utf8;
use alLanguageNameConverter;

print "<dictionary author=\"enwiktionary\">\n";

# TODO:
#   {{named-after
#   {{blend


#my $will_output_cur_entry = 0;
my ($cur_lexeme, $wikilang, $cur_lang, $content, %forms, $english_translation);
my ($cur_pos, $cur_infl_template);
my ($in_etym, $in_desc, $in_infl, $in_alt);
my $w = qr/[^ ,;()\[\]{}&<>]/;

while (<>) {
  chomp;
  s/^\s+//;
  s/\s+$//;
  if (/^<title>(.*)<\/title>\s*/) {
    print_cur_entry() if $wikilang ne "" && $cur_pos ne "";
    $cur_lexeme = $1;
    $cur_pos = "";
    $cur_infl_template = "";
    $wikilang = "";
  } elsif (/^(?:<text xml:space="preserve">\s*)?==([^=]+)==\s*$/) {
    print_cur_entry() if $wikilang ne "" && $cur_pos ne "";
    $wikilang = $1;
    $cur_lang = name2abbr($wikilang,1); #returns "" if unknown thanks to non-null second argument
    $cur_pos = "";
    $cur_infl_template = "";
  } elsif (/^===Etymology(?:\s*\d+)?==+$/) {
##?    print_cur_entry();
#    $will_output_cur_entry = 1;
    $in_etym = 1;
    $in_desc = 0;
    $in_infl = 0;
    $in_alt = 0;
  } elsif (/^==+Descendants==+$/) {
#    $will_output_cur_entry = 1;
    $in_etym = 0;
    $in_desc = 1;
    $in_infl = 0;
    $in_alt = 0;
  } elsif (/^==+alternative forms==+$/i) {
#    $will_output_cur_entry = 1;
    $in_etym = 0;
    $in_desc = 0;
    $in_infl = 0;
    $in_alt = 1;
  } elsif (/^=====?(?:Conjugation|Declension)=====?$/) {
    $in_etym = 0;
    $in_desc = 0;
    $in_infl = 1;
    $in_alt = 0;
  } elsif (/^==/) { # je pense que ça doit être toujours au moins /^=== (sinon cf. 1ere cond)
    #full list in TMPLIST
    $in_etym = 0;
    $in_desc = 0;
    $in_infl = 0;
    $in_alt = 0;
    if (/^====Translations/) {
      $in_translations = 1;
      $in_definitions = 0;
    } elsif (/^====?(Noun|Verb|Adjective|Proper noun|Adverb|Interjection|Preposition|Numeral|Conjunction|Particle|Determiner|Adjectival noun)=/) {
      print_cur_entry() if $wikilang ne "" && $cur_pos ne "";
      $cur_pos = $1;
      $in_translations = 0;
      $in_definitions = 1;
      $cur_infl_template = "";
    } else {
      $in_translations = 0;
      $in_definitions = 0;
    }
  } elsif (/^\[\[[^\[\]]+\]\]$/) {
    $in_etym = 0;
    $in_desc = 0;
    $in_translations = 0;
    $in_definitions = 0;
  } else {
    if ($in_translations) {
      if (/\{\{t\|en\|([^{}\|]+)/) {
	$english_translation .= "; ".$1;
      }
    } elsif ($in_definitions || $in_infl) {
      if (/^{{(fro-.*?)}}/) {
	$cur_infl_template = $1;
      } elsif (/^{{(head|fro|verb)}}$/) {
	$cur_infl_template = $1;
      }
    } elsif ($in_desc) {
      if (/^\* .*: \{\{(l)\|([^{}]+)\}\}$/) {
	$descendants .= convert($1,$2)."\n";
      } # TODO: * Italian: {{l|it|mangiare}} {{qualifier|borrowed}}
    } elsif ($in_alt) {
      while (s/^.*?\{\{(l)\|([^{}]+)\}\}//) {
	$altforms .= "      ".convert($1,$2)."\n";
      }
    } elsif ($in_definitions && $wikilang ne "English") {
      if (s/^# //) {
	s/\{\{l\|en\|([^{}\|]+)\}\}/\1/g;
	while (s/\{\{[^{}]+\}\}//g) {}
	s/&lt;ref .*?&gt;&lt;\/ref&gt;//g;
	s/\([^()]+\)//g;
	unless (/^\s*$/) {
	  s/\[\[[^\[\]\|]+\|([^\[\]]+)\]\]/\1/g;
	  s/\[\[([^\[\]]+)\]\]/\1/g;
	  s/\s+/ /g;
	  s/^ //;
	  s/ $//;
	  s/ ?\.$//;
	  if (/^\w+$/) {
	    $english_translation .= "; ".$_;
	  } elsif (/(?:^|;)((?:(?:to|an?|the) )?$w+(?: $w+(?: $w+)?)?(?:; (?:(?:to|an?|the) )?$w+(?: $w+(?: $w+)?)?)*)(?:;|$)/i) {
	    $english_translation .= "; ".$1;
	  } elsif (/(?:^|;)((?:to|an?|the) $w+(?: $w+(?: $w+)?)?), ((?:to|an?|the) $w+(?: $w+(?: $w+)?)?), ((?:to|an?|the) $w+(?: $w+(?: $w+)?)?), ((?:to|an?|the) $w+(?: $w+(?: $w+)?)?)(?:[;,]|$)/i) {
	    $english_translation .= "; $1; $2; $3; $4";
	  } elsif (/(?:^|;)((?:to|an?|the) $w+(?: $w+(?: $w+)?)?), ((?:to|an?|the) $w+(?: $w+(?: $w+)?)?), ((?:to|an?|the) $w+(?: $w+(?: $w+)?)?)(?:[;,]|$)/i) {
	    $english_translation .= "; $1; $2; $3";
	  } elsif (/(?:^|;)((?:to|an?|the) $w+(?: $w+(?: $w+)?)?), ((?:to|an?|the) $w+(?: $w+(?: $w+)?)?)(?:[;,]|$)/i) {
	    $english_translation .= "; $1; $2";
	  } elsif (/(^|;)an? ($w+) or ($w+)(;|$)/i) {
	    $english_translation .= "; $1; $2";
	  } elsif (/^($w{3,}), ($w{3,})$/i) {
	    $english_translation .= "; $1; $2";
	  } elsif (/^($w{3,} $w{3,}), ($w{3,} $w{3,})$/i) {
	    $english_translation .= "; $1; $2";
	  } elsif (/^($w{2,}), ($w{3,} $w+ $w{3,})$/i) {
	    $english_translation .= "; $1; $2";
	  }
	  $english_translation =~ s/; (?:an?|the) ([^;])/; $1/gi;
	  $english_translation =~ s/; To /; to /gi;
	}
      }
    }
    $_ = clean_wiki_etym($_);

    $content .= "\n" unless $content eq "";

    while (s/^(.*?)\{\{((?:suf|pre)fix|compound|affix|etyl|m(?:ention)?|l(?:ink)?|PIE root|cog(?:nate)?|der|back-form|bor(?:rowing)?|inh(?:erited)?|abbreviation of|etymtwin|inh|doublet|alternative form of)\|(.*?)\}\}//) {
      $before = $1;
      $template = convert($2,$3);
      $form = "";
      if ($template =~ /^<form/) {
	$form = $template;
      }
      if ($in_etym) {
	$content .= clean_wiki($before);
	$content .= $template;
      } else {
	$forms{"    ".$form} = 1 unless $form eq "";
      }
    }
    if ($in_etym) {
      $content .= clean_wiki($_);
    }
    $content =~ s/<lang lang="([^"<>]+)" l="[^<>"]+"[^<>]*\/> <form lang="\1"/<form lang="$1"/g;
  }
}
print_cur_entry();
print "</dictionary>\n";

sub clean_wiki {
  my $s = shift;
  $s =~ s/&lt;ref([^&]|&quot;)*&gt;.*?&lt;\/ref&gt;//g;
  $s =~ s/&lt;ref([^&]|&quot;)*\/&gt;//g;
  $s =~ s/&lt;!-- .*?--&gt;//g;
  $s =~ s/\{\{(?:wikispecies|wikipedia)[^{}]*}}//g;
  $s =~ s/\[\[Image[^\[\]]*\]\]//g;
  $s =~ s/\{\{w\|([^{}\|]*)\}\}/\1/g;
  $s =~ s/\{\{term\|([^\|{}]+)\}\}/<i>\1<\/i>/g;
  $s =~ s/{{number box\|[^\|{}]*\|(\d+)}}/$1. /g;
  $s =~ s/{{rfe\|[^{}]*}}//g;
  $s =~ s/{{attention\|[^{}]*}}//g;
  $s =~ s/\{\{unk\.\|\. \}\}/Unknown/;
  $s =~ s/\{\{rfscript\|[^}]*\}\}//g;
  return $s;
}

sub clean_wiki_etym {
  my $s = shift;

  $s =~ s/\[\[[^\[\]\|]+\|([^\[\]\|]+)\]\]/\1/g;
  $s =~ s/\[\[([^\[\]\|]+)\]\]/\1/g;
  $s =~ s/&amp;/&/g;
  $s =~ s/&nbsp;/ /g;
  $s =~ s/\|(?:sc|tr)=[^\|{}]+//g;

  $s =~ s/Abbreviation of ''([^ ]+)''/Abbreviation of <form lang="$cur_lang">$1<\/form>/g;

  return $s;
}

sub clean_meaning {
  my $s = shift;
  $s =~ s/^\[I\] /to /;
  $s =~ s/''//g;
  if ($s =~ /, /) {
    if ($s =~ /^to /) {
      $s =~ s/, /, to /g;
      $s =~ s/, to to /, to /g;
    } else {
      $s =~ s/(^|, )a //;
    }
  }
  $s =~ s/’, ‘/, /g;
  $s =~ s/&quot;, &quot;/, /g;
  $s = "id." if $s eq "id";
  return $s;
}

sub clean_lexeme {
  my $lexeme = shift;
  my $lang = shift;
  $lexeme =~ s/^\s+//;
  $lexeme =~ s/\s+$//;
  if ($lang eq "PIE") {
    $lexeme =~ s/h1/h₁/g;
    $lexeme =~ s/h2/h₂/g;
    $lexeme =~ s/h3/h₃/g;
    $lexeme =~ s/h4/h₄/g;
    $lexeme =~ s/([bpgkdt])h([^₁₂₃₄ªᵃ]|$)/\1ʰ\2/g;
    $lexeme =~ s/([bpgkdt])h([^₁₂₃₄ªᵃ]|$)/\1ʰ\2/g;
    $lexeme =~ s/([gk]ʰ?)w/\1ʷ/g;
    $lexeme =~ s/ʰʷ/ʷʰ/g;
    $lexeme =~ s/([^hH])([₁₂₃₄])/\1h\2/g;
  }
  return $lexeme;
}

sub clean_lang {
  my $lang = shift;
  my $lexeme = shift;
  if ($lang eq "AGr.") {
    $lang = "Gr.";
  } elsif ($lang eq "Gr." && $lexeme !~ /[ἀἐἰὀὐἠὠἄἔἴὄὔἤὤἁἑἱὁὑἡὡἅἕἵὅὕἥὥῤῥᾶῖῦῆῶῇῷῃῳὰὲὶὸὺὴὼἆἶὖἦὦἇἷὗἧὧ]/) {
    $lang = "MoGr";
  }
  return $lang;
}

sub print_cur_entry {
  return if $cur_lang eq "";
  $cur_lexeme =~ s/^Reconstruction:([^\/]+)\/\*?(.+)$/$2/;
  if ($cur_lexeme !~ /^(?:[A-Z][a-z]+):/) { # $will_output_cur_entry &&
    my $header = "<form lang=\"$cur_lang\" l=\"".(name2wikicode($wikilang) || "??")."\"";
    if ($english_translation ne "") {
      $english_translation =~ s/^; //;
      while ($english_translation =~ s/(^|; )([^;]+)((?:; .+)?); \2(;|$)/\1\2\3\4/g) {}
      $header .= " sense=\"$english_translation\"" unless $english_translation eq "";
    }
    $header .= ">$cur_lexeme</form>";
    print "<entry id=\"$cur_lexeme#$wikilang\">\n";
    print "  <header";
    print " ms=\"$cur_pos\"" if $cur_pos ne "";
    print " infl=\"$cur_infl_template\"" if $cur_infl_template ne "";
    print ">$header</header>\n";
    if ($altforms ne "") {
      print "  <altforms>\n";
      print "    $altforms\n";
      print "  </altforms>\n";
    }
    $content =~ s/^\s+//;
    $content =~ s/\n+\s*$//;
    $content =~ s/\n+/\n/;
    $content =~ s/\s*\n\s*/\n/;
    if ($content ne "" || $descendants ne "") {
      print "  <etymology>\n";
      print $content."\n" if $content ne "";
      if ($descendants ne "") {
	print "  <descendants>\n";
	$descendants =~ s/(^|\n)(.)/$1    $2/g;
	print $descendants;
	print "  </descendants>\n";
      }
      print "  </etymology>\n";
    }
    if (scalar keys %forms > 0) {
      print "  <forms>\n";
      print join("\n", sort keys %forms)."\n";
      print "  </forms>\n";
    }
    print "</entry>\n";
  }
#  $will_output_cur_entry = 0;
  $in_etym = 0;
  $in_desc = 0;
  %forms = ();
  $content = "";
  $descendants = "";
  $altforms = "";
  $english_translation = "";
}

sub convert {
  my $tpl = shift;
  my $s = shift;
  my $orig = $tpl."\t".$s;
  my $i = 0;
  my %tpl;
  my $v;
  if ($tpl =~ /^bor(?:rowing)?$/) {
     $s =~ s/^(?:(.*)\|)?lang=([^\|]+)/$2|$1/;
     $s =~ s/^([^\|]+\|[^\|]+\|)$/|$1/;
  }
  $s = reorder_template_args($s);
  $tpl = "back-form" if $tpl eq "back-formation";
#  print STDERR $tpl."\t".$s."\n";
  $s =~ s/^([^=\|]+)\|(.*)$/$2|lang=$1/g if $s !~ /lang=/ && $tpl =~ /^(?:suffix|prefix|affix|compound|etymtwin|back-form|abbreviation of|doublet)$/;
#  print STDERR ">".$tpl."\t".$s."\n";
  $s .= "|";
  while ($s =~ s/^([^\|]*)\|//) {
    $v = $1;
    if ($v =~ s/^([^=]+)=//) {
      next if $v eq "";
      $lbl = $1;
    } else {
      $i++;
      next if $v eq "";
      if (($tpl =~ /^(bor(?:rowing)?|der(?:ived)?|inh(?:erited)?|PIE root)$/ && $i == 1)
	  || ($tpl =~ /^etyl$/ && $i == 2)) {
	$lbl = "trglang";
      } elsif (($tpl =~ /^(l(?:ink)?|m(?:mention)?|cog(?:nate)?|etyl||etymtwin)$/ && $i == 1)
	       || ($tpl =~ /^(bor(?:rowing)?|der(?:ived)?|inh(?:erited)?)$/ && $i == 2)) {
	$lbl = "lang";
      } elsif (($tpl =~ /^(back-form|abbreviation of|etymtwin|doublet|alternative form of)$/ && $i == 1)
	       || ($tpl =~ /^(l(?:ink)?|m(?:mention)?|cog(?:nate)?)$/ && $i == 2)
	       || ($tpl =~ /^(bor(?:rowing)?|der(?:ived)?|inh(?:erited)?)$/ && $i == 3)) {
	$lbl = "__content";
      } elsif (($tpl =~ /^(abbreviation of)$/ && $i == 2)) {
	next;
      } elsif (($tpl =~ /^(l(?:ink)?|m(?:mention)?|cog(?:nate)?)$/ && $i == 3)
	       || ($tpl =~ /^(bor(?:rowing)?|der(?:ived)?|inh(?:erited)?)$/ && $i == 4)) {
	$lbl = "pparts";
      } elsif (($tpl =~ /^(abbreviation of)$/ && $i == 3)
	       ||($tpl =~ /^(m(?:ention)?|l(?:ink)?|cog(?:nate)?)$/ && $i == 4)
	       || ($tpl =~ /^(bor(?:rowing)?|der(?:ived)?|inh(?:erited)?)$/ && $i == 5)) {
	$lbl = "sense";
      } elsif (($tpl =~ /^(suffix)$/ && $i == 1)) {
	$tpl{__content} = $v;
	$lbl = "base";
      } elsif (($tpl =~ /^(suffix)$/ && $i == 2)) {
	$tpl{__content} .= " + ".$v;
	$lbl = "suffix";
      } elsif (($tpl =~ /^(compound)$/ && $i >= 1)) {
	$tpl{__content} = $v;
	$lbl = "comp".$i;
      } elsif (($tpl =~ /^(prefix)$/ && $i == 1)) {
	$tpl{__content} = $v;
	$lbl = "prefix";
      } elsif (($tpl =~ /^(prefix)$/ && $i == 2)) {
	$tpl{__content} .= " + ".$v;
	$lbl = "base";
      } elsif (($tpl =~ /^(affix)$/ && $i =~ /^\d+$/)) {
	$tpl{__content} .= " + " if $i > 1;
	$tpl{__content} .= $v;
	$lbl = "component".$i;
      } elsif (($tpl =~ /^(PIE root)$/ && $i == 2)) {
	$tpl{lang} = "PIE";
	$tpl{l} = "ine-pro";
	$lbl = "__content";
      } else {
	$lbl = $i;
      }
    }
    if ($lbl eq "t" || $lbl eq "gloss") {
      $lbl = "sense";
    } elsif ($lbl eq "pos") {
      $lbl = "ms";
    } elsif ($lbl eq "alt") {
      $lbl = "pparts";
    } elsif ($lbl eq "id") {
      if (defined($tpl{sense})) {
	$lbl = "sense_id";
      } else {
	$lbl = "sense";
      }
    } elsif ($lbl eq "lit") {
      if (defined($tpl{sense})) {
	$lbl = "sense_lit";
      } else {
	$lbl = "sense";
      }
    } elsif ($lbl =~ /^g\d*$/) {
      $v ="$lbl:$v";
      $lbl = "ms";
    }
    $tpl{$lbl} .= "; " if defined($tpl{$lbl});
    $tpl{$lbl} = $v;
  }
  $tpl{type} = "cognate" if $tpl =~ /^cog(?:nate)?$/;
  $tpl{type} = "borrowing" if $tpl =~ /^bor(?:rowing)?$/;
  $tpl{type} = "inherited" if $tpl =~ /^inh(?:erited)?$/;
  $tpl{type} = "suffix" if $tpl =~ /^suffix$/;
  $tpl{type} = "prefix" if $tpl =~ /^prefix$/;
  $tpl{type} = "PIE root" if $tpl =~ /^PIE root$/;
  $tpl{type} = "derived" if $tpl =~ /^der(?:ived)?$/;
  $tpl{type} = "abbreviation" if $tpl =~ /^abbreviation of$/;
  $tpl{type} = "doublet" if $tpl =~ /^(?:etymtwin|doublet)$/;
  $tpl{type} = "altform" if $tpl =~ /^(?:alternative form of)$/;
  if (defined($tpl{pparts}) && !defined($tpl{__content})) {
    $tpl{__content} = $tpl{pparts};
    delete($tpl{pparts});
  }
  delete($tpl{sort}) if defined($tpl{sort});
  if (defined($tpl{lang})) {
    $tpl{lang} =~ /^(.)/ || die;
    if ($1 eq lc($1)) {
      $tpl{l} = $tpl{lang};
      $lang = wikicode2abbr($tpl{l},1);
      if ($lang ne "") {
	$tpl{lang} = $lang;
      } else {
	delete($tpl{lang});
      }
    } else {
      $l = name2wikicode(abbr2name($tpl{lang},1),1) || name2wikicode($tpl{lang},1);
      if ($l eq "") {
	print STDERR "!".$tpl{lang}."\t$orig\n";
	$tpl{l} = "??";
      } else {
	$tpl{l} = $l;
      }
    }
  }
  if (defined($tpl{trglang})) {
    $tpl{trgl} = $tpl{trglang};
    $lang = wikicode2abbr($tpl{trgl},1);
    if ($lang ne "") {
      $tpl{trglang} = $lang;
    } else {
      delete($tpl{trglang});
    }
  }
  if ($tpl eq "etyl") {
    $s .= "<lang";
  } else {
    $s = "<form";
  }
  for ("lang", "l", "ms", "sense") {
    $s .= " $_=\"$tpl{$_}\"" if defined($tpl{$_});
  }
  for (sort keys %tpl) {
    next if /^(l(?:ang)?|ms|sense|type|__.*)$/;
    $s .= " $_=\"$tpl{$_}\"" if defined($tpl{$_});
  }
  $s .= " type=\"$tpl{type}\"" if defined($tpl{type});
  if (defined($tpl{__content})) {
    $s .= ">".$tpl{__content}."</form>";
  } else {
    $s .= "/>";
  }
  return $s;
}

sub reorder_template_args {
  my $s = shift;
  my @a = split /\|/, $s;
  my $r;
  for (@a) {
    if ($_ !~ /^[^ ]+=/) {
      $r .= "|" if $r ne "";
      $r .= $_
    }
  }
  for (@a) {
    if ($_ =~ /^[^ ]+=/) {
      $r .= "|" if $r ne "";
      $r .= $_
    }
  }
  return $r;
}
