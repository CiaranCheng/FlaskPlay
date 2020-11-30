// 创建车间派工单
string lsSql,lsErr // 执行sql、err
nvo_select lnvoSelect
long llcjpgdFlsl
string lsCjpgdLsbh
string lsDate,lsTime // 日期、时间
string lsXgsj // 修改时间
string lsCjpgdDjbh // 生成的车间派工单的单据编号
n_ds lndsfordjbh // 生成车间派工单单据编号
n_bhff_bhcreate lnBhff //单据编号服务
long llRow
string lsParm // 参数
string lsGzzx,lsScpc // 设备编号、炉次号
string lsKsrq,lsJsrq // 开始日期、结束日期

// 创建车间派工单
// 形成车间派工单所需要的数据

// 临时表清空
lsSql = "truncate table "+iscjpgd1TempTable
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

lsSql = "truncate table "+iscjpgd2TempTable
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

lsSql = "truncate table "+iscjpgd3TempTable
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","清空临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 把符合条件的数据插入到车间派工单的表头临时表、表体、单件临时表中

// 车间派工单任务表
// 序号后续使用F_ID进行更新
// 流水编号、分录编号先置空，后续使用2表进行回写，使用物料编号、工序编号作为关联关系
// F_SCPC，炉次号后续更新
// F_SL数量就是1
lsSql = " insert into "+iscjpgd3TempTable+&
	" (F_JHLS,F_JHFL,F_XH, "+&
	" F_WLBH,F_CPBH,F_GXSH,F_SCPC,F_GXBH, "+&
	" F_RWLS,F_RWBH,F_SFXD,F_CPRWZXZT, "+&
	" F_GYLXBH,F_GYLXFLBH,F_SCRWH,F_SL) "+&
	" select '','','', "+&
	" F_WLBH,F_CPBH,F_GXSH,'',F_GXBH,"+&
	" F_RWLS,F_RWBH,'0','0',"+&
	" F_GYLXBH,F_GYLXFLBH,F_SCRWH,1 "+&
	" from "+iscjpgdSelTempTable
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","归集数据到临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 车间派工单生产任务序号的处理
lsSql = " update " +iscjpgd3TempTable+&
	" set F_XH = right(cast('000000000'+convert(nvarchar,F_ID) as nvarchar(20)),10) "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成序号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 将生产任务信息根据物料编号工序编号进行汇总形成2表信息
// 按照物料编号、工序编号进行汇总
// 流水后续生成，分录后续根据f_id更新
// 工作中心、生产批次即炉号、炉次号后续更新
// 开始日期、结束日期后续根据炉次号进行更新，炉次字典中取
lsSql = "insert into "+iscjpgd2TempTable+"( "+&
	" F_JHLS,F_JHFL,F_GZZX,F_SCPC, "+&
	" F_WLBH,F_SL,F_GXBH,F_KSRQ,F_JSRQ, "+&
	" F_XDPGBZ,F_XDBZ,F_ZXZT,F_BZ )  "+&
	" select '','','','',"+&
	" F_WLBH,sum(F_SL),F_GXBH,'','',"+&
	" '0','0','0','车间装炉，PC端勾选下达生成' "+&
	" from "+iscjpgd3TempTable+" A "+&
	" group by A.F_WLBH,A.F_GXBH "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","归集数据到临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 获取表体数据行数，如果为0则不处理分录号和表头，外部已判断过，此处应该必然是有数据的
lsSql = "select count(1) from " + iscjpgd2TempTable
lnvoSelect.of_select( lsSql,llcjpgdFlsl,lsErr)
if isnull(llcjpgdFlsl) then
	llcjpgdFlsl = 0
end if

