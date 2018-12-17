load 'shape_grammar.rb'

$sgi=SGInvalidator.new

$g1=SGRules::Grammar.create()
$g1.add(SGRules::Split.new('','BB1,REM','20',1,Repeat::None))
$g1.add(SGRules::Split.new('REM','BB2,REM','20,',0,Repeat::None,true))
$g1.add(SGRules::Split.new('BB1','O,C,O','9,2',1))
$g1.add(SGRules::Split.new('BB2','O,C,O','9,2',0))


$sgi.add_grammar $g1
$sgi.add_range($g1.inputs)
$sgi.invalidate

$sgi.reset_timer
nil