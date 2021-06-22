// 将当前界面的所有数据存入待完工临时表中
// 然后利用临时表进行实表数据的更新
long llRowcount
long i,j = 1
string lsRwbh,lsFlbhTemp
string lsCol
string lsGxzt,lsCpbh,lsGxsh
string lsSql,lsErr,lsErrCpbh
string lsSfcj // 是否裁剪
//string lsKgrq
string lsgzzx
string lsjhls,lsjhfl
string lsScpc // 炉次号

gf_sethelp("正在进行完工处理......")
//lsKgrq = gfgetservertime()
llRowcount = dw_cpgxxx.rowcount( )
If llRowcount < 1 Then
	gf_closehelp()
	Return -1
End If

// 清空临时表
lsSql =  "truncate table " + isCmDwgrw
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 判断前道工序的状态，必须是已经开工了的工序才允许完工
// 前道工序为未裁剪的最大工序顺号的工序
For i = 1 to llRowcount
	lsCpbh = dw_cpgxxx.getitemstring(i,"f_cpbh")
	lsGxsh = dw_cpgxxx.getitemstring(i,"f_gxsh")
	lsGxzt = dw_cpgxxx.getitemstring(i,"f_gxzt")
	lsgzzx = dw_cpgxxx.getitemstring(i,"f_gzzx")
	lsScpc = dw_cpgxxx.getitemstring(i,"f_scpc")
	//	lsFlbh = dw_cpgxxx.Getitemstring(i,"f_flbh")
	
	// 没获取到工序状态的不处理
	If isnull(lsGxzt) or trim(lsGxzt) = "" Then
		lsGxzt = ""
		Continue
	End If
	
	// // 已经完工的不能继续完工
	//	If lsGxzt = "G2" Then
	//		Continue
	//	End If
	
	// 只有开工状态的工序才能进行完工操作 G1为已开工
	If lsGxzt <> "G1" Then
		Continue
	End If
	
	//	Select CMSCZJHRW_JHLS,CMSCZJHRW_JHFL Into :lsjhls,:lsjhfl
	//		From CMSCZJHRW
	//		Where CMSCZJHRW_CPBH = :lsCpbh
	//		and CMSCZJHRW_GXSH = :lsGxsh;
	
	// 待完工数据插入到临时表中
	//	lsSql = "insert into "+isCmDwgrw+"(F_CPBH,F_GXSH,F_JHLS,F_JHFL,F_GZZX,F_FLAG)"+&
	//		" values('"+lsCpbh+"','"+lsGxsh+"','"+lsjhls+"','"+lsjhfl+"','"+lsgzzx+"','0')"
	lsSql = "insert into "+isCmDwgrw+"(F_CPBH,F_GXSH,F_JHLS,F_JHFL,F_GZZX,F_SCPC,F_FLAG)"+&
		" values('"+lsCpbh+"','"+lsGxsh+"','','','"+lsgzzx+"','"+lsScpc+"','0')"
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","待完工数据归集出错！"+lsErr+"~r~n"+ lsSql)
		Continue
	End If
Next

// 考虑判断是否归集到数据，待完善


//  更新车间生产任务工艺的工序状态为完工状态
lsSql = "update CMCJSCRWGY set CMCJSCRWGY.CMCJSCRWGY_GXZT='G2',CMCJSCRWGY.CMCJSCRWGY_WGRY='"+GsUserName+"',"+&
	"CMCJSCRWGY.CMCJSCRWGY_WGRQ='"+GsCwrq+"' "+&
	" from "+isCmDwgrw+&
	" where CMCJSCRWGY.CMCJSCRWGY_CPBH= "+isCmDwgrw+".F_CPBH "+&
	" and CMCJSCRWGY.CMCJSCRWGY_GXSH= "+isCmDwgrw+".F_GXSH and "+isCmDwgrw+".F_FLAG='0' "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 生产周计划任务的状态更新
lsSql = " update CMSCZJHRW set "+&
	" CMSCZJHRW.CMSCZJHRW_CPRWZXZT = '2' "+&
	" from "+isCmDwgrw+&
	" where CMSCZJHRW.CMSCZJHRW_CPBH = "+isCmDwgrw+".F_CPBH "+&
	" and CMSCZJHRW.CMSCZJHRW_GXSH = "+isCmDwgrw+".F_GXSH and "+isCmDwgrw+".F_FLAG='0' "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生产周计划任务的状态更新出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 更新工作中心的状态及完工时间清空，考虑所有的件
// 已经有了产品编号、工序顺号就可唯一确定一条CMSCZJHRW，
// 然后可以联查CMSCZJHMX (工作中心、完工时间)

