.ic ^^
.tr ~
.hc `
.qc "
.pc @
.fs '____________________'''
.pl 66
.pw 68
.nd 1
.in 0
.po 0
.ll 60
.ls 1
.m1 4
.m2 2
.m3 2
.m4 2
.hy 3
.fi
.ju
.id skip_all_macros skip_all_macros
.an skip_all_macros +1
.ze >>> Macro package used more than once.  Use #^(skip_all_macros) ignored. <<<
.el skip_all_macros
.an skip_all_macros 1
.ze >>> Bulk Macros.  KLIST with o=4 g=0 +sf <<<
.at production
FASS 1990
.en production
.at title
FASSical Studies 1990
.en title
.af mon 01
.af day 01
.af min 01
.af hour 01
.zz -- Print a warning message with act and scene number
.at warning
.ze *** WARNING ^^(actr):^^(scen) -- @1
.en warning
.at squeeze_line
.sq
.sp
.en squeeze_line
.zz -- reset to normal
.at ex
^(squeeze_line)
.fi
.in 3
.ne 2
.en ex
.zz -- actor direction
.at ad
^(ex)
.in 0
.en ad
.zz -- Define a character abbreviation for use by .ch
.at define_name
.an chars_defined +1
.an @1_number 0^^(chars_defined)
.an @1_speechcount 0
.an @1_firstspeech 0
.at @1_longname
@2
.en (@1_longname)
.at @1_shortname
@3
.en (@1_shortname)
.dn 1 divert
.if ^^^^(@1_speechcount)=0 defined
	^^(@1_number).	<@1>	^^(@1_longname)~		~--NO~LINES--~~~~
.warning "^^(@1_longname) <@1> has no speeches in this scene"
.el defined
	^^(@1_number).	<@1>	^^(@1_longname)~	~^^^^(@1_speechcount)~	~^@^^^^(@1_firstspeech)
.en defined
.en divert
.en define_name
.zz -- Define a character abbreviation and print a cast of characters
.at na
.mg
                 . . . . . . . . . . . . . . . . . .
.if "@2"<1 endif2
.warning "'.na @1' needs long and short character names"
.define_name "@1" "<@1>--UNDEFINED" "<@1>"
	^^(@1_number).	<@1>	--NO~LONG~NAME--~	~(--NO~SHORT~NAME--)
.el endif2
.if "@3"<1 endif3
.warning "'.na @1' needs a third argument (short name)"
.define_name "@1" "@2" "@2"
	^^(@1_number).	<@1>	^^(@1_longname)~	~(--NO~SHORT~NAME--)
.el endif3
.define_name "@1" "@2" "@3"
	^^(@1_number).	<@1>	^^(@1_longname)~	~(^^(@1_shortname))
.en endif3
.en endif2
.mg

.zz
.en na
.zz -- one-use character macro
.at xx
.an ##_speechcount 0
.at ##_number
.en ##_number
.at ##_longname
@1
.en ##_longname
.at ##_shortname
__________'##'
.en ##_shortname
.ch ##
.an chars_used -1
.en xx
.at star
************************************************************
.en star
.zz -- song begin
.at sb
^(ex)
.if "@1">48 sb_endif
.warning "Title of song is more than 48 characters wide"
.warning "Title: '@1'"
.en sb_endif
.if "@2">48 sb_endif
.warning "Title of tune is more than 48 characters wide"
.warning "Title: '@2'"
.en sb_endif
.an song_count +1
.in 0
.nf
.ne 12
^(star)
.mg
*****                                                  *****
.ce 3
~@1~
~(to the tune of:)~
~@2~
.mg

^(star)
.sp
.in 3
.en sb
.zz -- verse separator
.at ve
^(ex)
.nf
.ne @1 5
.en ve
.zz -- song end
.at se
.warning ".se macro is obsolete.  Use .ex or nothing."
.ex
.en se
.zz -- begin a scene
.at bs
.pa 1
.an speech_count 0
.an chars_defined 0
.an chars_used 0
.an song_count 0
.an light_count 0
.an music_count 0
.an sound_count 0
.an sfx_count 0
.zz -- Divert list of character names defined to this file.
.fa 1 *defined
.an act
.at actr
@1
.en actr
.at scen
@2
.en scen
.ze >>> Now formatting ^^(actr):^^(scen)@4 -- @3 <<<
.he "^^(actr):^^(scen)@4"^(title)"Page %"
.fo "^^(actr):^^(scen)@4 Page %"^(production)"^(year)/^(mon)/^(day)-^(hour):^(min)"
.sp
.ce
.bf
@3
.sp 2
.he "^^(actr):^^(scen)@4"@3"Page %"
.bf
Characters defined for this scene:
.sp
.nf
.ta 3 R +3 +2 L +8 L R 57
.en bs
.zz -- end a scene
.at es
.zz -- Close diverted list of character names for use later.
.cl 1
.m3 1
.m4 0
.sp
.in 0
.ce
-~fin~-
.br
.m3 2
.m4 2
.an save_page ^^(%)
.en es
.zz -- end a scene
.at fini
.warning "FINI macro is obsolete.  Use .es"
.es
.en fini
.zz -- character macro
.at ch
.id @1_longname ch_endid
^(ex)
.ti 0
.an speech_count +1
.an @1_speechcount +1
.if ^^(@1_speechcount)=1 ch_endif
.bf
.uc
^^(speech_count)-^^(@1_longname):
.nc
.an @1_firstspeech ^^(speech_count)
.an chars_used +1
.el ch_endif
.uc
^^(speech_count)-^^(@1_shortname):
.nc
.en ch_endif
.el ch_endid
.warning "'.ch @1' abbreviation used but not defined by .na"
.warning "at speech ^^(speech_count).  Temporary definition created."
.define_name "@1" "<@1>--TEMPORARY" "<@1>"
.ch @1
.en ch_endid
.en ch
.zz -- character name in song
.at sl
.id @1_longname sl_endid
^(ex)
.nf
.uc
^^(@1_shortname):
.nc
.el sl_endid
.warning "'.sl @1' abbreviation used in song but not defined by .na"
.warning "near speech ^^(speech_count).  Temporary definition created."
.define_name "@1" "<@1>--TEMPORARY" "<@1>"
.sl @1
.en sl_endid
.en sl
.zz -- one-time character name in song
.at ss
.nf
@1:
.en ss
.zz -- sound direction
.at sd
^(ad)
.an sound_count +1
[S-^^(sound_count)]
.zz TECH: .no [S-^^(sound_count)]
.no S
.en sd
.zz -- lighting direction
.at ld
^(ad)
.an light_count +1
[L-^^(light_count)]
.zz TECH: .no [L-^^(light_count)]
.no L
.en ld
.zz -- special effect
.zz -- musical direction
.at md
^(ad)
.an music_count +1
[M-^^(music_count)]
.zz MUSIC: .no [M-^^(music_count)]
.no M
.en md
.zz -- special effects direction
.at sfx
^(ad)
.an sfx_count +1
[X-^^(sfx_count)]
.zz TECH: .no [X-^^(sfx_count)]
.no X
.en sfx
.zz -- prop stuff (null for Bulk)
.at (prip)
.en (prip)
.at (prop)
@1
.en (prop)
.zz -- Turn off parameter character.
.pc
.zz -- Skip to here if macro package already defined.
.en skip_all_macros

