//====================================================================
// 函数: u_cj_xacm_cjkb.uf_create_scrkd()
//--------------------------------------------------------------------
// 描述: 生成生产入库单
//--------------------------------------------------------------------
// 参数:
// 	value    	string		asWlbh 	物料编号
// 	value    	string 	asCpbh 	产品编号，单件号
// 	reference	string 	asrkdls	生成的入库单流水
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2017年09月20日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
string lsSql,lsErr
string lsLsbh
string lsSjdh
n_ds lndsDjbh
long llRow
n_bhff_bhcreate iuo_bhff
string lsKcywrq,lsLbbh,lsBmbh,lsCkbh,lsDjrq,lsJyk,lsPch
string lsParm
string lsWlbh,lsDjh

lsWlbh = asWlbh
lsDjh = asCpbh

// 打开弹窗，获取生成入库单需要的信息
// lsParm = "" // 传入参数
// 弹框录入部门、仓库等信息
lsParm = lswlbh+";"
openwithparm(w_cj_xacm_scrkd_xx,lsParm)
lsParm = message.stringparm
If isnull(lsParm) Or trim(lsParm) = '' Or trim(lsParm) = 'cancel' Then
	Return -2
End If

// 解析参数，获取各变量值
lsDjrq = get_token(lsParm,";")
lsKcywrq = get_token(lsParm,";")
lsLbbh = get_token(lsParm,";")
lsCkbh = get_token(lsParm,";")
lsBmbh = get_token(lsParm,";")
lsJyk =  get_token(lsParm,";")
lsPch = get_token(lsParm,";")

If isnull(lsDjrq) Or trim(lsDjrq) = "" Then
	lsDjrq = ""
End If

If isnull(lsKcywrq) Or trim(lsKcywrq) = "" Then
	lsKcywrq = ""
End If

If isnull(lsLbbh) Or trim(lsLbbh) = "" Then
	lsLbbh = ""
End If

If isnull(lsCkbh) Or trim(lsCkbh) = "" Then
	lsCkbh = ""
End If

If isnull(lsBmbh) Or trim(lsBmbh) = "" Then
	lsBmbh = ""
End If

If isnull(lsJyk) Or trim(lsJyk) = "" Then
	lsJyk = ""
End If

If isnull(lsPch) Or trim(lsPch) = "" Then
	lsPch = ""
End If

// 清空下临时表
// 生产入库单表头临时表
lsSql = "truncate table "+isKcrkdTempTableBt
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox('提示信息','清空临时表时发生错误~r~n'+lsErr+'~r~n'+lsSql)
	Return -1
End If

// 生产入库单表体临时表
lsSql = "truncate table "+isKcrkdTempTableMx
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox('提示信息','清空临时表时发生错误~r~n'+lsErr+'~r~n'+lsSql)
	Return -1
End If

// 生产入库单单件临时表
lsSql = "truncate table "+isKcrkdTempTableDj
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox('提示信息','清空临时表时发生错误~r~n'+lsErr+'~r~n'+lsSql)
	Return -1
End If

// 生成临时表数据--生产入库单表头
lsSql = "insert into "+isKcrkdTempTableBt+"(F_PJLX,F_YWBS,F_LSBH,F_SJDH,F_LBBH,F_DJRQ,F_KCYWRQ,F_CHYWRQ,F_CKBH,F_BMBH,F_JKY,F_LRXM,F_BZ) "+&
	" values('J','SGLR','','','"+lsLbbh+"','"+lsDjrq+"','"+lsKcywrq+"','"+lsKcywrq+"','"+lsCkbh+"','"+lsBmbh+"','"+lsJyk+"','"+GsUserName+"','车间下推自动生成')"

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成生产入库单表头出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If



// 生成临时表数据--生产入库单单件
// 数量默认就是1了
// 流水号、分录号暂时先不处理
lsSql = "insert into "+isKcrkdTempTableDj+"(F_LSBH,F_FLBH,F_JH,F_SL,F_FSL1,F_FSL2,F_WLBH,F_SCRWH,F_GXMC)"+&
		" select '','',F_CPBH,1,F_FSL1,F_FSL1,F_WLBH,F_SCRWH,F_GXMC "+&
		" from "+isDrkcpGxTempTable

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成生产入库单单件出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 生成临时表数据--生产入库单表体
// 根据单件表体生成
lsSql = "insert into "+isKcrkdTempTableMx+"(F_PJLX,F_LSBH,F_FLBH,F_HWBH,F_WLBH,F_PCH,F_ZYX1,F_ZYX2,F_ZYX3,F_ZYX4,F_ZYX5,F_TSKC,F_XGDX,F_SL,F_FSL1,F_FSL2,F_BZ,F_GXMC)"+&
		" select 'J','','','',F_WLBH,'"+lsPch+"','','','','','','Z','',sum(F_SL),sum(F_FSL1),sum(F_FSL2),'' ,max(F_GXMC)"+&
		" from "+isKcrkdTempTableDj+&
		" group by F_WLBH"

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成生产入库单表体出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 表体临时表分录编号处理
lsSql = " update " +isKcrkdTempTableMx+ " set F_FLBH = right(cast('000000000'+convert(nvarchar,F_ID) as nvarchar(20)),10) "
if gfexesql(lsSql,Sqlca) < 0 then
	lsErr = Sqlca.Sqlerrtext
	ROLLBACK;
	messagebox("提示信息","入库单表体更新分录编号失败！"+lsErr+"~r~n"+ lsSql)
	return -1
