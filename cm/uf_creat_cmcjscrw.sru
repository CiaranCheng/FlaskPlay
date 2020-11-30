//====================================================================
// 函数: u_cj_xacm_cjplgxzy.uf_create_cmcjscrw()
//--------------------------------------------------------------------
// 描述: 生成车间生产任务
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2017年09月27日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
string lsSql,lsErr
string lsScrwLsbh
n_ds lndsSel
Long i
String lsJhls,lsJhfl,lsXh

// 清空临时表
// 生产周计划临时表清空
lsSql = "truncate table "+isCmsczjhTempTable
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	gf_closehelp()
	Return -1
End If

// 车间生产任务产品临时表
lsSql = "truncate table "+isCmcjscrwcpTemp
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	gf_closehelp()
	Return -1
End If

// 车间生产任务工艺临时表
lsSql = "truncate table "+isCmcjscrwgyTemp
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	gf_closehelp()
	Return -1
End If

// 测试，勾选的数据
//f_test(isSelTempTable,"d:\seltemp.xls",Sqlca)

// 把选择的需要下达的生产计划明细对应的所有的生产任务插入临时表中
// 这张表里的产品编号一定是唯一的，否则后续会出问题==================
//=============考虑判断，理论上应该是唯一的，因为一个件同一个周期只可能处于一道工序，只能生成一个周计划
lsSql = "insert into "+isCmsczjhTempTable+"("+&
	" F_JHLS,F_JHBH,F_JHFL,F_GZZX,F_WLBH,F_SCPC,F_KSRQ,F_JSRQ,F_XDBZ,F_ZXZT,"+&
	" F_XH,F_RWLS,F_RWBH,F_CPBH,F_GXSH,F_GXBH,"+&
	" F_ZXBZ,F_SFXD,F_CPXDFLAG,F_GYLXBH,F_GYLXFLBH,F_SCRWH"+&
	" ) "+&
	" select "+&
	" F_JHLS,F_JHBH,F_JHFL,F_GZZX,F_WLBH,F_SCPC,F_KSRQ,F_JSRQ,F_XDBZ,F_ZXZT,"+&
	" CMSCZJHRW_XH,CMSCZJHRW_RWLS,CMSCZJHRW_RWBH,CMSCZJHRW_CPBH,CMSCZJHRW_GXSH,CMSCZJHRW_GXBH,"+&
	" CMSCZJHRW_ZXBZ,CMSCZJHRW_SFXD,'0',CMSCZJHRW_GYLXBH,CMSCZJHRW_GYLXFLBH,CMSCZJHRW_SCRWH "+&
	" from "+isSelTempTable+",CMSCZJHRW "+&
	" where F_JHLS=CMSCZJHRW_JHLS "+&
	" and F_JHFL=CMSCZJHRW_JHFL "
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","归集生产计划数据时出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// f_test(isCmsczjhTempTable,"d:\isCmsczjhTempTable.xls",Sqlca)
// 产品（预置体/单件）是否已经下达过的标志更新
lsSql = "update "+isCmsczjhTempTable+&
	" set F_CPXDFLAG='1' "+&
	" where exists(select 1 from CMCJSCRWCP where CMCJSCRWCP_CPBH=F_CPBH)"
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新产品下达标志时出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 测试，归集到的生产计划明细数据
// f_test(isCmsczjhTempTable,"d:\cmsczjhalltemp.xls",Sqlca)

// 未下达过的数据要生成任务流水号，更新到临时表中，便于后续往实际表中插入
lsSql = "select F_JHLS,F_JHFL,F_XH from "+isCmsczjhTempTable+" where F_CPXDFLAG='0' "
If gf_createds(lsSql,lndsSel) = -1 Then
	messagebox("提示信息","创建datastore失败！")
	gf_closehelp()
	Return -1
End If

