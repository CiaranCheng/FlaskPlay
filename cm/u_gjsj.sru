//====================================================================
// 函数: u_cj_xacm_cpscgcgz.uf_gjsj()
//--------------------------------------------------------------------
// 描述: 产品生产过程跟踪归集数据
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2018年03月06日
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

lsSql = " insert into "+iscxtbl+&
	"(F_LSBH,F_FLBH,F_WLBH,F_WLMC,F_CPBH,F_ZXFLBH,F_ZXFLMC,"+&
	" F_GZZX,F_ZXMC,F_SCPC,F_GXBH,F_GXMC,F_GXSH,F_GXMS,"+&
	" F_YJJF,F_GXZT,F_KGRY,F_JHKSRQ,F_KSRQ,"+&
	" F_WGRY,F_JHJSRQ,F_JSRQ,"+&
	" F_JJRY,F_JJSJ,F_JYRY,F_JYSJ,F_ZXRY,F_ZXRQ,"+&
	" F_CPRKCLFS,F_FZCRKINFO,F_SCRWH,F_GYLXBH,F_GYLXFLBH,F_CPZQ)"+&
	" select "+&
	" CMCJSCRWGY_LSBH ,CMCJSCRWGY_FLBH,CMCJSCRWCP_WLBH,CMCJSCRWCP_WLMC,CMCJSCRWCP_CPBH,'','',"+&
	" CMCJSCRWGY_GZZX,'','',CMCJSCRWGY_GXBH,'',CMCJSCRWGY_GXSH,'',"+&
	" CMCJSCRWCP_YJJF,CMCJSCRWGY_GXZT,CMCJSCRWGY_KGRY,'',CMCJSCRWGY_KGRQ,"+&
	" CMCJSCRWGY_WGRY,'',CMCJSCRWGY_WGRQ,"+&
	" '','','','',CMCJSCRWGY_ZXRY,CMCJSCRWGY_ZXRQ,"+&
	" '','',CMCJSCRWCP_SCRWH,CMCJSCRWGY_GYLXBH,CMCJSCRWGY_GYLXFLBH,'' "+&
	" from CMCJSCRWGY,CMCJSCRWCP "+&
	" where CMCJSCRWGY_LSBH = CMCJSCRWCP_LSBH "

// 产品编号，理论上产品编号是一定存在的  	
If not isnull(isCpbh) and trim(isCpbh) <> '' Then
	lsSql+= " and CMCJSCRWCP_CPBH='"+isCpbh+"'"
End If

// 包含未执行，即所有的都查询出来
If isBhwwg = '1'  Then
	
Else // 不包含把未完工的去掉即可
	lsSql+= "and CMCJSCRWGY_GXZT<>'G0' and CMCJSCRWGY_GXZT<>'G7' "
End If

// 包含已裁剪，即所有的都查询出来
If isBhycj = '1' Then
	
Else // 不包含已裁剪，即把裁剪的过滤掉
	lsSql+= " and CMCJSCRWGY_GXZT <> 'G6' "
End If

lsSql += " order by CMCJSCRWGY_GXSH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","插入待查询数据时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If


lsSql = " UPDATE "+iscxtbl+" SET F_GZZX = CMSCZJHMX_GZZX FROM CMSCZJHMX,CMSCZJHRW,CMCJSCRWGY   "+&
		 " WHERE   CMCJSCRWGY_CPBH=CMSCZJHRW_CPBH   AND  CMCJSCRWGY_GXSH = CMSCZJHRW_GXSH AND CMSCZJHMX_JHLS =CMSCZJHRW_JHLS AND CMSCZJHMX_JHFL=CMSCZJHRW_JHFL  "+&
		" AND  CMSCZJHRW_CPBH="+iscxtbl+".F_CPBH  AND CMSCZJHRW_GXSH="+iscxtbl+".F_GXSH  "
  
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","插入待查询数据时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If



// 更新工作中心分类（车间）编号
Choose Case gsKind
	Case 'ORA'
		lsSql = "update "+iscxtbl+" set (F_ZXFLBH) = (select JSGZZX_FLBH from JSGZZX  where "+iscxtbl+".F_GZZX=JSGZZX_ZXBH ) "+&
			"where exists(select 1 from JSGZZX where "+iscxtbl+".F_GZZX=JSGZZX_ZXBH )"
	Case Else
		lsSql = "update "+iscxtbl+" set F_ZXFLBH = JSGZZX_FLBH from JSGZZX  where "+iscxtbl+".F_GZZX=JSGZZX_ZXBH "
