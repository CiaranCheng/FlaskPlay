//====================================================================
// 函数: u_xacm_woscrwcx.uf_gjsj()
//--------------------------------------------------------------------
// 描述: 生产任务单数据归集
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2018年01月10日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
string lsSql,lsErr

// 清空临时表
lsSql = "truncate table " + iscxtbl
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

//lsSql = " insert into "+iscxtbl+&
//	"(F_LSBH,F_RWBH,F_RWLY,F_GXSH ,"+&
//	" F_GXBH,F_CSRQ,F_CPBH,F_WLBH,F_FPBZ,F_FPRY,F_FPRQ,F_DEGS,F_SCRWH)"+&
//	" select CMSCRW_LSBH,CMSCRW_RWBH,CMSCRW_RWLY,CMSCRW_GXSH ,"+&
//	" CMSCRW_GXBH,CMSCRW_CSRQ,CMSCRW_CPBH,CMSCRW_WLBH,CMSCRW_FPBZ ,CMSCRW_FPRY ,CMSCRW_FPRQ ,CMSCRW_DEGS,CMSCRW_SCRWH  "+&
//	"  from CMSCRW "
lsSql = " insert into "+iscxtbl+&
	" (F_LSBH,F_RWBH,F_RWLY,F_WLBH,F_WLMC,F_CPBH,"+&
	" F_GXBH,F_GXMC,F_GXSH,F_GXMS,F_CSRQ,"+&
	" F_FPBZ,F_FPRQ,F_FPRY,F_FPRYXM,F_DEGS,"+&
	" F_SCRWH,F_GYLXBH,F_GYLXFLBH,F_SL,F_YJJF)"+&
	" select "+&
	" CMSCRW_LSBH,CMSCRW_RWBH,CMSCRW_RWLY,CMSCRW_WLBH,'',CMSCRW_CPBH,"+&
	" CMSCRW_GXBH,'',CMSCRW_GXSH,'',CMSCRW_CSRQ,"+&
	" CMSCRW_FPBZ,CMSCRW_FPRQ,CMSCRW_FPRY,'',CMSCRW_DEGS,"+&
	" CMSCRW_SCRWH,CMSCRW_GYLXBH,CMSCRW_GYLXFLBH,1,'' "+&
	" from CMSCRW "+&
	" where 1=1 "

// 日期过滤条件  					
lsSql+= " and CMSCRW_CSRQ>='"+isqsrq+"' and CMSCRW_CSRQ<='"+iszzrq+"'"

// 任务来源 采购入库单或者工序转移单（CGRKD/GXZYD）
If not isnull(isDjly) and  trim(isDjly) <> '' Then
	lsSql+= " and CMSCRW_RWLY='" + isDjly+"'"
End If

// 生产任务号
If not isnull(isScrwh) and  trim(isScrwh) <> '' Then
	lsSql+= " and CMSCRW_SCRWH='" + isScrwh+"'"
End If

// 工序编号
If not isnull(isGxbh) and  trim(isGxbh) <> '' Then
	lsSql+= " and CMSCRW_GXBH='" + isGxbh+"'"
End If

// 工序顺号
If not isnull(isGxsh) and  trim(isGxsh) <> '' Then
	lsSql+= " and CMSCRW_GXSH='" + isGxsh+"'"
End If

// 是否分配
If not isnull(isSffp) and trim(isSffp) <> '' Then
	If trim(isSffp) = '未分配' Then
		lsSql+= " and CMSCRW_FPBZ='0' "
	End If
	If trim(isSffp) = '已分配' Then
		lsSql+= " and CMSCRW_FPBZ='1' "
	End If
End If

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","插入待查询数据时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新物料名称/产品名称
Choose Case gskind
	Case 'ORA'
		lsSql = "Update "+iscxtbl+" set (F_WLMC) = (SELECT LSWLZD_WLMC from LSWLZD where "+iscxtbl+".F_WLBH=LSWLZD_WLBH ) WHERE EXISTS(SELECT 1 from LSWLZD where "+iscxtbl+".F_WLBH=LSWLZD_WLBH )"
	Case Else
		lsSql = "Update "+iscxtbl+" set F_WLMC = LSWLZD_WLMC from LSWLZD where "+iscxtbl+".F_WLBH=LSWLZD_WLBH "