//llRowCount = dw_list.rowcount()
//llRow = dw_list.getrow() // 获取当前行，应该是空行，从当前行往下插入
For i = 1 To lndsSel.rowcount()
	lsJhls = lndsSel.getitemstring(i,"f_jhls")
	lsJhfl = lndsSel.getitemstring(i,"f_jhfl")
	lsXh = lndsSel.getitemstring(i,"f_xh")

	// 流水编号获取
	lsScrwLsbh = gsf_getnbbm("CMCJSCRW")
	If isnull(lsScrwLsbh) Or trim(lsScrwLsbh) = '' Then
		Rollback;
		messagebox("提示信息","获取流水号失败！")
		gf_closehelp()
		Return -1
	End If
	
	lsSql = "update "+isCmsczjhTempTable+" set F_CJSCRWLSBH='"+lsScrwLsbh+"' "+&
				" where F_JHLS='"+lsJhls+"' and F_JHFL='"+lsJhfl+"' and F_XH='"+lsXh+"' "
	If gfexesql(lsSql,Sqlca) < 0 Then
		lsErr = Sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新生产任务流水编号时出错！"+lsErr+"~r~n"+ lsSql)
		gf_closehelp()
		Return -1
	End If
next

// 生成流水编号，流水编号更新回临时表中
// 每个生产任务都必须有单独的流水编号，考虑如何更新生成的流水号？？
//// 生产任务产品更新计划流水
//lsSql = "update "+isCmcjscrwcpTemp+" set F_LSBH='"+lsScrwLsbh+"' "
//If gfexesql(lsSql,Sqlca) < 0 Then
//	lsErr = Sqlca.sqlerrtext
//	Rollback;
//	messagebox("提示信息","生产任务产品更新流水号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
//	Return -1
//End If
//
//// 生产任务工艺更新计划流水
//lsSql = "update "+isCmcjscrwgyTemp+" set F_LSBH='"+lsScrwLsbh+"' "
//If gfexesql(lsSql,Sqlca) < 0 Then
//	lsErr = Sqlca.sqlerrtext
//	Rollback;
//	messagebox("提示信息","生产任务工艺更新流水号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
//	Return -1
//End If
//

// 只插入CMCJSCRWCP中尚未插入过的
// 同一个产品只插入一次
// 图号取物料字典上的图号，名称取物料字典上的名称
// 刻号与产品编号（单件号）一致
//lsSql = "insert into "+isCmcjscrwcpTemp+"(F_LSBH,F_CPBH,F_WLBH,F_WLMC,"+&
//	" F_TH,F_KH,F_DJRQ,F_SJKGRQ,F_SJWGRQ )"+&
//	" select '',CMSCZJHRW_CPBH,F_WLBH,LSWLZD_WLMC,"+&
//	" LSWLZD_TH,CMSCZJHRW_CPBH,'"+gsCwrq+"','','' "+&
//	" from "+isSelTempTable+",LSWLZD,CMSCZJHRW "+&
//	" where F_WLBH=LSWLZD_WLBH "+&
//	" and CMSCZJHRW_JHLS=F_JHLS and CMSCZJHRW_JHFL=F_JHFL "+&
//	" and not exists(select 1 from CMCJSCRWCP where CMCJSCRWCP_CPBH=CMSCZJHRW_CPBH)"

lsSql = "insert into "+isCmcjscrwcpTemp+"(F_LSBH,F_CPBH,F_WLBH,F_WLMC,"+&
	" F_TH,F_KH,F_DJRQ,F_SJKGRQ,F_SJWGRQ,F_SCRWH )"+&
	" select F_CJSCRWLSBH,F_CPBH,F_WLBH,LSWLZD_WLMC,"+&
	" LSWLZD_GGXH,F_CPBH,'"+gsCwrq+"','','',"+isCmsczjhTempTable+".F_SCRWH "+&
	" from "+isCmsczjhTempTable+",LSWLZD "+&
	" where F_WLBH=LSWLZD_WLBH "+&
	" and F_CPXDFLAG='0' "+&
	" and not exists ( select 1 from CMCJSCRWCP where CMCJSCRWCP_CPBH=F_CPBH )"

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间生产任务产品临时表数据出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 测试，超码车间生产任务产品临时表数据
//f_test(isCmcjscrwcpTemp,"d:\cmcjscrwcptemp.xls",Sqlca)

// CMSCZJHRW_RWLS需要添加数据结构
// 总工时从哪里取过来

