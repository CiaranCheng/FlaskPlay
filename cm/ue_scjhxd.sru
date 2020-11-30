// 归集需要下达的数据
string lsSql,lsErr
long liCount
integer i,m,n
string lsJhls,lsJhfl // 计划流水、计划分录
string lsGzzx,lsWlbh,lsScpc // 工作中心、无聊编号、生产批次
string lsKsrq,lsJsrq // 开始日期、结束日期
string lsXdbz,lsZxzt // 下达标志，计划执行状态
string lsJhbh // 计划编号
long lsCjpgdRwsl // 车间派工单任务数量

gf_sethelp("正在进行下达处理......")

// 必须保存后才能下达。
If  isDjModel = "MODIFY" Then
	messagebox("提示信息","请先保存再进行下达！")
	gf_closehelp()
	Return 1
End If

// 看是否有需要进行入库的数据
If dw_detail.rowcount() < 1 Then
	messagebox("提示信息","没有进行下达的数据！")
	gf_closehelp()
	Return -1
End If

// 清空一下临时表
lsSql = "truncate table " + isSelTempTable
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 循环数据窗口将选择的数据存入临时表中，便于后续操作
liCount = 0
m = 0
n = 0
lsJhbh = dw_master.getitemstring(dw_master.getrow(),"cmsczjh_jhbh")
For i = 1 to dw_detail.rowcount( )
	
	lsJhls = dw_detail.getitemstring(i,"cmsczjhmx_jhls")
	lsJhfl = dw_detail.getitemstring(i,"cmsczjhmx_jhfl")
	lsGzzx = dw_detail.getitemstring(i,"cmsczjhmx_gzzx")
	lsWlbh = dw_detail.getitemstring(i,"cmsczjhmx_wlbh")
	lsScpc = dw_detail.getitemstring(i,"cmsczjhmx_scpc")
	lsKsrq = dw_detail.getitemstring(i,"cmsczjhmx_ksrq")
	lsJsrq = dw_detail.getitemstring(i,"cmsczjhmx_jsrq")
	lsXdbz = dw_detail.getitemstring(i,"cmsczjhmx_xdbz")
	lsZxzt = dw_detail.getitemstring(i,"cmsczjhmx_zxzt")
	
	If lsXdbz = "1" Then
		m++
		//messagebox("提示信息","派工单（"+lsJhbh+"）已经下达过，不允许重复下达！")
		Continue
	End If
	
	Select count(1) Into :lsCjpgdRwsl
		From CMSCZJHRW
		Where CMSCZJHRW_JHLS = :lsJhls
		and CMSCZJHRW_JHFL = :lsJhfl;
	If isnull(lsCjpgdRwsl) or lsCjpgdRwsl < 1 Then
		n++
		//		messagebox("提示信息","派工单（"+lsJhbh+"）未指派任务，不允许下达！")
		Continue
	End If
	// 将产品编号记录到临时表中
	lsSql =  " insert into "+isSelTempTable+"(F_JHLS,F_JHBH,F_JHFL,F_GZZX,F_WLBH,F_SCPC,F_KSRQ,F_JSRQ,F_XDBZ,F_ZXZT) "+&
		" values('"+lsJhls+"','"+lsJhbh+"','"+lsJhfl+"','"+lsGzzx+"','"+lsWlbh+"','"+lsScpc+"','"+lsKsrq+"','"+lsJsrq+"','"+lsXdbz+"','"+lsZxzt+"') "
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
		gf_closehelp()
		Return -1
	End If
	liCount++
Next

//f_test(isSelTempTable,"d:\111.xls",sqlca)
If liCount < 1 Then
	messagebox("提示消息","请选择需要进行下达的生产计划！")
	gf_closehelp()
	Return -1
End If

// 下达生成超码车间生产任务
If uf_create_cmcjscrw() < 0 Then
	messagebox("提示信息","生成车间生产任务失败！")
	gf_closehelp()
	Return -1
End If

// 更新明细表下达标志，使用临时表
lsSql = "update CMSCZJHMX set CMSCZJHMX_XDBZ='1',CMSCZJHMX_ZXZT='1' "+&
	" from "+ isSelTempTable+&
	" where CMSCZJHMX_JHLS=F_JHLS and CMSCZJHMX_JHFL=F_JHFL "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新明细表下达标志、执行状态出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 更新任务表下达标志，使用临时表
lsSql = "update CMSCZJHRW set CMSCZJHRW_SFXD='1', "+&
	" CMSCZJHRW_CPRWZXZT = '3' "+&
	" from "+ isSelTempTable+&
	" where CMSCZJHRW_JHLS=F_JHLS and CMSCZJHRW_JHFL=F_JHFL "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新任务表下达标志、执行状态出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 更新设备状态
lsSql = "update JSGZZX set JSGZZX_SBZT = '1' "+&
	" where JSGZZX_ZXBH = '"+lsGzzx+"' "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新设备状态出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 提交数据库
Commit;
If m <> 0 Then
	messagebox("提示信息","派工单已经下达过，不允许重复下达！")
End If
If n <> 0 Then
	//messagebox("提示信息","派工单未指派任务，不允许下达！")
End If

If liCount <> 0 Then
	messagebox("提示信息","派工单下达完成！")
	// 下方数据窗口刷新一下
	dw_master.retrieve(lsJhls)
	dw_detail.retrieve(lsJhls)
	dw_detail2.retrieve(lsJhls)
End If

gf_closehelp()

// 刷新下数据
//event ue_refresh()

Return 1
