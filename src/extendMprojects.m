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
 	;
	; Check # of files in dir
	if $extract(sourceDir,$length(sourceDir))'="/" set sourceDir=sourceDir_"/"
	set cnt=0
	for  set file=$zsearch(sourceDir_"*.m") quit:file=""  set files(file)="",cnt=cnt+1
	set files=cnt
	;
	if $data(files)=0 do
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
	; ----------------------------------------------
	; We can start the conversion
	; ----------------------------------------------
	;	
	; Populate the definition table
	set cnt=0
	for  set cnt=cnt+1,line=$text(+cnt) quit:line=""  do:$find(line,";;")
	. set type=$piece(line," ",3),from=$piece(line," ",4),to=$piece(line," ",5)
	. set:type'="" defs(type,from)=$select(replaceType="L":$$FUNC^%LCASE(to),replaceType="U":$$FUNC^%UCASE(to),1:to)
	;
	write !!,cnt,!
	zwr defs
	;
	; DEFINITIONS
	;; CMD B BREAK
	;; CMD C CLOSE
	;; IFN A ASCII
	;; IFN C CHAR
	;; ISV D DEVICE
	;; ISV EC ECODE
