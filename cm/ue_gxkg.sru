long llRowCount
long i,lsRwsl
string lsGxsh,lsCpbh,lsKgry,lsKgrq,lsXdpgbz
string lsSql,lsErr
nvo_select lnv_select
string lsJhls
string lsSfsd,lsSfll //是否首道工序，是否领料
string lsGxzt
long llcount
long llcountNum //用来统计不是派工下达状态的数量
long llcountNum2 //用来统计不是首道工序开工的数量

gf_sethelp("正在进行开工处理.......")
llcountNum = 0
llcountNum2 = 0
llRowCount = dw_detail2.rowcount()
lsJhls = dw_detail2.getitemstring(i,"cmsczjhrw_jhls")
lsKgrq = gfgetservertime()

// 首先清空一下临时表，务必清空，否则会将很多标志打错
lsSql = "truncate table "+isScrwTempTable
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

For i = 1 to llRowCount
	lsCpbh = dw_detail2.getitemstring(i,"cmsczjhrw_cpbh")
	lsGxsh = dw_detail2.getitemstring(i,"cmsczjhrw_gxsh")
	lsXdpgbz = dw_detail2.getitemstring(i,"cmsczjhrw_sfxd")
	lsJhls = dw_detail2.getitemstring(i,"cmsczjhrw_jhls")
	// 只有工序下达状态的工序才能进行开工操作 G7为派工下达
	Select CMCJSCRWGY_GXZT Into :lsGxzt
		From CMCJSCRWGY
		Where CMCJSCRWGY_CPBH = :lsCpbh and CMCJSCRWGY_GXSH = :lsGxsh;
	//	If lsGxzt <> "G7" Then
	//		MessageBox("提示信息","产品["+lsCpbh+"]不是派工下达状态，不能开工！")
	//		Continue
	//	End If
	If lsGxzt <> "G7" Then
		llcountNum++
	End If
	
	lsGxzt = ""
	// //首道工序必须领料才可以开工
	//	Select 'Exist' Into :lsSfsd
	//		From CMCJSCRWGY
	//		where CMCJSCRWGY_GXSH = :lsGxsh
	//		And CMCJSCRWGY_CPBH = :lsCpbh
	//		and CMCJSCRWGY_SFSDGX = '1';
	//	//	select 'Exist' into :lsSfll
	//	//	from CMCJSCRWCP
	//	//	where CMCJSCRWCP_CPBH= :lsCpbh and CMCJSCRWCP_SFLL= '1';
	//	Select 'Exist' Into :lsSfll
	//		From CMCJSCRWCP,KCCKD1
	//		where CMCJSCRWCP_SCCKDLSBH = KCCKD1_LSBH
	//		and CMCJSCRWCP_CPBH = :lsCpbh and CMCJSCRWCP_SFLL = '1' and KCCKD1_SHBZ = '1';
	//		//生产任务表判断是否领料。
	////	Select 'Exist' Into :lsSfll
	////		From CMSCRW,KCCKD1
	////		where CMSCRW_SCCKDLSBH = KCCKD1_LSBH
	////		and CMSCRW_CPBH = :lsCpbh and CMSCRW_SFLL = '1' and KCCKD1_SHBZ = '1';
	//	//	If Trim(lsSfsd) = 'Exist' then
	//	//		If Trim(lsSfll) <> 'Exist' Then
	//	//			MessageBox("提示信息","产品["+lsCpbh+"]首道工序必须领料才能开工！")
	//	//			continue
	//	//		End If
	//	//	End If
	//	If trim(lsSfsd) = 'Exist' Then
	//		If trim(lsSfll) <> 'Exist' Then
	//			llcountNum2++
	//		End If
	//	End If
	//	lsSfsd = ""
	//	lsSfll = ""
	If trim(lsXdpgbz) = "1" Then
		lsSql = "insert into "+isScrwTempTable+&
			" (F_CPBH,F_GXSH)"+&
			" values "+&
			"('"+lsCpbh+"','"+lsGxsh+"')"
		If gfexesql(lsSql,sqlca) < 0 Then
			lsErr = sqlca.sqlerrtext
			Rollback;
			messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
			gf_closehelp()
			Return -1
		End If
	End If
	llcount++
Next

// 不是派工下达状态的数量
If llcountNum > 0 Then
	messagebox("提示信息","产品不是派工下达状态，不能开工！")
	gf_closehelp()
	Return -1
End If

// 不是首道工序开工的数量
If llcountNum2 > 0 Then
	messagebox("提示信息","产品首道工序必须领料并审批通过才能开工！")
	gf_closehelp()
	Return -1
End If

// 动态SQL取临时表数据。
lsSql = "Select count(1) from CMCJSCRWGY,"+isScrwTempTable+&
	" where CMCJSCRWGY_CPBH = "+isScrwTempTable+".F_CPBH "+&
	" and CMCJSCRWGY_GXSH ="+isScrwTempTable+".F_GXSH "+&
	" and CMCJSCRWGY_GXZT = 'G7'"
lnv_select.of_select( lsSql,lsRwsl,lsErr)
If lsRwsl < 1 Then
	gf_closehelp()
	Return 1
End If

lsSql = "update CMCJSCRWGY "+&
	" set CMCJSCRWGY_GXZT ='G1',"+&
	" CMCJSCRWGY_KGRY = '"+GsUserName+"',"+&
	" CMCJSCRWGY_KGRQ = '"+Gscwrq+"' "+&
	" from "+isScrwTempTable+&
	" where CMCJSCRWGY_CPBH = "+isScrwTempTable+".F_CPBH "+&
	" and CMCJSCRWGY_GXSH ="+isScrwTempTable+".F_GXSH "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 更新产品任务执行状态。
lsSql = "update CMSCZJHRW set CMSCZJHRW_CPRWZXZT ='1' "+&
	" from "+isScrwTempTable+&
	" where CMSCZJHRW_CPBH = "+isScrwTempTable+".F_CPBH "+&
	" and CMSCZJHRW_GXSH ="+isScrwTempTable+".F_GXSH "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

Commit;

dw_master.retrieve(lsJhls)
dw_detail.retrieve(lsJhls)
dw_detail2.retrieve(lsJhls)
If llcount <> 0 Then
	messagebox("提示信息","已开工！")
End If

gf_closehelp()

Return  1