// 根据表体行数判断是否需要生成表体分录号已经表头数据，如果为0则跳过。
if llcjpgdFlsl > 0 then
	// 生成流水编号
	lsCjpgdLsbh = gsf_getnbbm("CMSCZJH")
	if lsCjpgdLsbh = '' then
		Rollback;
		messagebox("提示信息","获取派工单流水编号失败！")
		return -1
	end if
	
	// 车间派工单单件流水编号处理
	lsSql = " update " +iscjpgd3TempTable+ " set F_JHLS ='"+lsCjpgdLsbh+"' "
	if gfexesql(lsSql,sqlca) < 0 then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新流水编号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		return -1
	end if
	
	// 车间派工单表体流水编号处理
	lsSql = " update " +iscjpgd2TempTable+ " set F_JHLS ='"+lsCjpgdLsbh+"' "
	if gfexesql(lsSql,sqlca) < 0 then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新流水编号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		return -1
	end if
	
	// 车间派工单表体分录编号的处理
	lsSql = " update " +iscjpgd2TempTable+&
		" set F_JHFL = right(cast('000000000'+convert(nvarchar,F_ID) as nvarchar(20)),10) "
	if gfexesql(lsSql,sqlca) < 0 then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","生成分录号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		return -1
	end if
	
	// 表体分录更新到单件表中
	lsSql = " update A "+&
		" set A.F_JHFL=B.F_JHFL "+&
		" from "+iscjpgd3TempTable+" A,"+iscjpgd2TempTable+" B "+&
		" where A.F_WLBH=B.F_WLBH "+&
		" and A.F_GXBH=B.F_GXBH"
	if gfexesql(lsSql,sqlca) < 0 then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","操作临时表数据时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		return -1
	end if
	
	// 申请单表头生成处理
	// 获取系统时间
	//	gfgetsysdate(lsDate,lsTime)
	//	lsXgsj = lsDate+' '+lsTime
	
	// 车间派工单表头信息临时表
	lsSql = "insert into "+iscjpgd1TempTable+"( F_JHLS,F_JHBH,F_BZRY,F_BZRQ ) "+&
		" values(  '"+lsCjpgdLsbh+"','','"+gsusername+"','"+gsCwrq+"' ) "
	if gfexesql(lsSql,sqlca) < 0 then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","归集数据到临时表时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		return -1
	end if
	
	// 生成车间派工单的单据编号
	if isvalid(lndsfordjbh) then
		lndsfordjbh.reset()
	else
		lndsfordjbh = create n_ds
		lndsfordjbh.dataobject = "dw_cj_xacm_cjpgd_master_fordjbh"
	end if
	
	llRow = lndsfordjbh.insertrow(0)
	lndsfordjbh.setitem(llRow,"cmsczjh_bzrq",gsCwrq)
	lndsfordjbh.setitem(llRow,"cmsczjh_bzry",gsusername)
	lndsfordjbh.setitem(llRow,"cmsczjh_jhls",lsCjpgdLsbh)
	
	// 生成单据编号
	lnBhff.uf_createbh("CMSCZJH",lsCjpgdDjbh,lndsfordjbh,1,lsErr,sqlca)
	if lsCjpgdDjbh = '' then
		Rollback;
		messagebox("提示信息","未取得单据编号!"+lsErr)
		return -1
	end if
	
	// 将生成的单据编号更新到临时表中
	lsSql = " update " +iscjpgd1TempTable+&
		" set F_JHBH = '"+lsCjpgdDjbh+"' "
	if gfexesql(lsSql,sqlca) < 0 then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新单据编号时时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		return -1
	end if
end if

// 炉次信息选择
// 考虑是弹窗选择炉次，还是直接在界面上选择炉次
// 弹窗选择

lsParm = ""
openwithparm(w_js_zd_xacm_lcda_select,lsParm)


lsParm = message.stringparm
if isnull(lsParm) or trim(lsParm) = "" then
	lsParm = "cancel"
end if

if lsParm = "cancel" then
	Rollback;
	messagebox("提示信息","获取炉次信息失败！")
	return -1
end if

lsGzzx = get_token(lsParm,";")
lsScpc = get_token(lsParm,";")

// 根据炉次号获取炉次开始日期、结束日期
Select CMSCLCXX_JHKGRQ,CMSCLCXX_JHWGRQ
	Into :lsKsrq,:lsJsrq
	From CMSCLCXX
	Where CMSCLCXX_LCH = :lsScpc;
if isnull(lsKsrq) or trim(lsKsrq) = "" then
	lsKsrq = ""
