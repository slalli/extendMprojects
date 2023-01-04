	; extendMprojects
	; version 1.0.0
	;
	; author: 			Stefano Lalli
	; company name: 	jsonHIVES
	; licence: 			GNU AFFERO GENERAL PUBLIC LICENSE
	;
extendMprojects quit
; ****************************************	
; start(sourceDir,action) 
; sourceDir		directory where the .m files are
; action		defaults to RR. Action can be: RR (replace and rename), RE (replace), NE (new name: original name + '.extended')
; ****************************************	
start(sourceDir) 
	write !,"**********************************"
	write !,"Extend M projects version "_$piece($text(+2)," ",4)
	write !,"**********************************"
	;
	; Validate path
	if $get(sourceDir)="" read !!,"Enter the directory:",sourceDir
	;
	if $zsearch(sourceDir)="" do  quit
	. write !!,"Directory not found...",!!,"Quitting"
	;
	write !
	;
	new file,files,replaceType,marginType,cnt,inputStr,defs,line,action
	new bufferIn,bufferOut,cmd,ifn,isv,quitNow,extension
	;
	; Check # of files in dir
	if $extract(sourceDir,$length(sourceDir))'="/" set sourceDir=sourceDir_"/"
	set cnt=0
	for  set file=$zsearch(sourceDir_"*.m") quit:file=""  set:file'="/extendMprojects/src/extendMprojects.m" files(file)="",cnt=cnt+1
	set files=cnt
	;
	if $data(files)=0 do  quit
	. write !!,"Directory doesn't contain any .m file...",!!,"Quitting"
	;
	write !,"Files found in "_sourceDir_": "_files
	;
	; Prompt for conversion type: upper case or lower case
askAgainType
	read !!,"How do you want to convert the strings ? (U)pper case, (L)ower case, (Q)uit ",inputStr
	set inputStr=$$FUNC^%UCASE(inputStr)
	if inputStr="Q" do  quit
	. write !!,"Bye bye",!!
	if inputStr="U"!(inputStr="L") set replaceType=inputStr
	else  goto askAgainType
	;
	; Prompt for left margin
askAgainMargin
	read !!,"How do you want to convert the left margin ? (A)s it is, (1) space, (4) spaces, (T)tab, (Q)uit ",inputStr
	set inputStr=$$FUNC^%UCASE(inputStr)
	if inputStr="Q" do  quit
	. write !!,"Bye bye",!!
	if inputStr="A"!(inputStr="1")!(inputStr="4")!(inputStr="T") set marginType=$select(inputStr="A":0,inputStr="T":"T",1:+inputStr)
	else  goto askAgainMargin
	;
	; Prompt for the action
askAgainAction
	read !!,"Do you want to (R)eplace the files, replace (A)nd rename the old files, create ne(W) files, (Q)uit ",inputStr
	set inputStr=$$FUNC^%UCASE(inputStr)
	if inputStr="Q" do  quit
	. write !!,"Bye bye",!!
	if inputStr="R"!(inputStr="A")!(inputStr="W") set action=inputStr
	else  goto askAgainAction
	;
	if action="R" goto proceed
	;
aksAgainExtension
	read !!,"Enter the extension you wish to have appended to the .m files: ",!,"It must start with a ., type (Q) to quit ",inputStr
	if inputStr="Q"!(inputStr="q") do  quit
	. write !!,"Bye bye",!!
	if $extract(inputStr)="" goto aksAgainExtension
	if $extract(inputStr,1,1)'="." goto aksAgainExtension
	if $length(inputStr)<2 goto aksAgainExtension
	set extension=inputStr
	;
