package Phonetiser;

use strict;
use utf8;
use Exporter;
use Translitterate;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $REFC);

use Unicode::Normalize;

$VERSION     = '0.01';
@ISA         = qw(Exporter);
@EXPORT      = qw(&phonetize &simplify);


sub phonetize {
  my $s = shift;
  my $lang = shift;
  my $orig_s = $s;

  $s =~ s/ʮ/z̩ʷ/g;

  $s =~ s/u̯/w/g;
  $s =~ s/i̯/j/g;

  if ($lang =~ /^oe\.?$/i) {
    $s =~ s/ċ/č/g;
    $s =~ s/ġ/dž/g;
  }
  if ($lang =~ /^lat/i) {
    $s =~ s/ch?/k/g;
    $s =~ s/qu/kʷ/g;
    $s =~ s/v/w/g;
    $s =~ s/x/ks/g;
    die if $s =~ /q/;
  }
  if ($lang =~ /^bret/i) {
    $s =~ s/c['’]h/x/g;
    $s =~ s/dd/ð/g;
    $s =~ s/zh/z/g;
    $s =~ s/ch/š/g;
    $s =~ s/gn/ň/g;
    $s =~ s/y/j/g;
    $s =~ s/lh/ľ/g;
    $s =~ s/g(?:w|gou)(?=[aeiou])/gʷ/g;
    $s =~ s/kw/kʷ/g;
  }

  if ($lang =~ /Sami/) {
    $s =~ s/đ/ð/g;
  }
  
  if ($lang eq "G." || $lang =~ /^o?fris/i) {
    $s =~ s/sch/š/g;
    $s =~ s/cht/xt/g;
    $s =~ s/ch/ç/g;
    $s =~ s/ck/k/g;
    $s =~ s/ß/ss/g;
  }
  if ($lang =~ /^gaul/i) {
    $s =~ s/đ/ð/g;
  }
  if ($lang =~ /^(o?prus|[mo][hl]g|m?du|o?sw|on|nw|o?fris|oschw|[om]?dan)/i) {
    $s =~ s/ck/k/g;
  }
  $s =~ s/ᵛ/ʷ/g;
  $s =~ s/ᵉ/e/g;


  if ($lang =~ /^[mo]?w(?:elsh)?\.?$/i) {
    $s =~ s/ch/x/g;
    $s =~ s/dd/ð/g;
    $s =~ s/ff/f/g;
    $s =~ s/ng/ŋ/g;
    $s =~ s/ll/ľ/g;
    $s =~ s/ph/f/g;
    $s =~ s/rh/r/g;
    $s =~ s/th/þ/g;
    $s =~ s/u/ɪ/g;
    $s =~ s/y/ɪ/g;
    $s =~ s/f/v/g;
    $s =~ s/j/dž/g;
    $s =~ s/c/k/g;
    $s =~ s/’//g;
  }
  if ($lang =~ /^manx/i) {
    $s =~ s/y/ɪ/g;
    $s =~ s/t?çh/č/g;
    $s =~ s/d[dh]/d/g;
    $s =~ s/gg/g/g;
    $s =~ s/ght$/x/g;
    $s =~ s/gh/x/g;
    $s =~ s/d?j/dž/g;
    $s =~ s/l[lh]/l/g;
    $s =~ s/el$/əl/g;
    $s =~ s/mm/m/g;
    $s =~ s/ng/ŋ/g;
    $s =~ s/pp/p/g;
    $s =~ s/qu/kʷ/g;
    $s =~ s/rr/r/g;
    $s =~ s/^ss?n/šn/g;
    $s =~ s/ss/s/g;
    $s =~ s/sh/š/g;
    $s =~ s/st$/s/g;
    $s =~ s/t[th]/t/g;
  }
  if ($lang =~ /^oir/i) {
    $s =~ s/c/k/g;
  }
  if ($lang =~ /^ir(?:ish)?\.?$/i) {
    $s =~ s/nc/ŋk/g;
    $s =~ s/bhf?/w/g;
    $s =~ s/bp/b/g;
    $s =~ s/ch/x/g;
    $s =~ s/dh/ɣ/g;
    $s =~ s/dt/d/g;
    $s =~ s/fh//g;
    $s =~ s/gc/g/g;
    $s =~ s/mb/m/g;
    $s =~ s/mh/w/g;
    $s =~ s/n[nd]/n/g;
    $s =~ s/ng/ŋ/g;
    $s =~ s/ph/f/g;
    $s =~ s/rr/r/g;
    $s =~ s/sh/h/g;
    $s =~ s/th/h/g;
    $s =~ s/ts/t/g;
    $s =~ s/c/k/g;
    $s =~ s/v/w/g;
  }
  if ($lang =~ /^sc\.? ?gael/i) {
    $s =~ s/bh/v/g;
    $s =~ s/chd/xk/g;
    $s =~ s/cn/kr/g;
    $s =~ s/ch/x/g;
    $s =~ s/dh/ɣ/g;
    $s =~ s/fh//g;
    $s =~ s/gn/kr/g;
    $s =~ s/gh/ɣ/g;
    $s =~ s/g/k/g;
    $s =~ s/ll/ľ/g;
    $s =~ s/mh/v/g;
    $s =~ s/ng/ŋɡ/g;
    $s =~ s/nn/n/g;
    $s =~ s/ph/f/g;
    $s =~ s/rr/r/g;
    $s =~ s/[ts]h/h/g;
    $s =~ s/sr/str/g;
    $s =~ s/d/t/g;
    $s =~ s/b/p/g;
    $s =~ s/c/k/g;
  }
  if ($lang =~ /^to(?:ch)?\.? [ab]\.?$/i) {
    $s =~ s/c/tś/g;
    $s =~ s/ṣ/š/g;
    $s =~ s/ñ/ň/g;
    $s =~ s/ṅ/ŋ/g;
    $s =~ s/ly/ľ/g;
    $s =~ s/y/j/g;
    $s =~ s/ṃ/n/g;
  }
  if ($lang =~ /^(rv|skt)\.?$/i) {
    $s =~ s/([ṭcpgjḍdb])h/\1ʰ/g;
    $s =~ s/c/ç/g;
    $s =~ s/j/ď/g;
    $s =~ s/ñ/ň/g;
    $s =~ s/ṅ/ŋ/g;
    $s =~ s/v/β/g;
    $s =~ s/y/j/g;
  }
  if ($lang =~ /^[om]e\.?$/i) {
    $s =~ s/c/k/g;
  }
  
  if ($lang =~ /^(on|g|pie|rv|[ymo]av|com\. .*)\.?$/i) {
    unless ($lang =~ /^com\. sl/i) {
      $s =~ s/y/j/g;
    }
  }
  if ($lang =~ /^lyd\./i) {
    $s =~ s/ν/ŋ/g;
    $s =~ s/λ/ľ/g;
    $s =~ s/τ/c/g;
  }
  if ($lang =~ /^(?:pugric|puralic|aramaic|syriac)/i) {
    $s =~ s/[ϑθ]/þ/g;
    $s =~ s/δ/ð/g;
    $s =~ s/γ/ɣ/g;
  }
  if ($lang =~ /(^| )(bzyp|svan|georg(?:ian)?|p(?:roto-)?kartv(?:elian)?|abzhywa|abkhaz|abaza|mingr(?:elian)?|temirgoy|adyghe|p(?:roto-)?nostr(?:atic)?|p(?:roto-)?circass(?:ian)?)\.?([ \/]|$)/i) {
    $s =~ s/[’']/̣/g;
  }
  if ($lang =~/uzbek/) {
    $s =~ s/ọ/ɵ/g; # approximative?
    $s =~ s/ụ/ɵ/g; # approximative?
  }
  
  $s =~ s/°/ʷ/g;

  if ($lang =~ /^car\./i) {
    s/β/mb/g;
    s/δ/nd/g;
    s/τ/č/g;
    s/λ/ll/g;
    s/ḱ/kj/g;
    s/z/ts/g;
    s/ŋ/nk/g;
    s/γ/ng/g;
    s/ŕ/rj/g;
    s/ñ/nn/g;
  }
  
  if ($lang =~ /(^| )(?:mo?)?gr\./i || $lang =~ /^lin\.? ?b/i || $lang =~ /^illyrg\./i) {
    $s =~ s/ᾁ/hᾳ/g;
    $s =~ s/ᾅ/hᾴ/g;
    $s =~ s/ἁ/hα/g;
    $s =~ s/ἅ/hά/g;
    $s =~ s/ἃ/hὰ/g;
    $s =~ s/ᾃ/hᾲ/g;
    $s =~ s/ἓ/hὲ/g;
    $s =~ s/ἕ/hέ/g;
    $s =~ s/ἑ/hε/g;
    $s =~ s/ἡ/hη/g;
    $s =~ s/ᾓ/hὴ/g;
    $s =~ s/ᾗ/hῇ/g;
    $s =~ s/ἣ/hὴ/g;
    $s =~ s/ἧ/hῆ/g;
    $s =~ s/ἥ/hή/g;
    $s =~ s/ᾕ/hῄ/g;
    $s =~ s/ἷ/hῖ/g;
    $s =~ s/ἱ/hι/g;
    $s =~ s/ἳ/hὶ/g;
    $s =~ s/ἵ/hί/g;
    $s =~ s/ὁ/hο/g;
    $s =~ s/ὃ/hὸ/g;
    $s =~ s/ὅ/hό/g;
    $s =~ s/ὑ/hυ/g;
    $s =~ s/ὓ/hὺ/g;
    $s =~ s/ὕ/hύ/g;
    $s =~ s/ὗ/hῦ/g;
    $s =~ s/ὡ/hω/g;
    $s =~ s/ὣ/hὼ/g;
    $s =~ s/ὧ/hῶ/g;
    $s =~ s/ὥ/hώ/g;
    $s =~ s/ᾡ/hῳ/g;
    $s =~ s/ᾣ/hῲ/g;
    $s =~ s/ᾧ/hῷ/g;
    $s =~ s/ᾥ/hῴ/g;
    $s =~ s/^([αεηιουω])h/h\1/;
  }

  $s = Unicode::Normalize::NFC($s);

  if ($lang =~ /(^| )(?:mo?)?gr\./i || $lang =~ /^lin\.? ?b/i || $lang =~ /^car\./i || $lang =~ /^illyrg\./i) {
    $s =~ s/γ([γκχξ])/ŋ\1/g;
    $s =~ tr/αβγδεηικλμνοπρστυωϙϻάἀὰᾰᾱᾶᾳἂἄἆἇᾲᾴᾷᾀᾂᾄᾆᾇέἐὲἒἔϝήἠὴῆῃἢἤἦᾐᾑῂῄῇᾒᾔᾖίἰὶῐῑῖϊΐἲἴἶῒΐόὀὸὂὄῤῥύὐὺῠῡῦϋΰὒὔὖῢΰῧώὠὼῶῳὢὤὦᾠῲῴῷᾢᾤᾦϛςϐ/abgdeêiklmnoprstuôqṣaaaaaaaaaaaaaaaaaaaeeeeewêêêêêêêêêêêêêêêêiiiiiiiiiiiiiooooorruuuuuuuuuuuuuuôôôôôôôôôôôôôôôssb/;
    $s =~ s/ζ/zd/g;
    $s =~ s/ξ/ks/g;
    $s =~ s/ψ/ps/g;
    $s =~ s/θ/tʰ/g;
    $s =~ s/φ/pʰ/g;
    $s =~ s/χ/kʰ/g;
  }

  $s =~ s/ȝ/g/g;

  $s =~ s/[ǰǯ]/dž/g;
  $s =~ s/ʒ/ž/g;
  $s =~ s/ʒ́/dź/g; #?

  $s =~ s/h[ᵃ₄ª]/H/g;
  $s =~ s/h[₁₂₃123]{2,}/H/g;
  $s =~ s/h[₁₂₃]₋[₁₂₃]/H/g;

  $s =~ s/(h₁|ꜣ|´|ˀ)/ʔ/gi;
  $s =~ s/(h₂|ḫ)/x/gi;
  $s =~ s/h₃/H/gi;
  $s =~ s/\`/ʕ/g;

  if ($lang =~ /arm/i) {
    $s =~ s/[ʼ‘’ʿʻ]/ʰ/g;
    $s =~ s/cʰ/tsʰ/g;
    $s =~ s/hʰ/h/g;
  }
  if ($lang =~ /^(?:opers|[ck]hwar|sogd|.?av|pir)\.?$/i || $lang =~ /^OP\.?$/) {
    $s =~ s/ß/β/g; # Av oui, le reste = ?
    $s =~ s/f/φ/g; # Av oui, le reste = ?
    $s =~ s/[θϑ]/þ/g;
    $s =~ s/[đδ]/ð/g;
    $s =~ s/ń/ň/g; # Av oui, le reste = ?
    $s =~ s/γ/ɣ/g;
  }
  if ($lang =~ /^(?:(?:mo)?pers|oss)/i || $lang =~ /^OP\.?$/) {
    $s =~ s/(ğ|ǧ|γ)/ɣ/g;
  }
  if ($lang =~ /^lyc/i) {
    $s =~ s/ϑ/þ/g;
  }
  if ($lang =~ /^(?:psemitic)/i) {
    $s =~ s/’/ʔ/g;
    $s =~ s/‘/ʕ/g;
  }
  
#  if ($lang =~ /old egy/i) {
    $s =~ s/ḏ/ď/g;
    $s =~ s/ṯ/ť/g;
  #  }

  unless ($lang =~ /^[ge]\.?$/i || $lang =~ /^oe\.?$/i) {
    $s =~ s/[cс]/ts/g;
  }

  $s =~ s/ñ/ň/g;

  if ($lang =~ /^go(t|\.)/i) {
    $s =~ s/ß/β/g;
    $s =~ s/f/φ/g;
    $s =~ tr/j/i/;
    $s =~ s/q/kʷ/g;
    $s =~ s/gw/gʷ/g;
    $s =~ s/h/x/g;
    $s =~ s/ƕ/ʍ/g;
  }

  $s =~ s/c̣₁/c̣/g;
  $s =~ s/([sczṣž])₁/\1/g;

  $s =~ s/([aeiouyåąāàáăȁãâäǟằắạěėéèēẽȩêḕểĕḗẹëеǝəәæǣǽìíìĭịıīįȋîĩɨïȉɪóōǭòȍôȏõŏöȫøœɔṓṑ0ŭūüúùũȕûṹǖűỳýȳỹŷÿ])i/\1j/g;
  $s =~ s/([aeouyåąāàáăȁãâäǟằắạěėéèēẽȩêḕểĕḗẹëеǝəәæǣǽìíìĭịıīįȋîĩɨïȉɪóōǭòȍôȏõŏöȫøœɔṓṑ0ŭūüúùũȕûṹǖűỳýȳỹŷÿ])u/\1w/g;

  return $s;
}

sub simplify {
  my $s = shift;
  my $lang = shift;
  my $orig_s = $s;

  $s =~ s/[⁽⁾]//g;

  $s = Unicode::Normalize::NFD($s);
  $s =~ s/̣//g;
  $s = Unicode::Normalize::NFC($s);
  
  if ($lang =~ /proto-dargwa/) {
    $s =~ s/I//g;
  }

  $s =~ s/z̩/z/g;
#  print STDERR "$s : (".(join ",", split //, $s).")\n";
  if ($lang eq "Com. Celt.") {
    $s =~ s/ɸ/f/g;
  }
  if ($lang eq "Ir." || $lang eq "Welsh." || $lang =~ /^mw\.?$/i) {
    $s =~ s/’//g;
  }

  $s =~ s/ǥ/g/g;
  
  if ($lang eq "PUralic." || $lang eq "PUgric.") {
    $s =~ s/[ɜᴈ]/ä/g;
    $s =~ s/ȣ̈/ü/g;
    $s =~ s/ɤ/o/g;
    $s =~ s/[ȣᴕ]/u/g;
    $s =~ s/’//g;
  }

  $s =~ s/l̨/ľ/g;
  $s =~ s/n̨/ň/g;
  $s =~ s/r̨/ř/g;

  $s =~ s/ῠ́/υ/g;
  $s =~ s/ῡ́/ῡ/g;
  $s =~ s/᾽//g;
  $s =~ s/υ̃/ῦ/g;
  $s =~ s/ᾱ́/ᾱ/g;
  $s =~ s/ᾰ́/α/g;
  $s =~ s/ῑ̆/ῑ/g;
  $s =~ s/ῐ́/ι/g;

  $s =~ s/ỉ/i/g;
  $s =~ s/ŝ/š/g;
  $s =~ s/ĉ/č/g;

  $s =~ s/ˊ//g;
  
  $s =~ s/ṣ/S/g;
  $s =~ s/dʰ/D/g;
  $s =~ s/ṅ/N/g;
  $s =~ s/g[ʰh]/G/g;
  $s =~ s/d[ʰh]/D/g;
  $s =~ s/t[ʰh]/T/g;
  $s =~ s/b[ʰh]/B/g;
  $s =~ s/ǵ[ʰh]/Ǵ/g;
  $s =~ s/k[ʰh]/K/g;
  $s =~ s/p[ʰh]/P/g;
  $s =~ s/ỵ/y/g;

  $s =~ s/ʍ/xʷ/g;
  
  $s =~ s/̊//g;
  $s =~ s/^῎//g;
  $s =~ s/'//g;
  $s =~ s/̀//g;
  $s =~ s/(.)̣/$1/g; # uc($1)?
  $s =~ s/̱//g;
  $s =~ s/̇//g;

  $s =~ s/\pM//g;

  $s = Unicode::Normalize::NFC($s);
  $s =~ s/([āâǟēêḕểḗǣīȋîōǭôȏȫṓṑūǖȳȓ])/\1ː/g;
  $s =~ tr/åąāàáăȁãâäǟằắạěėéèēẽȩêḕểĕḗẹëеǝəәæǣǽӕìíìĭịıīįȋîĩɨïȉɪóōǭòȍôȏõŏöȫøœɔṓṑ0ŭūüúùũȕûṹǖűỳýȳỹŷÿṛṙŕȓḷĺḽłƛʎļɱņẑẓẕḳķḵʰɦħχʡʕʷᵤṗɵƀḇģɢġǧḿʲɳŵṽβφ/aaaaaaaaaaaaaaeeeeeeeeeeeeeeeeeeeeeeiiiiiiiiiiiiiiiooooooooooooooooouuuuuuuuuuuyyyyyyrrrrlllɫľľľmňzzzkkkhhxxHHwwpþbbggggmjnwvfv/;
  $s =~ s/ṃ/m/g;
  $s =~ s/ṇ/n/g;
  $s =~ s/ḍ/d/g;
  $s =~ s/ṭ/t/g;
  $s =~ s/ḥ/h/g;
  $s =~ s/ʁ/x/g;
  $s =~ s/ŕ/r/g;
  $s =~ s/ń/ň/g;
  $s =~ s/ᵈ/d/g;
  $s =~ s/[ⁱ\-]//g;
  $s =~ s/х/x/g; # cyrillic х

#  $s =~ s/kʷ/kw/g;
#  $s =~ s/gʷ/gw/g;

  
  unless ($lang =~ /(semitic|egyptian|berber)/i) {
    while ($s =~ s/([^ː])\1([^ː]|$)/\1ː\2/g) {
    }
  }

  unless ($s =~ /^[a-zšśčňľćřźǫęľɫêôǵḱžþɣṕŋçďðťTDSHNGBǴQKVCʔPː]+$/) {
    my $vars = $s;
    $vars =~ s/[a-zšśčňľćřźǫęľɫêôǵḱžþɣŋçďðťTDSHNGBǴQKVCʔPː]//g;
    print STDERR "($lang) $s ($vars) - $orig_s - $orig_s\n" ;
    return "";
  }

  if ($lang =~ /(?:mo?)?gr\./) {
    $s =~ s/nTos$//g;
    $s =~ s/nT[ea]$//g;
  }
  
  return $s;
}

sub is_valid_greek_word {
  my $s = shift;
  $s = lc(Unicode::Normalize::NFC($s));
  $s =~ s/^῎//;
  $s =~ s/^\*//;
  $s =~ s/ (adj)\.?$//;
  $s =~ s/^([^ ]+) in .*/\1/;
  $s =~ s/^([^ ]+), +.*/\1/;
  $s =~ s/^([^ ]+) +[\(\-\[\?;].*/\1/;
  $s =~ s/^([^ ]+) \([^ ]+\)$/\1/;
  $s =~ s/ \d+\.?.*$//;
  $s =~ s/^([^ ]*[α-ω][^ ]*)\s+[a-z].*/\1/;
  $s =~ s/(?<=[α-ω])o(?=[α-ω])/ο/g;
  $s =~ s/\(.\)//g;
  $s =~ s/ύ/ύ/g;
  $s =~ s/ό/ό/g;
  $s =~ s/ί/ί/g;
  $s =~ s/ά/ά/g;
  $s =~ s/έ/έ/g;
  $s =~ s/ή/ή/g;
  $s =~ s/ώ/ώ/g;
  $s =~ s/η̃/ῆ/g;
  $s =~ s/α̃/ᾶ/g;
  $s =~ s/υ̃/ῦ/g;
  $s =~ s/ι̃/ῖ/g;
  $s =~ s/ω̃/ῶ/g;
  $s =~ s/ῠ́/υ/g;
  $s =~ s/ῡ́/υ/g;
  $s =~ s/ᾱ́/α/g;
  $s =~ s/ᾰ́/α/g;
  $s =~ s/ῑ̆/ι/g;
  $s =~ s/ῐ́/ι/g;
  $s =~ s/̄//g;
  $s =~ s/᾽//g;
#  print STDERR "<$s>\n";
  return 1 if $s =~ /^[αβγδεζηθικλμνξοπρστυφχψωάἀὰᾰᾱᾶᾳἂἄἆἇᾲᾴᾷᾀᾂᾄᾆᾇέἐὲἒἔϝήἠὴῆῃἢἤἦᾐᾑῂῄῇᾒᾔᾖίἰὶῐῑῖϊΐἲἴἶῒΐόὀὸὂὄῤῥύὐὺῠῡῦϋΰὒὔὖῢΰῧώὠὼῶῳὢὤὦᾠῲῴῷᾢᾤᾦϛςϝϐ\-=ᾁᾅἁἅἃᾃἓἕἑἡᾓᾗἣἧἥᾕἷἱἳἵὁὃὅὑὓὕὗὡὣὧὥᾡᾣᾧᾥ]+$/;
  return 0;
}

sub is_valid_old_frison_word {
  my $s = shift;
  $s = Unicode::Normalize::NFC($s);
  $s =~ s/^([^ ]+), -.*/\1/;
  $s =~ s/ \d+\.?$//;
  return 1 if $s =~ /^[A-Za-zō'äā\-=]+$/;
  return 0;
}

1;
