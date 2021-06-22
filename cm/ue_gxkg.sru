long llRowCount
long i,lsRwsl
string lsGxsh,lsCpbh,lsKgry,lsXdpgbz
//string lsKgrqsj // 开工日期时间
string lsSql,lsErr
nvo_select lnv_select
string lsJhls
string lsSfsd,lsSfll //是否首道工序，是否领料
string lsGxzt
long llcount
long llcountNum //用来统计不是派工下达状态的数量
long llcountNum2 //用来统计不是首道工序开工的数量
String lsLch // 炉次号

gf_sethelp("正在进行开工处理.......")
llcountNum = 0
llcountNum2 = 0
llRowCount = dw_detail2.rowcount()
lsJhls = dw_detail2.getitemstring(i,"cmsczjhrw_jhls")


// 首先清空一下临时表，务必清空，否则会将很多标志打错
lsSql = "truncate table "+isScrwTempTable
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	return -1
end if

for i = 1 to llRowCount
	lsCpbh = dw_detail2.getitemstring(i,"cmsczjhrw_cpbh")
	lsGxsh = dw_detail2.getitemstring(i,"cmsczjhrw_gxsh")
	lsXdpgbz = dw_detail2.getitemstring(i,"cmsczjhrw_sfxd")
	lsJhls = dw_detail2.getitemstring(i,"cmsczjhrw_jhls")
	lsLch = dw_detail2.getitemstring(i,"cmsczjhrw_scpc") // 炉次号
	// 只有工序下达状态的工序才能进行开工操作 G7为派工下达
	Select CMCJSCRWGY_GXZT Into :lsGxzt
		From CMCJSCRWGY
		Where CMCJSCRWGY_CPBH = :lsCpbh and CMCJSCRWGY_GXSH = :lsGxsh;
	//	If lsGxzt <> "G7" Then
	//		MessageBox("提示信息","产品["+lsCpbh+"]不是派工下达状态，不能开工！")
	//		Continue
	//	End If
	if lsGxzt <> "G7" then
		llcountNum++
	end if
	
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
	if trim(lsXdpgbz) = "1" then
		lsSql = "insert into "+isScrwTempTable+&
			" (F_CPBH,F_GXSH)"+&
			" values "+&
			"('"+lsCpbh+"','"+lsGxsh+"')"
		if gfexesql(lsSql,sqlca) < 0 then
			lsErr = sqlca.sqlerrtext
			Rollback;
			messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
			gf_closehelp()
			return -1
		end if
	end if
	llcount++
next

// 不是派工下达状态的数量
if llcountNum > 0 then
	messagebox("提示信息","产品不是派工下达状态，不能开工！")
	gf_closehelp()
	return -1
end if

// 不是首道工序开工的数量
if llcountNum2 > 0 then
	messagebox("提示信息","产品首道工序必须领料并审批通过才能开工！")
	gf_closehelp()
	return -1
end if

// 动态SQL取临时表数据。
lsSql = "Select count(1) from CMCJSCRWGY,"+isScrwTempTable+&
	" where CMCJSCRWGY_CPBH = "+isScrwTempTable+".F_CPBH "+&
	" and CMCJSCRWGY_GXSH ="+isScrwTempTable+".F_GXSH "+&
	" and CMCJSCRWGY_GXZT = 'G7'"
lnv_select.of_select( lsSql,lsRwsl,lsErr)
if lsRwsl < 1 then
	gf_closehelp()
	return 1
end if

lsSql = "update CMCJSCRWGY "+&
	" set CMCJSCRWGY_GXZT ='G1',"+&
	" CMCJSCRWGY_KGRY = '"+GsUserName+"',"+&
	" CMCJSCRWGY_KGRQ = '"+Gscwrq+"' "+&
	" from "+isScrwTempTable+&
	" where CMCJSCRWGY_CPBH = "+isScrwTempTable+".F_CPBH "+&
	" and CMCJSCRWGY_GXSH ="+isScrwTempTable+".F_GXSH "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	return -1
end if

// 更新产品任务执行状态。
lsSql = "update CMSCZJHRW set CMSCZJHRW_CPRWZXZT ='1' "+&
	" from "+isScrwTempTable+&
	" where CMSCZJHRW_CPBH = "+isScrwTempTable+".F_CPBH "+&
	" and CMSCZJHRW_GXSH ="+isScrwTempTable+".F_GXSH "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	return -1
end if

// 更新生产炉次的实际开工日期、时间
string lsSjkgrq,lsSjkgsj // 实际开工日期、实际开工时间
string lsSjKgrqsj // 实际开工日期时间
lsSjKgrqsj = gfgetservertime()

lsSjkgrq = left(lsSjKgrqsj,8)
lsSjkgsj = right(lsSjKgrqsj,6)


lsSql = "update CMSCLCXX "+&
	" set CMSCLCXX_SJKGRQ='"+lsSjkgrq+"',CMSCLCXX_SJKGSJ='"+lsSjkgsj+"' "+&
	" where CMSCLCXX_LCH='"+lsLch+"' "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新生产炉次实际开工日期、时间出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	return -1
end if



Commit;

dw_master.retrieve(lsJhls)
dw_detail.retrieve(lsJhls)
dw_detail2.retrieve(lsJhls)
if llcount <> 0 then
	messagebox("提示信息","已开工！")
end if

gf_closehelp()

return  1