proceed
	; Overview
	write !!,"OVERVIEW",!
	write !,"You will convert the file into extended "_$select(replaceType="L":"lower case",1:"UPPER CASE")
	write !,"The left margin will be "_$select(marginType=0:"left as it is",marginType="T":"a tab character",marginType=4:"4 spaces",1:"1 space")
	if action="A" write !,"The newly formatted files will replace the existing files, while the old files with have the extension .m"_extension
	if action="W" write !,"The newly formatted files will will have the extension .m"_extension_" while the old files won't be changed."
	if action="R" write !,"The original files will be overwritten with the new files"
	write !,"A total of "_files_" file"_$select(files=1:"",1:"s")_" will be processed."
	;
	read !!,"Do you want to proceed ? (Y)es, (N)o, (Q)uit ",inputStr
	set inputStr=$$FUNC^%UCASE(inputStr)
	if inputStr="Q"!(inputStr="N") do  quit
	. write !!,"Bye bye",!!
	if inputStr'="Y" goto proceed
	;
	; Populate the definition table according to the replaceType
	set cnt=0
	for  set cnt=cnt+1,line=$text(+cnt) quit:line=""  do:$find(line,";;")
	. set type=$piece(line," ",3),from=$piece(line," ",4),to=$piece(line," ",5)
	. set:type'="" defs(type,from)=$select(replaceType="L":$$FUNC^%LCASE(to),replaceType="U":$$FUNC^%UCASE(to),1:to)
	. set:type'="" defs(type,$$FUNC^%LCASE(from))=$select(replaceType="L":$$FUNC^%LCASE(to),replaceType="U":$$FUNC^%UCASE(to),1:to)
	;
	;build replace buffer
	set cmd="" for  set cmd=$order(defs("CMD",cmd)) quit:cmd=""  do
	. set defs("replace","cmd"," "_cmd_" ")=" "_defs("CMD",cmd)_" "
	. set defs("replace","cmd"," "_cmd_":")=" "_defs("CMD",cmd)_":"
	. set defs("replace","cmd",$char(9)_cmd_" ")=$char(9)_defs("CMD",cmd)_" "
	. set defs("replace","cmd",$char(9)_cmd_":")=$char(9)_defs("CMD",cmd)_":"
	;
	set ifn="" for  set ifn=$order(defs("IFN",ifn)) quit:ifn=""  do
	. set defs("replace","ifn",ifn_"(")=defs("IFN",ifn)_"("
	;
	set isv="" for  set isv=$order(defs("ISV",isv)) quit:isv=""  do
	. set defs("replace","isv",isv_"=")=defs("ISV",isv)_"="
	. set defs("replace","isv","="_isv_" ")="="_defs("ISV",isv)_" "
	. set defs("replace","isv","="_isv_",")="="_defs("ISV",isv)_","
	;
	; ----------------------------------------------
	; We can start the conversion
	; ----------------------------------------------
	write !
	set file=""
	for  set file=$order(files(file)) quit:file=""  do
	. ;Read the original file
	. write !,"Processing file: "_file,!
	. open file:readonly
	. use file
	. set cnt=0
	. kill bufferIn
	. for  read line quit:$zeof  set cnt=cnt+1,bufferIn(cnt)=line
	. use $p
	. close file
	. ;
	. ; Process it
	. set *bufferOut=$$extendFile(.bufferIn,.defs)
	. ;
	. ;
	. ; Save it
	. w !
	. zwr bufferOut
	;
	;
	;
	quit
	;
	;
extendFile(buffer,defs)
	new bufferAfter,cnt,line,cmd,cmdReplace,ifnReplace,isvReplace
	;
	merge cmdReplace=defs("replace","cmd")
	merge ifnReplace=defs("replace","ifn")
	merge isvReplace=defs("replace","isv")
	;
	set cnt=0
	for  set cnt=$order(buffer(cnt)) quit:cnt=""  do
	. set line=buffer(cnt)
	. ; -------------------------
	. ; left margin
	. ; -------------------------
	. if marginType>0!(marginType="T") do
	. . if $extract(line,1,1)'=" ",$extract(line,1,1)'=$char(9) quit
	. . set charQuit=0
	. . for charCnt=1:1:$length(line) do  quit:charQuit
	. . . set char=$extract(line,charCnt,charCnt)
	. . . if char'=" ",char'=$char(9) set charQuit=charCnt
	. . set line=$select(marginType="T":$char(9),marginType=1:" ",marginType=4:"    ",1:" ")_$extract(line,charQuit,$length(line))
	. ; -------------------------
	. ; CMD
	. ; -------------------------
	. set line=$$STRRPLC(line,.cmdReplace)
	. ;
	. ; -------------------------
	. ; IFN
	. ; -------------------------
	. set line=$$STRRPLC(line,.ifnReplace)
	. ;
	. ; -------------------------
	. ; ISV
	. ; -------------------------
	. set line=$$STRRPLC(line,.isvReplace)
	. ;
	. ; Populate buffer
	. set bufferAfter(cnt)=line
	;
	quit *bufferAfter
	;
	;
STRRPLC(IN,SPEC) ;
	Q:'$D(IN) "" 
	Q:$D(SPEC)'>9 IN 
	;
	N A1,A2,A3,A4,A5,A6,A7,A8
	;
	S A1=$L(IN),A7=$J("",A1),A3="",A6=9999 
	;
	F  S A3=$O(SPEC(A3)) Q:A3=""  S A6(A6)=A3,A6=A6-1
	F A6=0:0 S A6=$O(A6(A6)) Q:A6'>0  S A3=A6(A6) D:$D(SPEC(A3))#2 RE1
	S A8="" F A2=1:1:A1 D RE3
	;
	Q A8
	;
