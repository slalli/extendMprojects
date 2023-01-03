	; extendMprojects
	; version 1.0.0
extendMprojects quit
; ****************************************	
; start(sourceDir,action) 
; sourceDir		directory where the .m files are
; action		defaults to RR. Action can be: RR (replace and rename), RE (replace), NE (new name: original name + '.extended')
; ****************************************	
start(sourceDir,action) 
	write !!,"**********************************"
	write !,"Extend M project "_$piece($text(+2)," ",3,4)
	write !,"**********************************"
	;
	; Validate path
	if $get(sourceDir)="" do  quit
	. write !!,"No source file was specified...",!!,"Quitting"
	;
	if $zsearch(sourceDir)="" do  quit
	. write !!,"File not found...",!!,"Quitting"
	;
	write !!
	;
	new file,files,replaceType,cnt,inputStr,defs,line
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
	write !!,"Files found in "_sourceDir_": "_files
	;
	; Prompt for conversion type: upper case or lower case
askAgainType
	read !!,"How do you want to convert ? (U)pper case, (L)ower case, (Q)uit ",inputStr
	set inputStr=$$FUNC^%UCASE(inputStr)
	if inputStr="Q" do  quit
	. write !!,"Bye bye",!!
	if inputStr="U"!(inputStr="L") set replaceType=inputStr
	else  goto askAgainType
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
	for  set cnt=cnt+1,line=$text(+cnt) quit:line=""  do:$find(line,";;")
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
	new bufferAfter,cnt,line,cmd,lastPos,foundPos,match,newLine
	;
	set cnt=0
	for  set cnt=$order(buffer(cnt)) quit:cnt=""  do
	. set line=buffer(cnt)
	. write !,">>>",line
	. ; begin with commands
	. set (cmd,newLine)=""
	. for  set cmd=$order(defs("CMD",cmd)) quit:cmd=""  do
	. . set foundPos=0,lastPos=1,match=""
	. . for  set foundPos=$find(line,cmd,lastPos) quit:foundPos=0  do
	. . . write !,"foundPos:",foundPos
	. . . set match=$extract(line,foundPos-1)
	. . . write !,"match: "_match
	. . . ; is next char either a space/tab or a : AND (is it first char OR prev char is space/tab)
	. . . if $extract(line,foundPos)=" "!($extract(line,foundPos)=$char(9))!($extract(line,foundPos)=":"),lastPos=2!($extract(line,foundPos-2)=" ")!($extract(line,foundPos-2)=$char(9)) do
	. . . . ; Replace
	. . . . write !,"...replacing"
	. . . . set newLine=newLine_$extract(line,lastPos,foundPos-2)_defs("CMD",cmd)
	. . . . set line=$extract(line,foundPos,$length(line))
	. . . . write !,"...",newLine
	. . . ;
	. . . set lastPos=foundPos
	. ;
	. if newLine="" set newLine=line
	. if $length(line)'=$length(newLine) set newLine=newLine_$extract(line,foundPos,$length(line))
	. set bufferAfter(cnt)=newLine
	;	
	quit *bufferAfter
	;
	;
	;
	; DEFINITIONS
	;; CMD B BREAK
	;; CMD C CLOSE
	;; CMD S SET
	;; CMD W WRITE
	;; IFN A ASCII
	;; IFN C CHAR
	;; ISV D DEVICE
	;; ISV EC ECODE
	;
	;
	;
