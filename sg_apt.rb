load 'shape_grammar.rb'

$sgi=SGInvalidator.new

$g1=SGRules::Grammar.create()
$g1.v('ud',9)
$g1.v('uw',3)


$g1.add(SGRules::Split.new('','BB1,REM','20000',1,Repeat::None))
$g1.add(SGRules::Split.new('','BB1,REM','ud*2+2,',1,Repeat::None))
$g1.add(SGRules::Split.new('REM','BB2,REM','ud*2+2,',0,Repeat::None,true))
$g1.add(SGRules::Split.new('BB1','O,C,O2','ud,2',1))
$g1.add(SGRules::RotAxis.new('BB2','BB2',1))
$g1.add(SGRules::Split.new('BB2','O3,C2,O','ud,2',1))
$g1.add(SGRules::Extend.new('O3','O','ud',0))
$g1.add(SGRules::Extend.new('C2','C','ud',0))
$g1.add(SGRules::Split.new('O2','REM,O','ud+2',0))
$g1.add(SGRules::Split.new('O','U','uw',0,112))
$g1.add(SGRules::Remove.new('REM'))

$sgi.add_grammar $g1
$sgi.add_range($g1.inputs)
$sgi.invalidate

$sgi.reset_timer
SG::SGUI.create $g1
nil