end if

// 单件临时表分录编号处理
lsSql = " update " +isKcrkdTempTableDj+ " set "+isKcrkdTempTableDj+".F_FLBH = "+isKcrkdTempTableMx+".F_FLBH "+&
		" from "+isKcrkdTempTableMx+&
		" where "+isKcrkdTempTableDj+".F_WLBH="+isKcrkdTempTableMx+".F_WLBH "
if gfexesql(lsSql,Sqlca) < 0 then
	lsErr = Sqlca.Sqlerrtext
	ROLLBACK;
	messagebox("提示信息","单件表更新分录编号失败！"+lsErr+"~r~n"+ lsSql)
	return -1
end if

// 临时表数据插入到实际表中
// 流水编号获取
lsLsbh = gsf_getnbbm("KCRKD")
If isnull(lsLsbh) Or trim(lsLsbh) = '' Then
	Rollback;
	//gf_closehelp_bar()
	//setpointer(Arrow!)
	messagebox("提示信息","获取流水号失败!")
	Return -1
End If

// 入库单流水传递回去
asRkdls = lsLsbh

// 实际单号生成
If isvalid(lndsDjbh) Then
	lndsDjbh.reset()
Else
	lndsDjbh = Create n_ds
	lndsDjbh.dataobject = 'dw_jxc_scrkd_master_cm_cj'
End If

llRow = lndsDjbh.insertrow(0)

lndsDjbh.setitem(llRow,'kcrkd1_djrq',gsCwrq)
lndsDjbh.setitem(llRow,'kcrkd1_kcywrq',lsKcywrq)
lndsDjbh.setitem(llRow,'kcrkd1_lbbh',lsLbbh)
lndsDjbh.setitem(llRow,'kcrkd1_bmbh',lsBmbh)
lndsDjbh.setitem(llRow,'kcrkd1_ckbh',lsCkbh)
iuo_bhff.ib_auto_updatelsbh = True
iuo_bhff.uf_createbh('SCRKD',lsSjdh,lndsDjbh,1,lsErr,Sqlca)
If lsSjdh = '' Then
	Rollback;
	messagebox("提示信息","获取实际单号失败!"+lsErr)
	Return -1
End If

// 生产入库单表头
lsSql = "insert into KCRKD1(KCRKD1_PJLX,KCRKD1_YWBS,KCRKD1_LBBH,KCRKD1_LSBH,KCRKD1_SJDH,"+&
	"KCRKD1_DJRQ,KCRKD1_KCYWRQ,KCRKD1_CHYWRQ,KCRKD1_CKBH,KCRKD1_BMBH,KCRKD1_JKY,"+&
	"KCRKD1_LRXM,KCRKD1_BZ,KCRKD1_SHBZ)"+&
	" select F_PJLX,F_YWBS,F_LBBH,'"+lsLsbh+"','"+lsSjdh+"',"+&
	"F_DJRQ,F_KCYWRQ,F_CHYWRQ,F_CKBH,F_BMBH,F_JKY,"+&
	"F_LRXM,F_BZ,'0' "+&
	" from "+isKcrkdTempTableBt

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If
//KCRKD2_C10 记录工序名称
// 生产入库单明细
lsSql = "insert into KCRKD2(KCRKD2_PJLX,KCRKD2_LSBH,KCRKD2_FLBH,KCRKD2_HWBH, "+&
	"KCRKD2_WLBH,KCRKD2_PCH,KCRKD2_ZYX1,KCRKD2_ZYX2,KCRKD2_ZYX3,KCRKD2_ZYX4,KCRKD2_ZYX5, "+&
	+"KCRKD2_TSKC,KCRKD2_XGDX,KCRKD2_SSSL,KCRKD2_FSSSL1,KCRKD2_FSSSL2,KCRKD2_BZ,KCRKD2_C10) "+&
	" select F_PJLX,'"+lsLsbh+"',F_FLBH,F_HWBH,"+&
	"F_WLBH,F_PCH,F_ZYX1,F_ZYX2,F_ZYX3,F_ZYX4,F_ZYX5,"+&
	"F_TSKC,F_XGDX,F_SL,F_FSL1,F_FSL2,F_BZ,F_GXMC "+&
	" from "+isKcrkdTempTableMx

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新流水编号方便后续更新非正常入库记录
lsSql = " update "+isKcrkdTempTableDj+&
	"  set "+isKcrkdTempTableDj+".F_LSBH = '"+lsLsbh+"' "

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 生产入库单单件
lsSql = "insert into KCRKD3(KCRKD3_LSBH,KCRKD3_FLBH,KCRKD3_JH,KCRKD3_SL,KCRKD3_FSL1,KCRKD3_FSL2,KCRKD3_SCRWH)"+&
	" select F_LSBH,F_FLBH,F_JH,F_SL,F_FSL1,F_FSL2,F_SCRWH"+&
	" from "+isKcrkdTempTableDj

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

Return 1