//lsSql = "insert into "+isCmcjscrwgyTemp+"(F_LSBH,F_FLBH,F_CPBH,F_GXSH,F_GXBH,"+&
//	"F_RWLS,F_RWBH,F_JHLS,F_JHFL,F_JHBH,"+&
//	"F_KGRY,F_KGRQ,F_WGRY,F_WGRQ,F_GXZT,F_GZZX,"+&
//	"F_ZGS,F_SJGS,F_ZSL,F_HGSL,F_BFSL )"+&
//	" select '',CMBZGYLX_FLBH,F_CPBH,CMBZGYLX_GXSH,CMBZGYLX_GXBH,"+&
//	" CMSCZJHRW_RWLS,CMSCZJHRW_RWBH,CMSCZJHRW_JHLS,CMSCZJHRW_JHFL,CMSCZJHRW_JHBH,"+&
//	" '','','','','G0',F_GZZX,"+&
//	" 100,0,1,0,0 "+&
//	" from "+isCmcjscrwcpTemp+",CMSCZJHRW,CMBZGYLX"+&
//	" where CMSCZJHRW_JHLS=F_JHLS and CMSCZJHRW_JHFL=F_JHFL "+&
//	" and F_CPBH=CMBZGYLX "

//lsSql = "insert into "+isCmcjscrwgyTemp+"(F_LSBH,F_FLBH,F_CPBH,F_GXSH,F_GXBH,"+&
//	"F_RWLS,F_RWBH,F_JHLS,F_JHFL,F_JHBH,"+&
//	"F_KGRY,F_KGRQ,F_WGRY,F_WGRQ,F_GXZT,F_GZZX,"+&
//	"F_ZGS,F_SJGS,F_ZSL,F_HGSL,F_BFSL )"+&
//	" select '',CMBZGYLX_FLBH,F_CPBH,CMBZGYLX_GXSH,CMBZGYLX_GXBH,"+&
//	" CMSCZJHRW_RWLS,CMSCZJHRW_RWBH,CMSCZJHRW_JHLS,CMSCZJHRW_JHFL,CMSCZJHRW_JHBH,"+&
//	" '','','','','G0',F_GZZX,"+&
//	" 100,0,1,0,0 "+&
//	" from "+isCmcjscrwcpTemp+",CMBZGYLX"+&
//	" where CMBZGYLX_GYLXBH='01' "
//"CMSCZJHRW_JHLS=F_JHLS and CMSCZJHRW_JHFL=F_JHFL "+&
//" and F_CPBH=CMBZGYLX "

// 插入类别为'01'的工艺路线
// 后续需考虑总工时从哪里来，目前是设置了默认值100
// 两者求了个笛卡尔积
// 计划的流水、分录、编号、任务流水、任务分录都应该为空，后续更新
//lsSql = "insert into "+isCmcjscrwgyTemp+"(F_LSBH,F_FLBH,F_CPBH,F_GXSH,F_GXBH,"+&
//	"F_RWLS,F_RWBH,F_JHLS,F_JHFL,F_JHBH,"+&
//	"F_KGRY,F_KGRQ,F_WGRY,F_WGRQ,F_GXZT,F_GZZX,"+&
//	"F_ZGS,F_SJGS,F_ZSL,F_HGSL,F_BFSL,F_SFSDGX,F_SFMDGX )"+&
//	" select F_CJSCRWLSBH,CMBZGYLX_FLBH,F_CPBH,CMBZGYLX_GXSH,CMBZGYLX_GXBH,"+&
//	" F_RWLS,F_RWBH,F_JHLS,F_JHFL,F_JHBH,"+&
//	" '','','','','G0',F_GZZX,"+&
//	" 100,0,1,0,0,CMBZGYLX_SFSDGX,CMBZGYLX_SFMDGX "+&
//	" from "+isCmsczjhTempTable+",CMBZGYLX"+&
//	" where CMBZGYLX_GYLXBH='01' "+&
//	" and F_CPXDFLAG='0' "