RE1 S A4=$L(A3),A5=0 F  S A5=$F(IN,A3,A5) Q:A5<1  D RE2
	Q
RE2 Q:$E(A7,A5-A4,A5-1)["X"  S A8(A5-A4)=SPEC(A3)
	F A2=A5-A4:1:A5-1 S A7=$E(A7,1,A2-1)_"X"_$E(A7,A2+1,A1)
	Q
RE3 I $E(A7,A2)=" " S A8=A8_$E(IN,A2) Q
	S:$D(A8(A2)) A8=A8_A8(A2)
	Q
	;
	;
	; ---------------------------
	; DEFINITIONS
	; ---------------------------
	;; CMD B BREAK
	;; CMD C CLOSE
	;; CMD D DO
	;; CMD E ELSE
	;; CMD F FOR
	;; CMD G GOTO
	;; CMD H HANG
	;; CMD I IF
	;; CMD J JOB
	;; CMD K KILL
	;; CMD L LOCK
	;; CMD M MERGE
	;; CMD N NEW
	;; CMD O OPEN
	;; CMD Q QUIT
	;; CMD R READ
	;; CMD S SET
	;; CMD TC TCOMMIT
	;; CMD TRE TRESTART
	;; CMD TRO TROLLBACK
	;; CMD TS TSTART
	;; CMD U USE
	;; CMD V VIEW
	;; CMD W WRITE
	;; CMD X XECUTE
	;; CMD ZA ZALLOCATE
	;; CMD ZB ZBREAK
	;; CMD ZCOM ZCOMPILE
	;; CMD ZC ZCONTINUE
	;; CMD ZD ZDEALLOCATE
	;; CMD ZE ZEDIT
	;; CMD ZG ZGOTO
	;; CMD ZH ZHELP
	;; CMD ZK ZKILL
	;; CMD ZL ZLINK
	;; CMD ZM ZMESSAGE
	;; CMD ZP ZPRINT
	;; CMD ZRU ZRUPDATE
	;; CMD ZS ZSHOW
	;; CMD ZST ZSTEP
	;; CMD ZSY ZSYSTEM
	;; CMD ZTC ZTCOMMIT
	;; CMD ZTR ZTRIGGER
	;; CMD ZTS ZTSTART
	;; CMD ZW ZWITHDRAW
	;; CMD ZWR ZWRITE
	;; IFN $A $ASCII
	;; IFN $C $CHAR
	;; IFN $D $DATA
	;; IFN $E $EXTRACT
	;; IFN $F $FIND
	;; IFN $FN $FNUMBER
	;; IFN $G $GET
	;; IFN $I $INCREMENT
	;; IFN $J $JUSTIFY
	;; IFN $L $LENGTH
	;; IFN $N $NAME
	;; IFN $P $PIECE
	;; IFN $QL $QLENGTH
	;; IFN $QS $QSUBSCRIPT
	;; IFN $Q $QUERY
	;; IFN $R $RANDOM
	;; IFN $RE $REVERSE
	;; IFN $S $SELECT
	;; IFN $ST $STACK
	;; IFN $T $TEXT
	;; IFN $TR $TRANSLATE
	;; IFN $V $VIEW
	;; IFN $ZA $ZASCII
	;; IFN $ZC $ZCHAR
	;; IFN $ZCO $ZCONVERT
	;; IFN $ZD $ZDATE
	;; IFN $ZE $ZEXTRACT
	;; IFN $ZF $ZFIND
	;; IFN $ZJ $ZJUSTIFY
	;; IFN $ZL $ZLENGTH
	;; IFN $ZM $ZMESSAGE
	;; IFN $ZPI $ZPIECE
	;; IFN $ZP $ZPREVIOUS
	;; IFN $ZSUB $ZSUBSTR
	;; IFN $ZTR $ZTRANSLATE
	;; IFN $ZW $ZWIDTH
	;; IFN $ZYSU $ZYSUFFIX
	;; IFN $ZBITAND $ZBITAND
	;; IFN $ZBITCOUNT $ZBITCOUNT
	;; IFN $ZBITFIND $ZBITFIND
	;; IFN $ZBITGET $ZBITGET
	;; IFN $ZBITLEN $ZBITLEN
	;; IFN $ZBITNOT $ZBITNOT
	;; IFN $ZBITOR $ZBITOR
	;; IFN $ZBITSET $ZBITSET
	;; IFN $ZBITSTR $ZBITSTR
	;; IFN $ZBITXOR $ZBITXOR
	;; IFN $ZDATA $ZDATA
	;; IFN $ZGETJPI $ZGETJPI
	;; IFN $ZJOBEXAM $ZJOBEXAM
	;; IFN $ZPARSE $ZPARSE
	;; IFN $ZPEEK $ZPEEK
	;; IFN $ZQGBLMOD $ZQGBLMOD
	;; IFN $ZSEARCH $ZSEARCH
	;; IFN $ZSIGPROC $ZSIGPROC
	;; IFN $ZSOCKET $ZSOCKET
	;; IFN $ZSYSLOG $ZSYSLOG
	;; IFN $ZTRIGGER $ZTRIGGER
	;; IFN $ZTRNLNM $ZTRNLNM
	;; IFN $ZSWRITE $ZSWRITE
	;; IFN $ZYHASH $ZYHASH
	;; IFN $ZYISSQLNULL $ZYISSQLNULL
	;; ISV $D $DEVICE
	;; ISV $EC $ECODE
	;; ISV $ES $ESTACK
	;; ISV $ET $ETRAP
	;; ISV $H $HOROLOG
	;; ISV $I $IO
	;; ISV $J $JOB
	;; ISV $K $KEY
	;; ISV $P $PRINCIPAL
	;; ISV $Q $QUIT
	;; ISV $R $REFERENCE
	;; ISV $ST $STACK
	;; ISV $S $STORAGE
	;; ISV $ST $SYSTEM
	;; ISV $T $TEST
	;; ISV $TL $TLEVEL
	;; ISV $TR $TRESTART
	;; ISV $X $X
	;; ISV $Y $Y
	;; ISV $ZA $ZA
	;; ISV $ALLOCSTOR $ALLOCSTOR
	;; ISV $B $ZB
	;; ISV $ZCHSET $ZCHSET
	;; ISV $ZCLOSE $ZCLOSE
	;; ISV $ZCMDLINE $ZCMDLINE
	;; ISV $ZCO $ZCOMPILE
	;; ISV $ZC $ZCSTATUS
	;; ISV $ZDA $ZDATEFORM
	;; ISV $ZD $ZDIRECTORY
	;; ISV $ZED $ZEDITOR
	;; ISV $ZEO $ZEOF
	;; ISV $ZE $ZERROR
	;; ISV $ZG $ZGBLDIR
	;; ISV $ZH $ZHOROLOG
	;; ISV $ZINI $ZININTERRUPT
	;; ISV $ZIO $ZIO
	;; ISV $ZJ $ZJOB
	;; ISV $ZKEY $ZKEY
	;; ISV $ZL $ZLEVEL
	;; ISV $ZMAXTPTI $ZMAXTPTIME
	;; ISV $ZMO $ZMODE
	;; ISV $ZONLNRLBK $ZONLNRLBK 
	;; ISV $ZPATN $ZPATNUMERIC
	;; ISV $ZPIN $ZPIN
	;; ISV $ZPOS $ZPOSITION
	;; ISV $ZPOUT $ZPOUT
	;; ISV $ZPROM $ZPROMPT
	;; ISV $ZQUIT $ZQUIT
	;; ISV $REALSTOR $ZREALSTOR
	;; ISV $ZRELDATE $ZRELDATE
	;; ISV $ZROU $ZROUTINES
	;; ISV $ZSO $ZSOURCE
	;; ISV $ZS $ZSTATUS
	;; ISV $ZST $ZSTEP
	;; ISV $ZSTRP $ZSTRPLLIM
	;; ISV $ZST $ZSYSTEM
	;; ISV $ZTE $ZTEXIT
	;; ISV $ZTIM $ZTIMEOUT
	;; ISV $T $ZTRAP
	;; ISV $ZUSEDSTOR $ZUSEDSTOR
	;; ISV $ZUT $ZUT
	;; ISV $ZV $ZVERSION
	;; ISV $ZYER $ZYERROR
	;; ISV $ZYINTRSIG $ZYINTRSIG
	;; ISV $ZYRE $ZYRELEASE
	;; ISV $ZYSQLNULL $ZYSQLNULL
	;; ISV $ZTDATA $ZTDATA
	;; ISV $ZTDELIM $ZTDELIM
	;; ISV $ZTLEVEL $ZTLEVEL
	;; ISV $ZTNAME $ZTNAME
	;; ISV $ZTRIGGEROP $ZTRIGGEROP
	;; ISV $ZTSLATE $ZTSLATE
	;; ISV $ZTVALUE $ZTVALUE
	;; ISV $ZTWORMHOLE $ZTWORMHOLE
