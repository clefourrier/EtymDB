package ScriptManager;

use strict;
use utf8;
use Exporter;
use Translitterate;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $REFC);

use Unicode::Normalize;

$VERSION     = '0.01';
@ISA         = qw(Exporter);
@EXPORT      = qw(&normalize &translitterate &is_valid_greek_word &is_valid_old_frison_word);

sub normalize {
  my $s = shift;
  my $lang = shift;
  my $no_lc = shift || 0;
  my $orig_s = $s;

  $s =~ s/-\d+$//;
  $s =~ s/([^\d])\d{2,}$/$1/;
  $s =~ s/\(\d+\)$//;
  $s =~ s/[\[\]\?\.‎΄·⋅˖‑⁺ˣ]//g;
#  $s =~ s/~//g;
  $s =~ s/…/-/g;

  if ($lang =~ /(^| )(?:mo?)?gr\.?/i || $lang =~ /^lin\.? ?b/i || $lang =~ /^car\./i || $lang =~ /(?:^| )(?:illyrg|o?phryg|thrac|maced)/i) {
    $s =~ s/ϕ/φ/gi;
    $s =~ s/о/ο/gi;
    $s =~ s/µ/μ/gi;
    $s =~ s/[kϰ]/κ/gi;
    $s =~ s/q/κʷ/gi;
  }
  if ($lang eq "Com. Ger." || $lang =~ /^pgm/i || $lang =~ /^gaul/i || $lang =~ /^O[EN]\.?$/ || $lang =~ /^OSax/) {
    $s =~ s/đ/ð/g;
    $s =~ s/θ/þ/g;
  }
  if ($lang =~ /^o?lat/i) {
    $s =~ s/ῑ/ī/g; # found this once
  }
  if ($lang =~ /^oe\.?$/i) {
    $s =~ s/ό/ó/g; # found this once
  }
  if ($lang =~ /(^| )(?:mo?)?gr\./i) {
    $s =~ s/y/u/g;
  }

  $s =~ s/²//gi;
#  $s =~ s/\+//gi;
  $s =~ s/=/-/gi;
  $s =~ s/\/$//gi;
  $s =~ s/://gi;

  $s =~ s/a՛/á/g;

  $s =~ s/a\^/â/gi;
  $s =~ s/e\^/ê/gi;
  $s =~ s/i\^/î/gi;
  $s =~ s/u\^/û/gi;
  $s =~ s/o\^/ô/gi;
  $s =~ s/r\^/ȓ/gi;
  $s =~ s/l\^/ḽ/gi;
  $s =~ s/m\^/ɱ/gi;
  $s =~ s/(ę|ę)\^/ę̂/gi;
  $s =~ s/z\^/ẑ/gi;
  $s =~ s/n\^/n/gi;#ou ň? (OE. chez Orel)

  $s =~ s/c\^/č/gi;

  if ($lang =~ /^(cz|slk|svk)/i) {
    $s =~ s/t’/ť/g;
    $s =~ s/d’/ď/g;
  }

  if ($lang =~ /^(?:hitt|pal|car|myl|mys|luw|lyd|lyc)\./i) {
    $s =~ s/h/ḫ/g;
    $s =~ s/h̯/ḫ/g;
  }

  $s =~ s/à/à/gi;
  $s =~ s/ś/ś/gi;
  $s =~ s/é/é/gi;
  $s =~ s/ę/ę/gi;
  $s =~ s/ó/ó/gi;
  $s =~ s/ι̃/ῖ/gi;
  $s =~ s/α̃/ᾶ/gi;
  $s =~ s/η̃/ῆ/gi;
  $s =~ s/ῃ̃/ῇ/gi;
  $s =~ s/υ̃/ῦ/gi;
  $s =~ s/ω̃/ῶ/gi;

  $s =~ s/ύ/ύ/gi;
  $s =~ s/ό/ό/gi;
  $s =~ s/ί/ί/gi;
  $s =~ s/ά/ά/gi;
  $s =~ s/έ/έ/gi;
  $s =~ s/ή/ή/gi;
  $s =~ s/ώ/ώ/gi;

  $s =~ s/^C/c/g;
  $s =~ s/^V/v/g;
  unless ($lang =~ /^pie/i) {
    $s =~ s/^H/h/g;
  }

  $s =~ s/H/_unknownh_/g;
  $s =~ s/C/_unknownc_/g;
  $s =~ s/(Ṿ|Ṿ|V|Ṽ)/_unknownv_/g;
  $s = lc($s) unless $no_lc;
  $s =~ s/_unknownh_/H/g;
  $s =~ s/_unknownc_/C/g;
  $s =~ s/_unknownv_/V/g;

  $s =~ s/(ẖ|ẖ)/ç/g;

  $s =~ s/ǳ/dz/g;

  if ($lang =~ /^pie/i) {
    $s =~ s/[Hh]1/h₁/g;    
    $s =~ s/[Hh]2/h₂/g;    
    $s =~ s/[Hh]3/h₃/g;    
    $s =~ s/[Hh]4/h₄/g;    
    $s =~ s/ĝ/ǵ/g;
    $s =~ s/g[’']/ǵ/g;
    $s =~ s/k[’']/ḱ/g;
    $s =~ s/e([₁₂₃123ᵃ₄ª])/h\1/g;
    $s =~ s/([ǵgkḱbdpt])h([^₁₂₃123ᵃ₄ª]|-|$)/\1ʰ\2/g;
    $s =~ s/([gk])wh([^₁₂₃123ᵃ₄ª]|-|$)/\1ʷʰ\2/g;
    $s =~ s/([gk])w/\1ʷ/g;
    $s =~ s/u̯/U/g;
    $s =~ s/i̯/I/g;
    $s =~ s/(ā́|ḗ|ṓ|[aáāeéēoóō])u/\1U/g;
    $s =~ s/(ā́|ḗ|ṓ|[aáāeéēoóō])i/\1I/g;
    $s =~ s/u(ā́|ḗ|ṓ|[aáāeéēoóō])/U\1/g;
    $s =~ s/i(ā́|ḗ|ṓ|[aáāeéēoóō])/I\1/g;
    $s =~ s/U/u̯/g;
    $s =~ s/I/i̯/g;
  }

  if ($lang =~ /^hit/i) {
    $s =~ s/-?([ᶻⁱʳᵗª\⁾\⁽]+)$/-/;
  }
  
  return $s;
}

sub translitterate {
  my $s = shift;
  my $lang = shift;
  my $orig_s = $s;

  $s =~ s/ṷ/u̯/g;
  $s =~ s/ꝣ/z/g;

  $s = Translitterate::rawtranslitterate($s);

  if ($lang =~ /arm/i) {
    $s =~ s/T/tʿ/g;
    $s =~ s/Č/č̣/g;
    $s =~ s/C/cʿ/g;
    $s =~ s/P/pʿ/g;
    $s =~ s/K/kʿ/g;
  }
  
  $s =~ s/ʀ/r/g;

  if ($lang eq "Skt.") { # TODO: pas de y pour un [j]
    $s =~ tr/ँंःअआइईउऊऋऌऍऎएऑऒओािॢीॣुूृॄॆेॅॊोॉ्/ṁṃḥaāiīuūṛḽêeēôoōãìḼĩḼùũṚṚèẽễòõỗ`/;
    $s =~ s/ै/àʲ/g;
    $s =~ s/ौ/àʷ/g;
    $s =~ s/ॐ/oᵐ/g;
    $s =~ s/ॠ/ṛ/g;
    $s =~ s/ॡ/ḽ/g;
    $s =~ s/ऐ/aʲ/g;
    $s =~ s/औ/aʷ/g;
    $s =~ s/क/kᵃ/g;
    $s =~ s/ख/kʰᵃ/g;
    $s =~ s/ग/gᵃ/g;
    $s =~ s/घ/gʰᵃ/g;
    $s =~ s/ङ/ṅᵃ/g;
    $s =~ s/च/cᵃ/g;
    $s =~ s/छ/cʰᵃ/g;
    $s =~ s/ज/jᵃ/g;
    $s =~ s/ज़/zᵃ/g;
    $s =~ s/झ/jʰᵃ/g;
    $s =~ s/ञ/ñᵃ/g;
    $s =~ s/ट/ṭᵃ/g;
    $s =~ s/ठ/ṭʰᵃ/g;
    $s =~ s/ड/ḍᵃ/g;
    $s =~ s/ढ/ḍʰᵃ/g;
    $s =~ s/ढ़/ḓʰᵃ/g;
    $s =~ s/ण/ṇᵃ/g;
    $s =~ s/त/tᵃ/g;
    $s =~ s/थ/tʰᵃ/g;
    $s =~ s/द/dᵃ/g;
    $s =~ s/ध/dʰᵃ/g;
    $s =~ s/न/nᵃ/g;
    $s =~ s/ऩ/ṉᵃ/g;
    $s =~ s/प/pᵃ/g;
    $s =~ s/फ/pʰᵃ/g;
    $s =~ s/फ़/fᵃ/g;
    $s =~ s/ब/bᵃ/g;
    $s =~ s/भ/bʰᵃ/g;
    $s =~ s/म/mᵃ/g;
    $s =~ s/य/yᵃ/g;
    $s =~ s/य़/ẏᵃ/g;
    $s =~ s/र/rᵃ/g;
    $s =~ s/ऱ/ṛᵃ/g;
    $s =~ s/ल/lᵃ/g;
    $s =~ s/ळ/ḷᵃ/g;
    $s =~ s/ऴ/ẕᵃ/g;
    $s =~ s/व/vᵃ/g;
    $s =~ s/श/śᵃ/g;
    $s =~ s/ष/ṣᵃ/g;
    $s =~ s/स/sᵃ/g;
    $s =~ s/ह/hᵃ/g;
    $s =~ s/क़/qᵃ/g;
    $s =~ s/ख़/ḵʰᵃ/g;
    $s =~ s/ग़/gʰᵃ/g;
    $s =~ s/ड़/ḓᵃ/g;
    $s =~ s/ᵃ([aāiīuūṛḽêeēôoōãìḼĩḼùũṚṚèẽễòõỗ])/\1/g;
    $s =~ s/ᵃ/a/g;
    # simplification
    $s =~ s/​//g;
    $s =~ s/‍//g;
    $s =~ s/Ṛ/ṛ/g;
  }

  if ($lang =~ /^o?gaulg/i || $lang =~ /(?:^| )(?:lycc|thrac|o?phryg|maced)/i) {
    $s =~ tr/αβγδεηικλμνοπρστυωϙϻάἀὰᾰᾱᾶᾳἂἄἆἇᾲᾴᾷᾀᾂᾄᾆᾇέἐὲἒἔϝήἠὴῆῃἢἤἦᾐᾑῂῄῇᾒᾔᾖίἰὶῐῑῖϊΐἲἴἶῒΐόὀὸὂὄῤῥύὐὺῠῡῦϋΰὒὔὖῢΰῧώὠὼῶῳὢὤὦᾠῲῴῷᾢᾤᾦϛςϐ/abgdeêiklmnoprstuôqṣaaaaaaaaaaaaaaaaaaaeeeeewêêêêêêêêêêêêêêêêiiiiiiiiiiiiiooooorruuuuuuuuuuuuuuôôôôôôôôôôôôôôôssb/;
    $s =~ s/ζ/zd/g;
    $s =~ s/ξ/ks/g;
    $s =~ s/ψ/ps/g;
    $s =~ s/θ/tʰ/g;
    $s =~ s/φ/pʰ/g;
    $s =~ s/χ/kʰ/g;
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
