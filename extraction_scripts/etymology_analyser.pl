#!/usr/bin/perl

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use utf8;
use LanguageNameConverter;
use ScriptManager;
use strict;
use Text::Levenshtein qw(distance);

my $formre = qr/<form[^<>]*>[^<>]*<\/form>/;
my $langre = qr/<lang[^<>]*\/>/;
my (%forms, %formid2form);
my (%compoundings, %compoundingid2compound);
my %formid2compoundings;
my (%rels, %invrels);
my $maxformid;
my $maxcompoundingid;

my $bool = 0;
my ($cur_lang, $cur_lang_abbrev, $cur_lang_wikicode);
my $headerform;
my ($etymology, %relations);
my $total_merging_nb;
my $total_c_merging_nb;
my $line;
while (<>) {
  chomp;
  $line++;
  s/  +/ /g;
  if (/^\s*<entry id=".*?#(.*)">\s*$/) {
    $cur_lang = $1;
    $cur_lang_abbrev = name2abbr($cur_lang) || $cur_lang;
    $cur_lang_wikicode = name2wikicode($cur_lang) || "??";
#    print STDERR "Current language: $cur_lang\n";
  } elsif (/^\s*<etymology>\s*$/) {
    $bool = 1;
  } elsif (/^\s*<\/etymology>\s*$/) {
    if ($etymology ne "") {
      clean_etymology($etymology);
    }
    $etymology = "";
    $bool = 0;
  } elsif ($bool) {
    $etymology .= "\n" unless $etymology eq "";
    $etymology .= $_;
  } else {
    if (/^\s*<header[^>]*>(.+)<\/header>/) {
      $headerform = $1;
#      print STDERR "Header form: $headerform\n";
      if ($headerform =~ / l="en"/ && $headerform !~ / sense="/) {
    $headerform =~ s/^(<form(?: (?:l(?:ang)?|ms)="[^"<>]*")*)([^<>]*)>([^<>]+)/$1 sense="$3"$2>$3/;
    form2formid(simplify_form($headerform),1);
      }
    }
#    print "$_\n";
  }
}

print STDERR "  Forms before merging: $maxformid =".(scalar keys %formid2form)."\n";
print STDERR "  Compounds before merging: $maxcompoundingid\n";
my $relsnb = 0;
for my $to (keys %rels) {
  for my $from (keys %{$rels{$to}}) {
    $relsnb++ for keys %{$rels{$to}{$from}};
  }
}
print STDERR "  Relations before merging: $relsnb\n";
merge_formids();

print STDERR "  Merged forms: $total_merging_nb\n";
print STDERR "  Merged compound ids: $total_c_merging_nb\n";

print STDERR "  Forms after merging: ".(scalar keys %formid2form)." = ".($maxformid-$total_merging_nb)."\n";
$relsnb = 0;
for my $to (keys %rels) {
  for my $from (keys %{$rels{$to}}) {
    $relsnb++ for keys %{$rels{$to}{$from}};
  }
}
print STDERR "  Relations after merging: $relsnb\n";

clean_relations();

correct_relation_types();

$relsnb = 0;
for my $to (keys %rels) {
  for my $from (keys %{$rels{$to}}) {
    $relsnb++ for keys %{$rels{$to}{$from}};
  }
}
print STDERR "  Relations after cleaning: $relsnb\n";

for my $formid (sort keys %formid2form) {
  print "$formid\t".$formid2form{$formid}{lang}."\t".($formid2form{$formid}{is_reconstructed} ? "1" : "0")."\t".$formid2form{$formid}{form}."\t".$formid2form{$formid}{sense}."\n" unless $formid2form{$formid}{form} eq "-";
}
for my $compoundid (sort {($b-1) <=> ($a-1)} keys %compoundingid2compound) {
  print $compoundid;
  for (0..$#{$compoundingid2compound{$compoundid}}) {
    print "\t".$compoundingid2compound{$compoundid}[$_];
  }
  print "\n";
}
for my $to (keys %rels) {
  for my $from (keys %{$rels{$to}}) {
    for my $rel (keys %{$rels{$to}{$from}}) {
      print "$rel\t$to\t$from\n";
    }
  }
}



sub clean_etymology {
  my $s = shift;
  my $d;
  
  #debug
  $s =~ s/<form 2="drumslade" 4="drummer" nocap="1" nodot="1">en<\/form>/<form l="en" sense="drummer" nocap="1" nodot="1">drumslade<\/form>/;
  $s =~ s/<form 2="abagerie" nodot="1">ro<\/form>/<form l="ro" nodot="1">abagerie<\/form>/;
  $s =~ s/<form 2="σκᾰ́τᾰ">el<\/form>/<form l="el">σκᾰ́τᾰ<\/form>/;

  $s =~ s/<form lang="[^"]+" l="[^"]+" type="doublet"\/>/Doublet of/g;
  
  $s =~ s/(<form[^\n<>]+type="PIE root">[^\n<>]*<\/form>)/\n$1\n/gs;
  $s =~ s/\.The /. The/gs;
  $s =~ s/~/\\~/gs;
  
  if ($s =~ s/(?<!Old )\b($langnameRE) <form lang="([^\n<>"]+)" l=/"<form lang=\"".name2abbr($1)."\" l=\"".name2wikicode($1)."\" olang=\"$2\" ol="/ge) {
    $s =~ s/ lang="([^\n<>"]+)" l="([^\n<>"]+)" olang="$1" ol="$2"/ lang="$1" l="$2"/gs;
  }
  if ($s =~ s/(?<!Old )\b($langnameRE) <form l=/"<form lang=\"".name2abbr($1)."\" l=\"".name2wikicode($1)."\" ol="/ge) {
    $s =~ s/ lang="([^\n<>"]+)" l="([^\n<>"]+)" ol="$2"/ lang="$1" l="$2"/gs;
  }

  if ($s =~ s/<descendants>\n?(.+?)<\/descendants>\n?//s) {
    $d = $1;
    $d =~ s/ *\n+ */\n/gs;
    $d =~ s/ *\n$//s;
    $d =~ s/^ +//s;
    for (split /\n/, $d) {
      add_relation(simplify_form($_),simplify_form($headerform),"inh") unless /<form[^<>]+\/>/;
    }
  }

  # distribute forms for multiple languages (ex: Sp. and Cat. xxx)
  $s =~ s/<lang (lang="[^\n<>"]+" l="[^\n<>"]+")[^\/<>]+\/>, <lang (lang="[^\n<>"]+" l="[^\n<>"]+")[^\/<>]+\/>, <lang (lang="[^\n<>"]+" l="[^\n<>"]+")[^\/<>]+\/>(?: and|,) <form (lang="[^"<>]*" l="[^"<>]*")([^\/<>]*>[^\n<>]+<\/form)>/<form $1$5 inferred="1">, <form $2$5 inferred="1">, <form $3$5 inferred="1">, <form $4$5>/gs;
  $s =~ s/<lang (lang="[^\n<>"]+" l="[^\n<>"]+")[^\/<>]+\/>, <lang (lang="[^\n<>"]+" l="[^\n<>"]+")[^\/<>]+\/>(?: and|,) <form (lang="[^"<>]*" l="[^"<>]*")([^\/<>]*>[^\n<>]+<\/form)>/<form $1$4 inferred="1">, <form $2$4 inferred="1">, <form $3$4>/gs;
  $s =~ s/<lang (lang="[^\n<>"]+" l="[^\n<>"]+")[^\/<>]+\/>(?: and|,) <form (lang="[^"<>]*" l="[^"<>]*")([^\/<>]*>[^\n<>]+<\/form)>/<form $1$3 inferred="1">, <form $2$3>/gs;

  $s =~ s/<lang([^<>\/]+)\/> \{\{[^{}\|]+\|[^{}\|]+\}\} \'\'([^'{}]+)\'\'/<form $1>$2<\/form>/g;
  $s =~ s/<form([^<>\/]+)>([^<>{}]+)<\/form> \{\{[^{}\|]+\|[^{}\|]+\}\} ‘([^’{}\|]+)’/<form$1 sense="$3">$2<\/form>/g;
  $s =~ s/<lang([^<>\/]+)\/> \{\{[^{}\|]+\|[^{}\|]+\}\} \{\{term\|\|([^{}\|]+)\}\}/<form $1>$2<\/form>/g;
  $s =~ s/<lang([^<>\/]+)\/> \'\'([^'{}]+)\'\' \{\{[^{}\|]+\|[^{}\|]+\}\}/<form $1>$2<\/form>/g;
  #
  # Avestan ''kahrkatat'' 'rooster' {{rfscript|ae}}
  #
  # <form lang="Av." l="ae" sense="covenant, contract, oath"/> {{rfscript|ae}}

  while ($s =~ s/<form([^\n<>\/]*)>([^\n<>]+)<\/form>, <form\1>([^\n<>]+)<\/form>/<form$1>$2 ~ $3<\/form>/g) {}
  $s =~ s/<form([^\n<>\/]*)>([^\n<>]+)<\/form>, <form\1([^\n<>\/]*)>([^\n<>]+)<\/form>/<form$1$3>$2 ~ $4<\/form>/gs;
  while ($s =~ s/(<form[^\n<>\/]*>[^\n<>]+), ([^\n<>]+<\/form>)/$1 ~ $2/gs) {}

  $s =~ s/ +\+ +<\/form> +<form/<\/form> + <form/g;
  $s =~ s/<\/form> +(<form[^<>\n\/]+>) +\+ /<\/form> + $1/g;
  
  $s =~ s/(<form[^<>\/\n]*) sense="[^<>"\n]*"([^<>\/\n]*>[^<>\n]* \+ )/$1$2/gs;
  while ($s =~ s/(<form[^<>\/\n]*>)([^<>\+\n]+) \+ /$1$2<\/form> + $1/gs) {}
  $s =~ s/ \+ (<form[^<>\/\n]*suffix="[^<>\n"]+"[^<>\n]*>)([^-])/ + $1-$2/g;
  $s =~ s/(<form[^<>\/\n]*prefix="[^<>\n"]+"[^<>\n]*>[^<>\n]*[^-])<\/form> \+ /$1-<\/form>/g;
  $s =~ s/ \+ -(<form[^<>\/\n]*>)-?/ + $1-/g;

  my ($src, $trg, $sense);
  $s =~ s/§/__PARA__/gs;
  $s =~ s/#/__HASH__/gs;
  $s =~ s/(^|\n)Ultimately from /$1From /gs;
  $s =~ s/(^|\n)From (?:the )?/$1# $headerform, from /gs;
  $s =~ s/(^|\n)($formre), from/$1## $headerform, from $2, from/gs;
  $s = "§".$s; #marker
  while ($s =~ s/§(.*?)(?<!\+ )($formre(?: \+ $formre)*)(?:(?:, (?:ultimately )?|\. Ultimately )from| &lt;) ($formre(?: \+ $formre)*)([\.,]| \(|$)/$1$2, from §$3$4/s) {
    $trg = $2;
    $src = $3;
    if ($src !~ / sense="/ && $src !~ / \+ / && $trg =~ / (sense="[^"<>]+")/) {
      $sense = $1;
      $src =~ s/^(<form(?: (?:l(?:ang)?|ms)="[^"<>]*")*)([^<>]*)>([^<>]+)/$1 $sense inferredsense="1"$2>$3/;
      $s =~ s/^(.*)§($formre)/$1§$src/s;
    }
    if ($src =~ /type="suffix"/) {
      if ($src =~ / \+ /) {
    add_relation(simplify_form($trg),simplify_form($src),"der(s)");
      } else {
    print STDERR "WARNING[line $line] (incomplete suffix relation): $src\n";
      }
    } elsif ($src =~ /type="prefix"/) {
      if ($src =~ / \+ /) {
    add_relation(simplify_form($trg),simplify_form($src),"der(p)");
      } else {
    print STDERR "WARNING[line $line] (incomplete prefix relation): $src\n";
      }
    } elsif ($src =~ /type="compound"/) {
      die unless $src =~ / \+ /;
      add_relation(simplify_form($trg),simplify_form($src),"cmpd");
    } elsif ($src =~ /type="borrowing"/) {
      add_relation(simplify_form($trg),simplify_form($src),"bor");
    } elsif ($src =~ /type="altform"/) {
      add_relation(simplify_form($trg),simplify_form($src),"altform");
    } else {
      add_relation(simplify_form($trg),simplify_form($src),"inh");
    }
  }
  $s =~ s/§//;

  $s = "§".$s; #marker
  while ($s =~ s/§(.*?)(?<!\+ )($formre), ((?:singular|plural|dual) ?(?:present|past|perfect) ?(?:active|passive) ?(?:infinitive|participle) of) ($formre)([\.,]| \(|$)/$1$2, $3 §$4$5/s) {
    $trg = $2;
    $src = $3;
    add_relation(simplify_form($trg),simplify_form($src),"infl");
  }
  $s =~ s/§//;

  my $s_tmp = $s;
  while ($s_tmp =~ s/(^|\n|\. )(?:Cognate with|Cognates include|Related to|Compare) ($formre)(, |\.| and |$)/$1Cognate with /s) {
    add_relation(simplify_form($headerform),simplify_form($2),"cog");
  }
  $s_tmp = $s;
  while ($s_tmp =~ s/(?: \(|; )compare ($formre)(, |\.| and |$)/ \(compare /s) {
    add_relation(simplify_form($headerform),simplify_form($1),"cog");
  }
  $s_tmp = $s;
  while ($s_tmp =~ s/, whence also ($formre)(, |\.| and |$)/, whence also /s) {
    add_relation(simplify_form($headerform),simplify_form($1),"cog");
  }
  $s =~ s/(^|\n)# $formre, from /$1From /gs;
  $s =~ s/(^|\n)## $formre, from /$1/gs;
  if ($s =~ /^Borrowed (?:\(in this form\) )?from ($formre)/) {
    add_relation(simplify_form($headerform),simplify_form($1),"bor");
  }

  while ($s =~ /($formre)/g) {
    form2formid(simplify_form($1),1);
  }

  $s =~ s/\n+/\n/gs;
  $s =~ s/^\n//;
  $s =~ s/\n$//;
  return $s;
}

sub simplify_form {
  my $f = shift;
  my ($sf, $lang, $nword);
#  print STDERR "SF $f\n";
  for (split /(?<=>) \+ (?=<)/, $f) {
    s/^(<form)//;
    $sf .= " + " unless $sf eq "";
    $sf .= "<form";
    $lang = "";
    while (s/ +([^<>=]+)="([^<>"]*)"//) {
      my $a = $1;
      my $v = $2;
      next if $v eq "";
      next unless $a =~ /^(l|ms|sense)$/;
      $sf .= " $a=\"$v\"";
      $lang = $v if $a eq "l";
    }
    die $_ unless /^ *>([^<>]+)<\/form>$/;
    $nword = translitterate(normalize($1,$lang,1),$lang);
    $sf .= " orig=\"$1\"" if $1 ne $nword;
    $sf .= ">$nword</form>";
  }
#  print STDERR "$sf\n";
  return $sf;
}

sub add_relation {
  my $to = shift;
  my $from = shift;
  my $rel = shift;
  die if $to < 0;
  #  print STDERR "add_relation($to,$from,$rel)\n";
  return if $from =~ />-<\/form>/;
  return if $to =~ />-<\/form>/;
  $to = form2formid($to);
  if ($from =~ / \+ /) {
    return if $to == 0;
    unless (defined($compoundings{$from})) {
      $maxcompoundingid++;
      for my $cc (split / \+ /, $from) {
    $cc = form2formid($cc);
    return if $cc == 0;
    $compoundings{$from} = -$maxcompoundingid;
    push @{$compoundingid2compound{-$maxcompoundingid}}, $cc;
    $formid2compoundings{$cc}{-$maxcompoundingid} = 1;
      }
    }
    $rels{$to}{$compoundings{$from}}{$rel}++;
    $invrels{$compoundings{$from}}{$to}{$rel}++;
  } else {
    $from = form2formid($from);
    return if $to == 0 || $from == 0;
    $rels{$to}{$from}{$rel}++;
    $invrels{$from}{$to}{$rel}++;
  }
}

sub form2formid {
  my $form = shift;
  my $robust = shift || 0;
  my $orig_form = $form;
  if ($robust) {
    next unless $form =~ /^<form.*>[^<>]+<\/form>/;
    next unless $form =~ / l="[^"]+"/
  }
  $form =~ s/^<form(.*)>([^<>]+)<\/form>/\1/ || return 0;
  my $word = $2;
  $word =~ s/Reconstruction.*?\/(.)/\1/;
  my $is_reconstructed = 0;
  if ($word =~ s/^\*//) {
    $is_reconstructed = 0;
    $word =~ s/([,~] )\*/\1/g;
  }
  $form =~ / l="([^"]+)"/ || die "$orig_form";
  my $formlang = $1;
  my $formsense;
  if ($form =~ / sense="([^"]+)"/) {
    $formsense = $1;
    $formsense =~ s/(&quot;, also &quot;|”, “|&quot;, ''also'', &quot;)/; /g;
    $formsense =~ s/&quot;, literally &quot;/; (lit.) /g;
    while ($formsense =~ s/(^|;)(?:to|I) ([^;]*?), ([^tI]|t[^o]|I[^ ])/$1to $2, to $3/g) {}
    $formsense =~ s/^(?:a|the) //; 
  }
  if (defined($forms{$formlang})
      && defined($forms{$formlang}{$word})
      && defined($forms{$formlang}{$word}{$formsense})
     ) {
    return $forms{$formlang}{$word}{$formsense};
  } else {
    $maxformid++;
    $forms{$formlang}{$word}{$formsense} = $maxformid;
    $formid2form{$maxformid}{lang} = $formlang;
    $formid2form{$maxformid}{form} = $word;
    $formid2form{$maxformid}{sense} = $formsense;
    $formid2form{$maxformid}{is_reconstructed} = $is_reconstructed;
    return $maxformid;
  }
}

