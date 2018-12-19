load 'shape_grammar.rb'

$sgi=SGInvalidator.new

$g1=SGRules::Grammar.create()
$g1.v('setback',3)
$g1.v('plotw',15)
$g1.v('bdepth',20)
$g1.v('bwidth',10)
$g1.v('porch',2.5)
$g1.v('sundepth',7)
$g1.v('ftfh',4.2)


# $g1.add(SGRules::Split.new('','','20000',1,Repeat::None))
$g1.add(SGRules::Comment.new('Divide the plot and create the house'))
$g1.add(SGRules::SplitEqual.new('','plot','plotw*2',0,Repeat::Last))
$g1.add(SGRules::Split.new('','plotR,plot','r0.5,',0,Repeat::Last))
$g1.add(SGRules::FlipAxis.new('plotR','plot',[-1,1,1]))
$g1.add(SGRules::Split.new('plot','yard,house','setback,bdepth',1,Repeat::None))
$g1.add(SGRules::Split.new('house','house,yard','bwidth',0,Repeat::None))

$g1.add(SGRules::Comment.new('Detail massing'))
$g1.add(SGRules::Split.new('house','entrance,living,house','porch,sundepth',1,Repeat::None))
$g1.add(SGRules::FlipAxis.new('house','house',[1,-1,1]))
$g1.add(SGRules::Split.new('house','dining,house','sundepth',1,Repeat::None))
$g1.add(SGRules::Split.new('house','mid,yard','sundepth',0,Repeat::None))
$g1.add(SGRules::Split.new('entrance','entrance,yard','porch',0,Repeat::None))

$g1.add(SGRules::Split.new('mid','mid_1,mid_2,mid_3','ftfh,ftfh',2))
$g1.add(SGRules::Extend.new('mid_1','mid_1','2',0))
$g1.add(SGRules::Extend.new('mid_3','mid_3','2',1))
# $g1.add(SGRules::Extend.new('mid_3','mid_3','-2',1))

$g1.add(SGRules::Comment.new('Beautification'))
$g1.add(SGRules::Split.new('living','living_1,living_2,REM','ftfh,ftfh',2))
$g1.add(SGRules::Split.new('dining','dining_1,dining_2,dining_3','ftfh,ftfh',2))
$g1.add(SGRules::Split.new('dining_3','dining_3,REM','sundepth*0.7',0))

$g1.add(SGRules::Split.new('entrance','entrance,REM','ftfh',2))

$g1.add(SGRules::Remove.new('yard'))
$g1.add(SGRules::Remove.new('REM'))

# $g1.add(SGRules::Union.new('dining_3,mid_3','union'))
$g1.add(SGRules::Translate.new('living_2','，living_2,garden','r0,1',2))
$g1.add(SGRules::Translate.new('mid_1','mid_1,garden','r0,1',2))
$g1.add(SGRules::Translate.new('dining_2','dining_2,garden','r0,1',2))

$g1.add(SGRules::FlipAxis.new('garden','garden',[-1,1,1]))
$g1.add(SGRules::Convert.new('garden','green',1))


$sgi.add_grammar $g1
$sgi.add_range($g1.inputs)
$sgi.invalidate

$sgi.reset_timer
SG::SGUI.create $g1
nil