end if
if isnull(lsJsrq) or trim(lsJsrq) = "" then
	lsJsrq = ""
end if

// 界面维护信息更新到临时表中
// 更新
// 工作中心、生产批次即炉号、炉次号后续更新
// 开始日期、结束日期后续根据炉次号进行更新，炉次字典中取
lsSql = "update "+iscjpgd2TempTable+&
	" set F_GZZX='"+lsGzzx+"',F_SCPC='"+lsScpc+"', "+&
	" F_KSRQ='"+lsKsrq+"',F_JSRQ='"+lsJsrq+"' "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","归集数据到临时表--更新炉次相关信息时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

lsSql = "update "+iscjpgd3TempTable+&
	" set F_SCPC='"+lsScpc+"' "
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","归集数据到临时表--更新炉次相关信息时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 真正形成系统中的单据
// 事务开始
sqlca.autocommit = false

// 形成车间派工单
// 临时表插入实际表中：单件信息
lsSql = " insert into CMSCZJHRW(CMSCZJHRW_JHLS,CMSCZJHRW_JHFL,CMSCZJHRW_XH, "+&
	" CMSCZJHRW_CPBH,CMSCZJHRW_GXSH,CMSCZJHRW_SCPC,CMSCZJHRW_GXBH, "+&
	" CMSCZJHRW_RWLS,CMSCZJHRW_RWBH,CMSCZJHRW_SFXD,CMSCZJHRW_CPRWZXZT, "+&
	" CMSCZJHRW_GYLXBH,CMSCZJHRW_GYLXFLBH,CMSCZJHRW_SCRWH ) "+&
	" select F_JHLS,F_JHFL,F_XH, "+&
	" F_CPBH,F_GXSH,F_SCPC,F_GXBH, "+&
	" F_RWLS,F_RWBH,F_SFXD,F_CPRWZXZT, "+&
	" F_GYLXBH,F_GYLXFLBH,F_SCRWH "+&
	" from "+iscjpgd3TempTable
if gfexesql(lsSql,sqlca) = -1 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间派工单单件数据时出错！~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 临时表插入实际表中：表体信息
lsSql = " insert into CMSCZJHMX(CMSCZJHMX_JHLS,CMSCZJHMX_JHFL,CMSCZJHMX_GZZX,CMSCZJHMX_SCPC,"+&
	" CMSCZJHMX_WLBH,CMSCZJHMX_SL,CMSCZJHMX_GXBH,CMSCZJHMX_KSRQ,CMSCZJHMX_JSRQ,"+&
	" CMSCZJHMX_XDPGBZ,CMSCZJHMX_XDBZ,CMSCZJHMX_ZXZT,CMSCZJHMX_BZ) "+&
	" select F_JHLS,F_JHFL,F_GZZX,F_SCPC,"+&
	" F_WLBH,F_SL,F_GXBH,F_KSRQ,F_JSRQ,"+&
	" F_XDPGBZ,F_XDBZ,F_ZXZT,F_BZ "+&
	" from "+iscjpgd2TempTable
if gfexesql(lsSql,sqlca) = -1 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间派工单表体数据时出错！~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 临时表插入实际表中：表头信息
lsSql = " insert into CMSCZJH(CMSCZJH_JHLS,CMSCZJH_JHBH,CMSCZJH_BZRY,CMSCZJH_BZRQ)"+&
	" select F_JHLS,F_JHBH,F_BZRY,F_BZRQ "+&
	" from "+iscjpgd1TempTable
if gfexesql(lsSql,sqlca) = -1 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成车间派工单表头数据时出错！~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 进行生产任务状态的更新，更新为已分配
lsSql = "update CMSCRW "+&
	" set CMSCRW_FPBZ='1',CMSCRW_FPRQ='"+gsCwrq+"',CMSCRW_FPRY='"+gsusername+"'"+&
	" from "+ iscjpgdSelTempTable+&
	" where CMSCRW.CMSCRW_LSBH="+iscjpgdSelTempTable+".F_RWLS"
if gfexesql(lsSql,sqlca) < 0 then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新生产任务的分配标志时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	return -1
end if

// 提交数据库
// 事务结束
Commit;

return 1