// 计划流水、计划分录更新到临时表中便于后续操作
lsSql = "update "+isCmDwgrw+&
	" set "+isCmDwgrw+".F_JHLS=CMSCZJHRW.CMSCZJHRW_JHLS,"+isCmDwgrw+".F_JHFL=CMSCZJHRW.CMSCZJHRW_JHFL"+&
	" from CMSCZJHRW "+&
	" where "+isCmDwgrw+".F_CPBH=CMSCZJHRW.CMSCZJHRW_CPBH and "+isCmDwgrw+".F_GXSH=CMSCZJHRW.CMSCZJHRW_GXSH and "+isCmDwgrw+".F_FLAG='0' "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","待完工数据处理出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If
//////////////////
////// 这里只是确定一下计划流水和计划分录，通过flag = 1 来标识
//////
//////////////////////////
// 处理临时表，
// 按照计划流水、计划分录group by 便于更新CMSCZJHMX的状态 标志为1
lsSql =  "insert into "+isCmDwgrw+"(F_CPBH,F_GXSH,F_JHLS,F_JHFL,F_GZZX,F_FLAG)"+&
	" select max(F_CPBH),max(F_GXSH),F_JHLS,F_JHFL,max(F_GZZX),'1' "+&
	" from "+isCmDwgrw+&
	" group by "+isCmDwgrw+".F_JHLS,"+isCmDwgrw+".F_JHFL"

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","临时表数据处理出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 按照工作中心归集，便于更新JSGZZX 设备的状态 标志为2
lsSql =  "insert into "+isCmDwgrw+"(F_CPBH,F_GXSH,F_JHLS,F_JHFL,F_GZZX,F_FLAG)"+&
	" select max(F_CPBH),max(F_GXSH),max(F_JHLS),max(F_JHFL),F_GZZX,'2' "+&
	" from "+isCmDwgrw+&
	" group by "+isCmDwgrw+".F_GZZX "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","临时表数据处理出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 更新周计划明细的状态，周计划明细下的所有的件都完工的情况下才是整体的完工状态
// 即不存在未完工的下级
lsSql = "update CMSCZJHMX set CMSCZJHMX.CMSCZJHMX_ZXZT='2' "+&
	" from "+isCmDwgrw+&
	" where CMSCZJHMX.CMSCZJHMX_JHLS= "+isCmDwgrw+".F_JHLS "+&
	" and CMSCZJHMX.CMSCZJHMX_JHFL="+isCmDwgrw+".F_JHFL and "+isCmDwgrw+".F_FLAG='1' "+&
	" and not exists(select 1 from  CMSCZJHRW "+&
	" where CMSCZJHRW.CMSCZJHRW_JHLS=CMSCZJHMX.CMSCZJHMX_JHLS "+&
	" and CMSCZJHRW.CMSCZJHRW_JHFL=CMSCZJHMX.CMSCZJHMX_JHFL "+&
	" and CMSCZJHRW.CMSCZJHRW_CPRWZXZT <> '2' )"

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新周计划完工状态失败！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 临时表字段 产品编号、工序顺号，工作中心、完工时间 四个字段
//	// 更新JSGZZX 表 JSGZZX_WGRQ、设备状态字段
//	lsSql = " update JSGZZX set "+&
//		" JSGZZX_WGRQ = null and JSGZZX_SBZT='0' "+&
//		" where JSGZZX_ZXBH = '"+lsgzzx+"' "
//	
//	If gfexesql(lsSql,sqlca) < 0 Then
//		lsErr = sqlca.sqlerrtext
//		Rollback;
//		messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
//	End If

// 更新设备的状态为空闲，更新完工日期为空
// 所有的周计划都是完工状态说明才是空闲状态，即不存在未完工状态的
lsSql = "update JSGZZX set JSGZZX.JSGZZX_SBZT='0',JSGZZX.JSGZZX_WGRQ='' "+&
	" from "+isCmDwgrw+&
	" where JSGZZX.JSGZZX_ZXBH="+isCmDwgrw+".F_GZZX and "+isCmDwgrw+".F_FLAG='1' "+&
	" and not exists(select 1 from CMSCZJHMX where CMSCZJHMX_ZXZT<>'2')"

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工作中心状态失败！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If


// 更新生产炉次的实际完工日期、时间
string lsSjWgrq,lsSjWgsj // 实际完工日期、实际完工时间
string lsSjWgrqsj // 实际完工日期时间
lsSjWgrqsj = gfgetservertime()

lsSjWgrq = left(lsSjWgrqsj,8)
lsSjWgsj = right(lsSjWgrqsj,6)

lsSql = "update CMSCLCXX "+&
	" set CMSCLCXX_SJWGRQ='"+lsSjWgrq+"',CMSCLCXX_SJWGSJ='"+lsSjWgsj+"' "+&
	" from "+isCmDwgrw+" A "+&
	" where CMSCLCXX.CMSCLCXX_LCH=A.F_SCPC "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新生产炉次实际完工日期、时间出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	return -1
end if

// 提交数据库
Commit;

// 循环赋值
// 界面状态更新
For i = 1 to llRowcount
	dw_cpgxxx.setitem( i,"f_gxzt","G2")
Next

messagebox("提示信息","完工完成！")
gf_closehelp()

Return 1