sub merge_formids {
  my $replacedforms = 1;
  my $replacedcompounds;
  my $previous_word;
  my %replace;
  my $n;
  while ($replacedforms || $replacedcompounds) {
    $replacedforms = 0;
    for my $lang (sort keys %forms) {
      $previous_word = "_°_previous_word_lalalala_°_";
      for my $word (sort keys %{$forms{$lang}}) {
        unless (scalar keys %{$forms{$lang}{$word}} > 1 || distance($word, $previous_word, {ignore_diacritics => 1}) == 0) {
          $previous_word = $word;
          next;
        }
        # if a word has only two gloses, one of which empty, we merge them
        if (defined($forms{$lang}{$word}{""}) && scalar keys %{$forms{$lang}{$word}} == 2) {
          my $formid_tobereplaced = $forms{$lang}{$word}{""};
          for (sort keys %{$forms{$lang}{$word}}) {
            next if $_ eq "";
            $replace{$formid_tobereplaced} = $forms{$lang}{$word}{$_};
            $formid2form{$replace{$formid_tobereplaced}}{is_reconstructed} ||= $formid2form{$formid_tobereplaced}{is_reconstructed};
            delete($forms{$lang}{$word}{""});
            delete($formid2form{$formid_tobereplaced});
            $replacedforms++;
          }
        } elsif (scalar keys %{$forms{$lang}{$word}} > 2) {
          loop: for my $s1 (sort keys %{$forms{$lang}{$word}}) {
            next if $s1 eq ""; 
            for my $s2 (sort keys %{$forms{$lang}{$word}}) {
              next if $s2 eq "";
              next unless $forms{$lang}{$word}{$s1} < $forms{$lang}{$word}{$s2}; # id of 1 is < to id of 2, in order to manage relations once
              my (%s1, %s2);
              # We store the different versions of the glosses, associated with different ids
              $s1{$_} = 1 for split / *[,;] +/, $s1;
              $s2{$_} = 1 for split / *[,;] +/, $s2;
              for (sort keys %s1) {
                if (defined($s2{$_})) {  # If the glosses are similar, we merge the two ids and keep the lowest
                  $replace{$forms{$lang}{$word}{$s2}} = $forms{$lang}{$word}{$s1};
                  my %s;
                  $s{$_} = 1 for (keys %s1, keys %s2);
                  my $targetformid = $forms{$lang}{$word}{$s1};
                  $formid2form{$targetformid}{is_reconstructed} ||= $formid2form{$forms{$lang}{$word}{$s2}}{is_reconstructed};
                  delete($formid2form{$forms{$lang}{$word}{$s2}});
                  delete($forms{$lang}{$word}{$s1});
                  delete($forms{$lang}{$word}{$s2});
                  $forms{$lang}{$word}{join(", ", sort keys %s)} = $targetformid;
                  $replacedforms++;
                  last loop;
                }
              }
            }
          }
        }

	die "ERROR: there seems to be 2 distinct yet identical instances of word '$word' in language $lang" if $word eq $previous_word;
	
        if (distance($word, $previous_word, {ignore_diacritics => 1}) == 0){
          loop: for my $s1 (sort keys %{$forms{$lang}{$word}}) {
            next if $s1 eq ""; 
            for my $s2 (sort keys %{$forms{$lang}{$previous_word}}) {
              next if $s2 eq "";
              my (%s1, %s2);
              # We store the different versions of the glosses, associated with different ids
              $s1{$_} = 1 for split / *[,;] +/, $s1;
              $s2{$_} = 1 for split / *[,;] +/, $s2;
              for (sort keys %s1) {
                if (defined($s2{$_})) {  # If the glosses are similar
                  $replace{$forms{$lang}{$previous_word}{$s2}} = $forms{$lang}{$word}{$s1};
                  my %s;
                  $s{$_} = 1 for (keys %s1, keys %s2);
                  my $targetformid = $forms{$lang}{$word}{$s1};
                  print STDERR "\n MY replace: $word ($lang), $previous_word";
                  print STDERR "\n$formid2form{$forms{$lang}{$word}{$s1}}{\"form\"} $formid2form{$forms{$lang}{$word}{$s1}}{\"sense\"} $forms{$lang}{$word}{$s1}";
                  print STDERR "\n$formid2form{$forms{$lang}{$previous_word}{$s2}}{\"form\"} $formid2form{$forms{$lang}{$previous_word}{$s2}}{\"sense\"} $forms{$lang}{$previous_word}{$s2}\n";
                  $formid2form{$targetformid}{is_reconstructed} ||= $formid2form{$forms{$lang}{$previous_word}{$s2}}{is_reconstructed};

                  # We assign the meaning and value to the previous word
                  delete($forms{$lang}{$word}{$s1});  # Remove cur meaning from cur word
                  delete($forms{$lang}{$previous_word}{$s2});  # Remove previous meaning from previous word
                  delete($formid2form{$forms{$lang}{$previous_word}{$s2}});  # Remove the link between prev meaning_id and prev word (since it'll be deleted)
                  if (scalar keys %{$forms{$lang}{$previous_word}} == 0) {  # If the word has no other gloses
                    print STDERR "DELETED $previous_word, $lang\n\n";
                    delete($forms{$lang}{$previous_word});
                  }
                  $forms{$lang}{$word}{join(", ", sort keys %s)} = $targetformid;  # Add cur and previous meanings to cur word (since alphabetical order, we keep the accented word)
                  $replacedforms++;
                  last loop;
                }
              }
            }
          }
        }
        $previous_word = $word;
      }
    }
    $total_merging_nb += $replacedforms;
    if ($replacedforms > 0 || $replacedcompounds > 0) {
      $n = 0;
      for my $tobereplaced (sort keys %replace) {
        $n++;
        print STDERR "$n/$replacedforms ($tobereplaced -> $replace{$tobereplaced})\r";
        if ($tobereplaced > 0) {
          if (defined($formid2compoundings{$tobereplaced})) {
            for my $c (sort keys %{$formid2compoundings{$tobereplaced}}) {
              $formid2compoundings{$replace{$tobereplaced}}{$c} = 1;
              delete ($formid2compoundings{$tobereplaced}{$c});
              for (0..$#{$compoundingid2compound{$c}}) {
                if ($compoundingid2compound{$c}[$_] == $tobereplaced) {
                  $compoundingid2compound{$c}[$_] = $replace{$tobereplaced};
                }
              }
            }
            delete($formid2compoundings{$tobereplaced});
          }
        } else {
          $compoundingid2compound{$tobereplaced} = undef;
          delete($compoundingid2compound{$tobereplaced});
        }
        if (defined($invrels{$tobereplaced})) {
          for my $l2 (sort keys %{$invrels{$tobereplaced}}) {
            die if $l2 < 0;
            die "\$rels{$l2}{$tobereplaced} not defined" unless defined($rels{$l2}{$tobereplaced});
            for (sort keys %{$rels{$l2}{$tobereplaced}}) {
              $rels{$l2}{$replace{$tobereplaced}}{$_} = $rels{$l2}{$tobereplaced}{$_};
              $invrels{$replace{$tobereplaced}}{$l2}{$_} = $invrels{$tobereplaced}{$l2}{$_};
              delete($rels{$l2}{$tobereplaced}{$_});
              delete($invrels{$tobereplaced}{$l2}{$_});
            }
            delete($rels{$l2}{$tobereplaced});
            delete($invrels{$tobereplaced}{$l2});
          }
          delete($invrels{$tobereplaced});
        }
        if (defined($rels{$tobereplaced})) {
          die if $replace{$tobereplaced} < 0;
          for my $l2 (sort keys %{$rels{$tobereplaced}}) {
            for (sort keys %{$rels{$tobereplaced}{$l2}}) {
              $rels{$replace{$tobereplaced}}{$l2}{$_} = $rels{$tobereplaced}{$l2}{$_};
              $invrels{$l2}{$replace{$tobereplaced}}{$_} = $invrels{$l2}{$tobereplaced}{$_};
              delete($rels{$tobereplaced}{$l2}{$_});
              delete($invrels{$l2}{$tobereplaced}{$_});
            }
            delete($rels{$tobereplaced}{$l2});
            delete($invrels{$l2}{$tobereplaced});
          }
          delete($rels{$tobereplaced});
        }
      }
    }
    $replacedcompounds = 0;
    %replace = ();
    my %tmp = ();
    my $m = 0;
    for my $c (sort keys %compoundingid2compound) {
      my $seq = join(" + ", @{$compoundingid2compound{$c}});
      if (defined($tmp{$seq})) {
        $replace{$c} = $tmp{$seq};
        $total_c_merging_nb++;
        $replacedcompounds++;
        print STDERR "\t\t\t\t\t$replacedcompounds ($c -> $tmp{$seq})\r";
      } else {
        $tmp{$seq} = $c;
      }
    }
    print STDERR "\n";
  }
}