// 计划流水、计划分录、计划编号、工作中心、任务流水、任务分录,生产批次放空
lsSql = "insert into "+isCmcjscrwgyTemp+"(F_LSBH,F_FLBH,F_CPBH,F_GXSH,F_GXBH,"+&
	"F_RWLS,F_RWBH,F_JHLS,F_JHFL,F_JHBH,"+&
	"F_KGRY,F_KGRQ,F_WGRY,F_WGRQ,F_GXZT,F_GZZX,"+&
	"F_ZGS,F_SJGS,F_ZSL,F_HGSL,F_BFSL,F_SFSDGX,F_SFMDGX,F_GYLXBH,F_GYLXFLBH,F_SCPC )"+&
	" select F_CJSCRWLSBH,CMBZGYLX_FLBH,F_CPBH,CMBZGYLX_GXSH,CMBZGYLX_GXBH,"+&
	" '','','','','',"+&
	" '','','','','G0','',"+&
	" 100,0,1,0,0,CMBZGYLX_SFSDGX,CMBZGYLX_SFMDGX,"+isCmsczjhTempTable+".F_GYLXBH,CMBZGYLX_FLBH,'' "+&
	" from "+isCmsczjhTempTable+",CMBZGYLX"+&
	" where CMBZGYLX_GYLXBH=F_GYLXBH "+&
	" and F_CPXDFLAG='0' "

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间生产任务工艺临时表数据出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 测试
//f_test(isCmcjscrwgyTemp,"d:\cmcjscrwgytemp.xls",Sqlca)

// 生成完整工艺路线后要更新计划流水、计划分录、计划编号等
// 计划流水、计划分录、计划编号、工作中心、任务流水、任务分录放空
// 根据临时表产品编号、工序顺号 更新生成的CMCJSCRWGY的这些值

//lsSql = "update "+isCmcjscrwgyTemp+&
//	" set F_RWLS = "+isCmsczjhTempTable+".F_RWLS, "+&
//	"F_RWBH = "+isCmsczjhTempTable+".F_RWBH, "+&
//	"F_JHLS = "+isCmsczjhTempTable+".F_JHLS, "+&
//	"F_JHFL = "+isCmsczjhTempTable+".F_JHFL, "+&
//	"F_JHBH = "+isCmsczjhTempTable+".F_JHBH, "+&
//	"F_GZZX = "+isCmsczjhTempTable+".F_GZZX "+&
//	" from "+isCmsczjhTempTable+&
//	" where "+isCmcjscrwgyTemp+".F_CPBH = "+isCmsczjhTempTable+".F_CPBH "+&
//	" and "+isCmcjscrwgyTemp+".F_GXSH = "+isCmsczjhTempTable+".F_GXSH"
//If gfexesql(lsSql,Sqlca) < 0 Then
//	lsErr = Sqlca.sqlerrtext
//	Rollback;
//	messagebox("提示信息","生成车间生产任务工艺临时表数据出错！"+lsErr+"~r~n"+ lsSql)
//	Return -1
//End If
//
//f_test(isCmcjscrwgyTemp,"d:\cmcjscrwgytemp22.xls",Sqlca)
//f_test(isCmsczjhTempTable,"d:\CmsczjhTempTable22.xls",Sqlca)
////
//return -1


// 临时表数据插入实际表中
// 生成生产任务产品CMCJSCRWCP
lsSql = "insert into CMCJSCRWCP(CMCJSCRWCP_LSBH,CMCJSCRWCP_CPBH,CMCJSCRWCP_WLBH,CMCJSCRWCP_WLMC,"+&
	"CMCJSCRWCP_TH,CMCJSCRWCP_KH,CMCJSCRWCP_DJRQ,CMCJSCRWCP_SJKGRQ,CMCJSCRWCP_SJWGRQ,CMCJSCRWCP_SCRWH) "+&
	" select F_LSBH,F_CPBH,F_WLBH,F_WLMC,"+&
	" F_TH,F_KH,F_DJRQ,F_SJKGRQ,F_SJWGRQ,F_SCRWH "+&
	" from "+isCmcjscrwcpTemp
