//====================================================================
// 事件: u_cj_xacm_cjplgxzy.ue_bcprk()
//--------------------------------------------------------------------
// 描述:半成品品入库，中间需要返工的半成品需要入车间库
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2017年09月08日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
string lsSql,lsErr
long liCount
integer i
string lsSelect
string lsLsbh,lsFlbh,lsCpbh,lsGxsh // 流水编号、分录编号、产品编号、工序顺号
string lsParm
string lsWlbh // 物料编号
nvo_select lNvoSelect // 利用sql取值对象
string lsRkdls
string lsGxzt
long llCount1,llCount2 // 计数使用
string lsMaxGxsh // 最大工序顺号
integer liRtn // 执行返回值
string lsRkjl // 非正常产品品入库记录
string lsScrwh,lsgxmc
decimal vdfsl1

// 看是否有需要进行入库的数据
If dw_data.rowcount() < 1 Then
	messagebox("提示信息","没有进行工序转移的数据！")
	Return -1
End If

// 清空一下临时表
lsSql = "truncate table " + isDrkcpGxTempTable
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 循环数据窗口将选择的数据存入临时表中，便于后续操作
// 必须是工序顺号相同的才能指定相同的下道工序
liCount = 0
For i = 1 to dw_data.rowcount( )
	lsSelect = dw_data.getitemstring( i,"f_select")
	If lsSelect <> '1' Then
		Continue
	End If
	lsLsbh = dw_data.getitemstring(i,"cmcjscrwgy_lsbh")
	lsFlbh = dw_data.getitemstring(i,"cmcjscrwgy_flbh")
	lsCpbh = dw_data.getitemstring(i,"cmcjscrwgy_cpbh")
	lsGxsh = dw_data.getitemstring(i,"cmcjscrwgy_gxsh")
	lsWlbh = dw_data.getitemstring(i,"cmcjscrwcp_wlbh")
	lsGxzt = dw_data.getitemstring(i,"cmcjscrwgy_gxzt")
	lsScrwh = dw_data.getitemstring(i,"cmcjscrwcp_scrwh")
	
	vdfsl1 = dw_data.getitemdecimal(i,"cmcjscrwgy_fsl1")
	if isnull(vdfsl1) then vdfsl1 = 0
	
	lsgxmc = dw_data.getitemstring(i,"lsgxzd_gxmc")
	lsgxmc= trim(lsgxmc)
	if isnull(lsgxmc) then lsgxmc=''
	
	// 将产品编号记录到临时表中
	lsSql =  " insert into "+isDrkcpGxTempTable+"(F_LSBH,F_FLBH,F_WLBH,F_CPBH,F_GXSH,F_GXZT,F_SCRWH,F_GXMC,F_FSL1) "+&
				" values('"+lsLsbh+"','"+lsFlbh+"','"+lsWlbh+"','"+lsCpbh+"','"+lsGxsh+"','"+lsGxzt+"','"+lsScrwh+"','"+lsgxmc+"', "+string(vdfsl1)+" ) "
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
		Return -1
	End If
	liCount++
Next

If liCount < 1 Then
	messagebox("提示消息","请选择需要进行工序转移的任务！")
	Return -1
End If

// 合法性判断
// 工序状态必须是都已经检验完成
// 必须都是最后一道工序，半成品入库不需要
lsSql = "select count(1) from "+isDrkcpGxTempTable+" where F_GXZT<>'G3' "
lNvoSelect.of_select( lsSql, llCount1, lsErr)
If isnull(llCount1) Then
	llCount1 = 0
End If

If llCount1 > 0 Then
	Rollback;
	messagebox("提示信息","存在未检验的工序入库！")
	Return -1
End If

// 半成品入库不需要是末道工序，考虑是否判断必须不是末道工序，最后一道工序加工坏了也得入半成品库
//Select max(CMCJSCRWGY_GXSH) Into :lsMaxGxsh From CMCJSCRWGY Where CMCJSCRWGY_LSBH = :lsLsbh;
//If isnull(lsMaxGxsh) Or trim(lsMaxGxsh) = "" Then
//	lsMaxGxsh = ""
//End If
//
//lsSql = "select count(1) from "+isDrkcpGxTempTable+" where F_GXSH<>'"+lsMaxGxsh+"' "
//lNvoSelect.of_select( lsSql, llCount2, lsErr)
//If isnull(llCount2) Then
//	llCount2 = 0
//End If
//
//If llCount2 > 0 Then
//	Rollback;
//	messagebox("提示信息","存在不是末道工序的产品入库！")
//	Return -1
//End If