End Choose

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工作中心分类编号（车间编号）时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新工作中心分类（车间）名称
Choose Case gsKind
	Case 'ORA'
		lsSql = "update "+iscxtbl+" set (F_ZXFLMC) = (select JSGZZXFL_MC from JSGZZXFL  where "+iscxtbl+".F_ZXFLBH=JSGZZXFL.JSGZZXFL_BH ) "+&
			"where exists(select 1 from JSGZZXFL where "+iscxtbl+".F_ZXFLBH=JSGZZXFL.JSGZZXFL_BH )"
	Case Else
		lsSql = "update "+iscxtbl+" set F_ZXFLMC = JSGZZXFL_MC from JSGZZXFL  where "+iscxtbl+".F_ZXFLBH=JSGZZXFL.JSGZZXFL_BH "
End Choose

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工作中心类别（车间）名称时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新工作中心名称
lsSql = "update " + iscxtbl +&
	" set F_ZXMC=JSGZZX_ZXMC "+&
	" from  CMCJSCRWGY, JSGZZX "+&
	" where "+iscxtbl+".F_GZZX=JSGZZX.JSGZZX_ZXBH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工作中心名称时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新工序名称
lsSql = "update " + iscxtbl +&
	" set F_GXMC=LSGXZD_GXMC "+&
	" from LSGXZD "+&
	" where "+iscxtbl+".F_GXBH=LSGXZD.LSGXZD_GXBH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工序名称时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新工序描述/工序周期
Choose Case gsKind
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

// 更新炉次号（生产批次），计划开始日期、计划结束日期
lsSql = "update " + iscxtbl +&
	" set F_SCPC=CMSCZJHMX_SCPC,F_JHKSRQ=CMSCZJHMX_KSRQ,F_JHJSRQ=CMSCZJHMX_JSRQ "+&
	" from CMSCZJHMX,CMSCZJHRW "+&
	" where "+iscxtbl+".F_CPBH=CMSCZJHRW.CMSCZJHRW_CPBH "+&
	" and  "+iscxtbl+".F_GXSH=CMSCZJHRW.CMSCZJHRW_GXSH "+&
	" and CMSCZJHRW.CMSCZJHRW_JHLS = CMSCZJHMX.CMSCZJHMX_JHLS"

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新炉次号、计划开始日期、计划结束日期时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If
//


//车间派工单编制日期
lsSql = "update " + iscxtbl +&
	" set F_CJPGDRQ=CMSCZJH_BZRQ,F_CJPGDBH=CMSCZJH_JHBH "+&
	" from CMSCZJHRW,CMSCZJH "+&
	" where "+iscxtbl+".F_CPBH=CMSCZJHRW.CMSCZJHRW_CPBH "+&
	" and  "+iscxtbl+".F_GXSH=CMSCZJHRW.CMSCZJHRW_GXSH "+&
	" and CMSCZJHRW.CMSCZJHRW_JHLS = CMSCZJH.CMSCZJH_JHLS  "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新编制日期时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新检验信息
Choose Case gsKind
	Case 'ORA'
		// Oracle暂时不写了，时间关系
	Case Else
		lsSql = "update "+iscxtbl+" set F_JJRY=CMCJSCRWZJ_JJRY,F_JJSJ=CMCJSCRWZJ_JJSJ,F_JYRY=CMCJSCRWZJ_JYRY,F_JYSJ=CMCJSCRWZJ_JYWCSJ"+&
			" from CMCJSCRWZJ  "+&
			" where "+iscxtbl+".F_LSBH=CMCJSCRWZJ.CMCJSCRWZJ_LSBH and "+iscxtbl+".F_FLBH=CMCJSCRWZJ.CMCJSCRWZJ_FLBH"
End Choose

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新质检信息时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新入库信息
Choose Case gsKind
	Case 'ORA'
		// Oracle的先不写了，时间比较紧张
	Case Else
		lsSql = "update "+iscxtbl+" set F_CPRKCLFS=CMCJSCRWCP_CPRKCLFS,F_FZCRKINFO = CMCJSCRWCP_FZCRKINFO "+&
			" from CMCJSCRWCP,CMCJSCRWGY where CMCJSCRWCP.CMCJSCRWCP_LSBH=CMCJSCRWGY.CMCJSCRWGY_LSBH "+&
			" and CMCJSCRWCP.CMCJSCRWCP_SFRK='1' and CMCJSCRWGY.CMCJSCRWGY_GXZT='G4' "+&
			" and "+iscxtbl+".F_LSBH=CMCJSCRWGY.CMCJSCRWGY_LSBH and "+iscxtbl+".F_FLBH=CMCJSCRWGY.CMCJSCRWGY_FLBH"
End Choose

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新入库信息时出错！"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

Return 1