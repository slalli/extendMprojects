	; extendMprojects
	; version 1.0.0
extendMprojects quit
; ****************************************	
; start(sourceDir,action) 
; sourceDir		directory where the .m files are
; action		defaults to RR. Action can be: RR (replace and rename), RE (replace), NE (new name: original name + '.extended')
; ****************************************	
start(sourceDir) 
	write !!,"**********************************"
	write !,"Extend M project "_$piece($text(+2)," ",3,4)
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
	new bufferIn,bufferOut
	;
	; Check # of files in dir
	if $extract(sourceDir,$length(sourceDir))'="/" set sourceDir=sourceDir_"/"
	set cnt=0
	for  set file=$zsearch(sourceDir_"*.m") quit:file=""  set files(file)="",cnt=cnt+1
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
	read !!,"How do you want to convert the left margin ? (A)s it is, (1) space, (4) spaces, (Q)uit ",inputStr
	set inputStr=$$FUNC^%UCASE(inputStr)
	if inputStr="Q" do  quit
	. write !!,"Bye bye",!!
	if inputStr="A"!(inputStr="1")!(inputStr="4") set marginType=$select(inputStr="A":0,1:+inputStr)
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
	; Populate the definition table according to the replaceType
	set cnt=0
	for  set cnt=cnt+1,line=$text(+cnt) w !,"line:",line quit:line=""  do:$find(line,";;")
	. set type=$piece(line," ",3),from=$piece(line," ",4),to=$piece(line," ",5)
	. set:type'="" defs(type,from)=$select(replaceType="L":$$FUNC^%LCASE(to),replaceType="U":$$FUNC^%UCASE(to),1:to)
	. set:type'="" defs(type,$$FUNC^%LCASE(from))=$select(replaceType="L":$$FUNC^%LCASE(to),replaceType="U":$$FUNC^%UCASE(to),1:to)
	;
	write !!,cnt,!
	zwr defs
	write !
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
	. u $p
	. close file
	. ;
	. ; Process it
	. set *bufferOut=$$extendFile(.bufferIn,.defs)
	. ;
	. ;
	. ; Save it
	. zwr bufferOut
	;
	;
	;
	quit
	;
	;
extendFile(buffer,defs)
	new bufferAfter,cnt,line,cmd,lastPos,foundPos,match,newLine,newLine2
	new charCnt,char,charQuit,ifn
	;
	set cnt=0
	for  set cnt=$order(buffer(cnt)) quit:cnt=""  do
	. set line=buffer(cnt)
	. ; -------------------------
	. ; left margin
	. ; -------------------------
	. if marginType>0 do
	. . if $extract(line,1,1)'=" ",$extract(line,1,1)'=$char(9) quit
	. . set charQuit=0
	. . for charCnt=1:1:$length(line) do  quit:charQuit
	. . . set char=$extract(line,charCnt,charCnt)
	. . . if char'=" ",char'=$char(9) set charQuit=charCnt
	. . set line=$select(marginType=1:" ",marginType=4:"    ",1:" ")_$extract(line,charQuit,$length(line))
	. ; -------------------------
	. ; commands
	. ; -------------------------
	. set (cmd,newLine)=""
	. for  set cmd=$order(defs("CMD",cmd)) quit:cmd=""  do
	. . set foundPos=0,lastPos=1,match=""
	. . for  set foundPos=$find(line,cmd_" ",lastPos) quit:foundPos=0  do
	. . . set match=$extract(line,foundPos-2)
	. . . WRITE !,"*MATCH:",match
	. . . ; is next char either a space/tab or a : AND (is it first char OR prev char is space/tab)
	. . . if $extract(line,foundPos-1)=" "!($extract(line,foundPos-1)=$char(9))!($extract(line,foundPos-1)=":"),lastPos=2!($extract(line,foundPos-3)=" ")!($extract(line,foundPos-3)=$char(9)) do
	. . . . ; Replace
	. . . . set newLine=newLine_$extract(line,lastPos,foundPos-3)_defs("CMD",cmd)_" "
	. . . . set line=$extract(line,foundPos,$length(line))
	. . . ;
	. . . set lastPos=foundPos
	. ;
	. if newLine="" set newLine=line
	. else  if $length(line)'=$length(newLine) set newLine=newLine_$extract(line,foundPos,$length(line))
	. ;
	. set bufferAfter(cnt)=newLine
	;	
	quit *bufferAfter
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
	;; IFN A ASCII
	;; IFN C CHAR
	;; ISV D DEVICE
	;; ISV EC ECODE
	;