If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间生产任务产品出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 生成生产任务工艺CMCJSCRWGY
lsSql = "insert into CMCJSCRWGY (CMCJSCRWGY_LSBH,CMCJSCRWGY_FLBH,CMCJSCRWGY_CPBH,CMCJSCRWGY_GXSH,CMCJSCRWGY_GXBH,"+&
	"CMCJSCRWGY_RWLS,CMCJSCRWGY_RWBH,CMCJSCRWGY_JHLS,CMCJSCRWGY_JHFL,CMCJSCRWGY_JHBH,"+&
	"CMCJSCRWGY_KGRY,CMCJSCRWGY_KGRQ,CMCJSCRWGY_WGRY,CMCJSCRWGY_WGRQ,CMCJSCRWGY_GXZT,CMCJSCRWGY_GZZX,"+&
	"CMCJSCRWGY_ZGS,CMCJSCRWGY_SJGS,CMCJSCRWGY_ZSL,CMCJSCRWGY_HGSL,CMCJSCRWGY_BFSL,CMCJSCRWGY_SFSDGX,CMCJSCRWGY_SFMDGX,CMCJSCRWGY_GYLXBH,CMCJSCRWGY_GYLXFLBH,CMCJSCRWGY_SCPC ) "+&
	" select F_LSBH,F_FLBH,F_CPBH,F_GXSH,F_GXBH,"+&
	"F_RWLS,F_RWBH,F_JHLS,F_JHFL,F_JHBH,"+&
	"F_KGRY,F_KGRQ,F_WGRY,F_WGRQ,F_GXZT,F_GZZX,"+&
	"F_ZGS,F_SJGS,F_ZSL,F_HGSL,F_BFSL,F_SFSDGX,F_SFMDGX,F_GYLXBH,F_GYLXFLBH,F_SCPC"+&
	" from "+isCmcjscrwgyTemp

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间生产任务工艺出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

lsSql = "update CMCJSCRWGY "+&
	" set CMCJSCRWGY_RWLS = "+isCmsczjhTempTable+".F_RWLS, "+&
	"CMCJSCRWGY_RWBH = "+isCmsczjhTempTable+".F_RWBH, "+&
	"CMCJSCRWGY_JHLS = "+isCmsczjhTempTable+".F_JHLS, "+&
	"CMCJSCRWGY_JHFL = "+isCmsczjhTempTable+".F_JHFL, "+&
	"CMCJSCRWGY_JHBH = "+isCmsczjhTempTable+".F_JHBH, "+&
	"CMCJSCRWGY_SCPC = "+isCmsczjhTempTable+".F_SCPC, "+&
	"CMCJSCRWGY_GZZX = "+isCmsczjhTempTable+".F_GZZX "+&
	" from "+isCmsczjhTempTable+&
	" where CMCJSCRWGY_CPBH = "+isCmsczjhTempTable+".F_CPBH "+&
	" and  CMCJSCRWGY_GXSH = "+isCmsczjhTempTable+".F_GXSH"

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新计划流水、计划分录、计划编号、工作中心、任务流水、任务分录、工艺路线分类编号，工艺路线编号、炉次号时出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 是否考虑把首道工序更新为已转序。
// 已经插入过的只更新状态
// 看板新增一个状态，将派工单下达的状态更新为G7：已派工下达
// 后续控制，只有派工下达状态的才允许进行开工
lsSql = " update CMCJSCRWGY "+&
	" set CMCJSCRWGY_GXZT='G7' "+&
	" from "+isCmsczjhTempTable+&
	" where CMCJSCRWGY_CPBH=F_CPBH and CMCJSCRWGY_GXSH=F_GXSH "

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新状态出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 把第一道工序 预置体直接更新为已转序，只有在生成CMCJSCRW产品时才更新
// 产品编号+分录编号0000000001能够锁定第一条
lsSql = " update CMCJSCRWGY "+&
	" set CMCJSCRWGY_GXZT='G5' "+&
	" from "+isCmcjscrwcpTemp+&
	" where CMCJSCRWGY_CPBH="+isCmcjscrwcpTemp+".F_CPBH and CMCJSCRWGY_FLBH='0000000001' "

If gfexesql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新第一道工序为转序状态时出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

gf_closehelp()

Return 1