// 打开弹窗处理完工入库操作，生成入库单
// 调用函数，生成生产入库单
liRtn = uf_create_scrkd(lsWlbh,lsCpbh,lsRkdls)
If liRtn = -2 Then
	Rollback;
	Return -1
Elseif liRtn <= -1 Then
	Rollback;
	messagebox("提示信息","生成生产入库单出错!")
	Return -1
Else
	
End If

// 考虑关联关系的记录
//// 将生成的生产入库单的流水号回写到CMCJSCRWCP上，记录关系，便于逆向操作，进行回溯
//// 根据单件号作为更新依据
//lsSql = "update CMCJSCRWCP set CMCJSCRWCP_SCCKDLSBH=F_LSBH,CMCJSCRWCP_SCCKDFLBH=F_FLBH "+&
//		" from "+isKcckdTempTableDj+&
//		" where CMCJSCRWCP_CPBH=F_CPBH "
//
//If gfexesql(lsSql,sqlca) < 0 Then
//	lsErr = sqlca.sqlerrtext
//	Rollback;
//	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
//	Return -1
//End If

//f_test(isKcrkdTempTableDj,"d:\kkkk.xls",sqlca)

// 更新超码车间生产任务产品表的入库标志，入库流水分录，入库处理方式。
//lsSql = "insert into KCRKD3(KCRKD3_LSBH,KCRKD3_FLBH,KCRKD3_JH,KCRKD3_SL,KCRKD3_FSL1,KCRKD3_FSL2)"+&
//	" select '"+lsLsbh+"',F_FLBH,F_JH,F_SL,F_FSL1,F_FSL2"+&
//	" from "+isKcrkdTempTableDj
//lsSql = " update CMCJSCRWCP set "+&
//	" CMCJSCRWCP_SFRK = '1', "+&
//	" CMCJSCRWCP_SCRKDLSBH = '"+isKcrkdTempTableDj+".F_LSBH' "+&
//	" CMCJSCRWCP_SCRKDFLBH = '"+isKcrkdTempTableDj+".F_FLBH' "+&
//	" CMCJSCRWCP_CPRKCLFS = '3' "+&
//	" from "+isKcrkdTempTableDj+&
//	" where CMCJSCRWCP_CPBH = "+isKcrkdTempTableDj+".F_JH "

lsSql = " update CMCJSCRWCP set "+&
	" CMCJSCRWCP_SFRK = '1', "+&
	" CMCJSCRWCP_FZCRKINFO = "+isKcrkdTempTableDj+".F_LSBH+','+"+isKcrkdTempTableDj+".F_FLBH+';' ,"+&
	" CMCJSCRWCP_CPRKCLFS = '3' "+&
	" from "+isKcrkdTempTableDj+&
	" where CMCJSCRWCP_CPBH = "+isKcrkdTempTableDj+".F_JH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If


// 更新工序转序状态为已入库
// 根据临时表去更新
//lsSql = "update CMCJSCRWGY set CMCJSCRWGY_SFZX = '1', CMCJSCRWGY_GXZT='G4' "+&
lsSql = "update CMCJSCRWGY set CMCJSCRWGY_SFZX = '1', CMCJSCRWGY_GXZT='G40' "+&
	" from "+isDrkcpGxTempTable+&
	" where CMCJSCRWGY_LSBH=F_LSBH and CMCJSCRWGY_FLBH=F_FLBH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 提交数据库
Commit;

messagebox("提示信息","入库完成！")

// 看板刷新一下
event ue_refresh()

// 打开生成的生产入库单，便于其提交审批
If isnull(lsRkdls) or trim(lsRkdls) = "" Then
	Rollback;
	messagebox("提示信息","获取生产入库单流水号失败，无法打开!")
	Return -1
End If

If gif_exists("KCRKD1","KCRKD1_LSBH='"+lsRkdls+"' ") < 1 Then
	messagebox("提示信息","生成生产入库单失败!")
	Return 0
End If

lsParm = "KC"+";"+"0"+";VIEW;"+lsRkdls
gn_modules.of_openmodule("KCAA03",lsParm,lsErr)

Return 1
