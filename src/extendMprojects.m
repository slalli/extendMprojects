	; extendMprojects
	; version 0.0.1
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
 	if $get(sourceDir)="" do  quit
 	. write !!,"No source file was specified...",!!,"Quitting"
 	;
 	if $zsearch(sourceDir)="" do  quit
 	. write !!,"File not found...",!!,"Quitting"
 	;
 	if $get(action)="" set action="NE"
	
 	new replaceType
 	;