End Choose

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新产品名称时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新工序名称
Choose Case gskind
	Case 'ORA'
		lsSql = "update "+iscxtbl+" set (F_GXMC) = (select LSGXZD_GXMC from LSGXZD where "+iscxtbl+".F_GXBH=LSGXZD.LSGXZD_GXBH )"+&
			" where exists(select 1 from LSGXZD where "+iscxtbl+".F_GXBH=LSGXZD.LSGXZD_GXBH )"
	Case Else
		lsSql = "update "+iscxtbl+" set F_GXMC = LSGXZD_GXMC from LSGXZD where "+iscxtbl+".F_GXBH=LSGXZD.LSGXZD_GXBH "
End Choose
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工序名称时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新工序描述/工序周期
Choose Case gskind
	Case 'ORA'
		lsSql = "update "+iscxtbl+" set (F_GXMS) = (select CMBZGYLX_GXMS from CMBZGYLX  "+&
			"where "+iscxtbl+".F_GYLXBH=CMBZGYLX.CMBZGYLX_GYLXBH and "+iscxtbl+".F_GYLXFLBH=CMBZGYLX.CMBZGYLX_FLBH ) "+&
			" where exists(select 1 from CMBZGYLX  where "+iscxtbl+".F_GYLXBH=CMBZGYLX.CMBZGYLX_GYLXBH "+&
			" and "+iscxtbl+".F_GYLXFLBH=CMBZGYLX.CMBZGYLX_FLBH )"
	Case Else
		lsSql = "update "+iscxtbl+" set F_GXMS = CMBZGYLX_GXMS from CMBZGYLX  "+&
			"where "+iscxtbl+".F_GYLXBH=CMBZGYLX.CMBZGYLX_GYLXBH and "+iscxtbl+".F_GYLXFLBH=CMBZGYLX.CMBZGYLX_FLBH"
End Choose

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工序周期时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 本身就是名称了，不需要更新了
//// 更新分配人员姓名
//Choose Case gskind
//	Case 'ORA'
//		lsSql = "Update "+iscxtbl+" set (F_FPRYXM) = (SELECT ZWZGZD_ZGXM from ZWZGZD where "+iscxtbl+"F_FPRY=ZWZGZD_ZGBH ) WHERE EXISTS(SELECT 1 from ZWZGZD where "+iscxtbl+".F_FPRY=ZWZGZD_ZGBH )"
//	Case Else
//		lsSql = "Update "+iscxtbl+" set F_FPRYXM = ZWZGZD_ZGXM from ZWZGZD where "+iscxtbl+".F_FPRY=ZWZGZD_ZGBH "
//End Choose
//
//If gfexesql(lsSql,sqlca) < 0 Then
//	lsErr = sqlca.sqlerrtext
//	Rollback;
//	messagebox("提示信息","更新分配人员姓名时出错！"+lsErr+"~r~n"+ lsSql)
//	Return -1
//End If

// 更新已机加否 CMCJSCRWCP_YJJF
Choose Case gskind
	Case 'ORA'
//		lsSql = "update "+iscxtbl+" set (F_GXMC) = (select LSGXZD_GXMC from LSGXZD where "+iscxtbl+".F_GXBH=LSGXZD.LSGXZD_GXBH )"+&
//			" where exists(select 1 from LSGXZD where "+iscxtbl+".F_GXBH=LSGXZD.LSGXZD_GXBH )"
	Case Else
		lsSql = "update "+iscxtbl+" set F_YJJF = CMCJSCRWCP_YJJF from CMCJSCRWCP where "+iscxtbl+".F_CPBH=CMCJSCRWCP.CMCJSCRWCP_CPBH "
End Choose
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新已机加否时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 将已机加否为空的更新为未机加
lsSql = "update "+iscxtbl+" set F_YJJF = '0' where isnull(F_YJJF,'')='' "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新已机加否时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

Return 1