sub clean_relations {
  my $cleaned_relations_nb;
  for my $f1 (keys %rels) {
    for my $f2 (keys %{$rels{$f1}}) {
      for my $r12 (keys %{$rels{$f1}{$f2}}) {
    next if $r12 eq "cog";
    next unless defined($rels{$f2});
    for my $f3 (keys %{$rels{$f2}}) {
      for my $r23 (keys %{$rels{$f2}{$f3}}) {
        next if $r23 eq "cog";
        if (defined($rels{$f1}{$f3})) {
          for my $r13 (keys %{$rels{$f1}{$f3}}) {
        next if $r13 eq "cog";
        $cleaned_relations_nb++;
        delete($rels{$f1}{$f3}{$r13});
        delete($invrels{$f3}{$f1}{$r13});
          }
          delete($rels{$f1}{$f3}) if scalar keys %{$rels{$f1}{$f3}} == 0;
          delete($invrels{$f3}{$f1}) if scalar keys %{$invrels{$f3}{$f1}} == 0;
        }
      }
    }
      }
    }
  }
  print STDERR "  Relations deleted by cleaning: $cleaned_relations_nb\n";
}

sub correct_relation_types {
  my $cleaned_relations_nb;
  for my $f1 (keys %rels) {
    die $f1 if $f1 < 0;
    my $l1 = $formid2form{$f1}{lang};
    for my $f2 (keys %{$rels{$f1}}) {
      my $l2;
      if ($f2 > 0) {
    $l2 = $formid2form{$f2}{lang};
      } else {
    my $l2;
    for (0..$#{$compoundingid2compound{$f2}}) {
      if ($l2 eq "" || $l2 eq $formid2form{$compoundingid2compound{$f2}[$_]}{lang}) {
        $l2 = $formid2form{$compoundingid2compound{$f2}[$_]}{lang};
      } else {
        $l2 = "";
        last;
      }
    }
      }
#      print "S\t".(scalar keys %{$rels{$f1}{$f2}})."\t".(join " ", sort keys %{$rels{$f1}{$f2}})."\t$l1\t$l2\n";
      if (scalar keys %{$rels{$f1}{$f2}} == 1) {
    for my $r12 (keys %{$rels{$f1}{$f2}}) {
      if ($l1 eq $l2 && $r12 eq "inh" && $f2 > 0) {
        $rels{$f1}{$f2}{der} = $rels{$f1}{$f2}{$r12};
        $invrels{$f2}{$f1}{der} = $invrels{$f2}{$f1}{$r12};
        delete($rels{$f1}{$f2}{$r12});
        delete($invrels{$f2}{$f1}{$r12});
      } elsif ($l1 eq $l2 && ($r12 eq "inh" || $r12 eq "der") && $f2 < 0) {
        if ($formid2form{$compoundingid2compound{$f2}[$#{$compoundingid2compound{$f2}}]}{word} =~ /^-/) {
          $rels{$f1}{$f2}{"der(s)"} = $rels{$f1}{$f2}{$r12};
          $invrels{$f2}{$f1}{"der(s)"} = $invrels{$f2}{$f1}{$r12};
        } elsif ($formid2form{$compoundingid2compound{$f2}[0]}{word} =~ /-$/) {
          $rels{$f1}{$f2}{"der(p)"} = $rels{$f1}{$f2}{$r12};
          $invrels{$f2}{$f1}{"der(p)"} = $invrels{$f2}{$f1}{$r12};
        } else {
          $rels{$f1}{$f2}{cmpd} = $rels{$f1}{$f2}{$r12};
          $invrels{$f2}{$f1}{cmpd} = $invrels{$f2}{$f1}{$r12};
        }
        delete($rels{$f1}{$f2}{$r12});
        delete($invrels{$f2}{$f1}{$r12});
      } elsif ($l2 eq "" && ($r12 eq "inh" || $r12 eq "der") && $f2 < 0) {
        $rels{$f1}{$f2}{"cmpd+bor"} = $rels{$f1}{$f2}{$r12};
        $invrels{$f2}{$f1}{"cmpd+bor"} = $invrels{$f2}{$f1}{$r12};
        delete($rels{$f1}{$f2}{$r12});
        delete($invrels{$f2}{$f1}{$r12});
      }
    }
      }
    }
  }
}
