TEST
    s a=0,c=20 w "test"
   w "test"
   w $a(23),$a(44)
   ZWR TEST
  CLOSE s
  s:c d=0
; comment
    c s

PROCESS(SMSG,NOTIMEOUT,NOGC)
	;SMSG  :BYREF socket message JDOM
	;
	N RET,CMD,PAR,IX,STR,CNT,%jhTIMINGS
	N RPLC,%jhGNAME,%jhSELECT,%jhORDERBY,%jhLIMIT,%jhWHERE,%jhUPDATE,%jhDELETE
	;
	S %jhTIMINGS("START")=$ZUT
	S NOTIMEOUT=$G(NOTIMEOUT,0)
	S NOGC=$G(NOGC,0)
	;
	S CNT=0
	;Process separators
	S CMD=$G(SMSG("command")),CMD=$TR($TR($TR(CMD,$C(13)," "),$C(10)," "),$C(9)," ")
	;Process comma separated fields
	S RPLC(",")=", ",RPLC("', ")="',",RPLC(""" ")=""","
	S CMD=$$strREPLACE^%jhUTILS(CMD,.RPLC)
	;Split command
	F IX=1:1:$L(CMD," ") S STR=$P(CMD," ",IX) S:STR'="" CNT=CNT+1,SMSG("command","as",CNT)=STR,SMSG("command",CNT)=$$strTOupper^%jhUTILS(STR)
	;
	S CMD=$G(SMSG("command",1)),PAR=$G(SMSG("command",2))
	I CMD="" D ERRandQUIT^%jhERROR(200001) G PROCESSQ
	;
	;SYSLOG
	I CMD'="INSERT",PAR'="SYSLOG",$F($$strTOupper^%jhUTILS($G(SMSG("command"))),"SYSLOG.SL.1")=0 D ADD^%jhSYSLOG("EXE",$G(SMSG("command")))
	;
	;Parse out
	I CMD="LOGIN" D  G PROCESSQ
	. I PAR'="" D ERRandQUIT^%jhERROR(200004,SMSG("command","as",2)) Q
	. N RES
	. M RES("user")=%jhUSER
	. D OKheader^%jhRESPONSE(.RES)
	. D BUILDsimple^%jhRESPONSE(.RES)
	. ;SYSLOG
	. D ADD^%jhSYSLOG("EOK",$G(SMSG("command")))
	;
	I CMD="CREATE" D  G PROCESSQ
	. I PAR="DATABASE" D CREATEdb^%jhCMDdb(.SMSG) Q
	. I PAR="HIVE" D CREATEhive^%jhCMDdb(.SMSG) Q
	. I PAR="REGION"
	. I PAR="INDEX" D CREATEindex^%jhCMDdb(.SMSG) Q
	. I PAR="USER" D CREATEuser^%jhCMDusers(.SMSG) Q
	. I PAR="USERGROUP" D CREATEusergroup^%jhCMDusers(.SMSG) Q
	. I PAR="TASK" D CREATEtask^%jhCMDschedule(.SMSG) Q
	. ;
	. D ERRandQUIT^%jhERROR(200003,SMSG("command","as",2))
	;

