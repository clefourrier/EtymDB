package Translitterate;

use strict;
use utf8;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $REFC);

use Unicode::Normalize;

$VERSION     = '0.01';
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&rawtranslitterate);
%EXPORT_TAGS = ();

sub rawtranslitterate {
  my $s = shift;
  $s =~ s/𐀀/a/g;
  $s =~ s/𐀁/e/g;
  $s =~ s/𐀂/i/g;
  $s =~ s/𐀃/o/g;
  $s =~ s/𐀄/u/g;
  $s =~ s/𐀅/da/g;
  $s =~ s/𐀆/de/g;
  $s =~ s/𐀇/di/g;
  $s =~ s/𐀈/do/g;
  $s =~ s/𐀉/du/g;
  $s =~ s/𐀊/ja/g;
  $s =~ s/𐀋/je/g;
  $s =~ s/𐀍/jo/g;
  $s =~ s/𐀏/ka/g;
  $s =~ s/𐀐/ke/g;
  $s =~ s/𐀑/ki/g;
  $s =~ s/𐀒/ko/g;
  $s =~ s/𐀓/ku/g;
  $s =~ s/𐀔/ma/g;
  $s =~ s/𐀕/me/g;
  $s =~ s/𐀖/mi/g;
  $s =~ s/𐀗/mo/g;
  $s =~ s/𐀘/mu/g;
  $s =~ s/𐀙/na/g;
  $s =~ s/𐀚/ne/g;
  $s =~ s/𐀛/ni/g;
  $s =~ s/𐀜/no/g;
  $s =~ s/𐀝/nu/g;
  $s =~ s/𐀞/pa/g;
  $s =~ s/𐀟/pe/g;
  $s =~ s/𐀠/pi/g;
  $s =~ s/𐀡/po/g;
  $s =~ s/𐀢/pu/g;
  $s =~ s/𐀣/qa/g;
  $s =~ s/𐀤/qe/g;
  $s =~ s/𐀥/qi/g;
  $s =~ s/𐀦/qo/g;
  $s =~ s/𐀨/ra/g;
  $s =~ s/𐀩/re/g;
  $s =~ s/𐀪/ri/g;
  $s =~ s/𐀫/ro/g;
  $s =~ s/𐀬/ru/g;
  $s =~ s/𐀭/sa/g;
  $s =~ s/𐀮/se/g;
  $s =~ s/𐀯/si/g;
  $s =~ s/𐀰/so/g;
  $s =~ s/𐀱/su/g;
  $s =~ s/𐀲/ta/g;
  $s =~ s/𐀳/te/g;
  $s =~ s/𐀴/ti/g;
  $s =~ s/𐀵/to/g;
  $s =~ s/𐀶/tu/g;
  $s =~ s/𐀷/wa/g;
  $s =~ s/𐀸/we/g;
  $s =~ s/𐀹/wi/g;
  $s =~ s/𐀺/wo/g;
  $s =~ s/𐀼/za/g;
  $s =~ s/𐀽/ze/g;
  $s =~ s/𐀿/zo/g;
  $s =~ s/𐁁/ai/g;
  $s =~ s/𐁂/au/g;
  
  $s =~ tr/𐌀𐌁𐌂𐌃𐌄𐌅𐌆𐌇𐌈𐌉𐌋𐌌𐌍𐌐𐌑𐌓𐌔𐌕𐌖𐌘𐌙𐌚𐌞𐌝𐌊/abcdevzhθilmnpśrstuφψfúík/;

  $s =~ tr/ᚁᚂᚃᚄᚅᚆᚇᚈᚉᚊᚋᚌᚍᚎᚏᚐᚑᚒᚓᚔ/blwsnhdtkkʷmggʷSraouei/;
  
  $s =~ tr/აბგდევზჱთილმნჲოჟრსჳუჷფქღჸშჩცხჴჰჵჶ/abɡdevzētilmnjožrswuəpkğʔščcxqhōf/;
  $s =~ s/ძ/dz/g;
  $s =~ s/ჯ/dž/g;
  $s =~ s/კ/kʼ/g;
  $s =~ s/წ/cʼ/g;
  $s =~ s/ჭ/čʼ/g;
  $s =~ s/ყ/qʼ/g;
  $s =~ s/პ/pʼ/g;
  $s =~ s/ტ/tʼ/g;
  
  $s =~ tr/ᚠᚢᚦᚨᚱᚲᚷᚹᚻᚺᚾᛁᛃᛇᛈᛉᛊᛋᛏᛒᛖᛗᛚᛜᛝᛟᛞ/fuþarkgwhhnijïpzsstbemlŋŋod/;

  $s =~ tr/абвгдежзийклмнопрстуфхцчшыэіѳѣѵѡѫѧꙑѹ/abvgdežzijklmnoprstufxcčšyèifěiôǫęiu/;
  $s =~ s/ё/jo/g;
  $s =~ s/щ/šč/g;
  $s =~ s/ю/ju/g;
  $s =~ s/я/ja/g;
  $s =~ s/ѕ/dz/g;
  $s =~ s/ѯ/ks/g;
  $s =~ s/ѱ/ps/g;
  $s =~ s/ѭ/jǫ/g;
  $s =~ s/ѩ/ję/g;
  $s =~ s/ѥ/je/g;
  $s =~ s/є/e/g;
  $s =~ s/ꙗ/ja/g;
  $s =~ tr/ьъ/ĭŭ/;

  $s =~ tr/𐌰𐌱𐌲𐌳𐌴𐌵𐌶𐌷𐌸𐌹𐌺𐌻𐌼𐌽𐌾𐌿𐍀𐍂𐍃𐍄𐍅𐍆𐍇𐍈𐍉/abgdēqzhþiklmnjuprstwfxƕō/;

  $s =~ s/ու/u/g;
  $s =~ s/և/ew/g;
  $s =~ tr/աբգդեզէըթժիլխծկհձղճմյնշոչպջռսվտրցւփքօֆ/abgdezēëTžilxckhjġČmynšočpjrṙsvtrCwPKōf/;

  return $s;
}

1;
