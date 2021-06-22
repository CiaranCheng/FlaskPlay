//====================================================================
// 事件: w_cj_xacm_xdgxxz.open()
//--------------------------------------------------------------------
// 描述: 下道工序选择窗口
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  long
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2017年09月14日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
string lsParm
string lsLsbh,lsFlbh
string lsSqlSelect
String lsGxsh
String lsGylxbh,lsGylxFlbh
string vssql ,vserror

lsParm = message.stringparm
//lsLsbh = get_token(lsParm,";")
//lsFlbh = get_token(lsParm,";")
lsGylxbh = get_token(lsParm,";")
lsGylxFlbh = get_token(lsParm,";")
lsGxsh = get_token(lsParm,";")
isusedgxtbl = get_token(lsParm,";") //20210526 



 
// 获取数据源
isSqlSelect = dw_gylx.describe("DataWindow.Table.Select")

uf_setformat()

if not isnull(isusedgxtbl) and trim(isusedgxtbl) <> '' then
	vssql = "INSERT INTO " + isusedgxtbl +" (F_CPBH,F_GXBH,F_GXSH,F_BZ ) SELECT CMCJSCRWGY_CPBH, CMCJSCRWGY_GXBH,CMCJSCRWGY_GXSH,'1' FROM CMCJSCRWGY WHERE CMCJSCRWGY_GXZT IN( 'G5' ,'G3')  AND  EXISTS(SELECT 1 FROM "+isusedgxtbl+" WHERE F_CPBH = CMCJSCRWGY_CPBH) "
	If gfexesql(vsSql,sqlca) < 0 Then
		vserror = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+vserror+"~r~n"+ vsSql)
		gf_closehelp()
		Return 
	End If	
	vssql = "INSERT INTO " + isusedgxtbl +" (F_CPBH,F_GXBH,F_GXSH,F_BZ ) SELECT '', F_GXBH,F_GXSH,'2' FROM "+isusedgxtbl+" WHERE F_BZ ='1'  GROUP BY F_GXBH,F_GXSH "
	If gfexesql(vsSql,sqlca) < 0 Then
		vserror = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+vserror+"~r~n"+ vsSql)
		gf_closehelp()
		Return 
	End If	
	vssql = "DELETE FROM " + isusedgxtbl +"   WHERE F_BZ ='0'  OR F_BZ = '1'   "
	If gfexesql(vsSql,sqlca) < 0 Then
		vserror = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+vserror+"~r~n"+ vsSql)
		gf_closehelp()
		Return 
	End If		
end if


//lsSqlSelect = isSqlSelect + " and CMCJSCRWGY_LSBH='"+lsLsbh+"' and CMCJSCRWGY_GXSH>'"+lsGxsh+"' "
if not isnull(isusedgxtbl) and trim(isusedgxtbl) <> '' then //20210526 
	lsSqlSelect = isSqlSelect + " and CMBZGYLX_GYLXBH='"+lsGylxbh+"'   "
else
	lsSqlSelect = isSqlSelect + " and CMBZGYLX_GYLXBH='"+lsGylxbh+"' and CMBZGYLX_GXSH>'"+lsGxsh+"' "	
end if

//lsSqlSelect = isSqlSelect + " and CMBZGYLX_GYLXBH='"+lsGylxbh+"' and CMBZGYLX_GXSH>'"+lsGxsh+"' "

if not isnull(isusedgxtbl) and trim(isusedgxtbl) <> '' then //20210526 
	//f_test(isusedgxtbl,'d:\gxbh.xls',sqlca)
	lsSqlSelect = lsSqlSelect+" AND NOT EXISTS (SELECT 1 FROM  "+isusedgxtbl+"  WHERE F_GXBH = CMBZGYLX_GXBH AND F_GXSH = CMBZGYLX_GXSH )"
end if

lsSqlSelect = gssqltrans(lsSqlSelect)
dw_gylx.modify("Datawindow.Table.Select=~""+lsSqlSelect+"~"")

dw_gylx.settransobject(sqlca)
dw_gylx.retrieve()

//dw_gylx.setsort("CMCJSCRWGY_GXSH asc")
dw_gylx.setsort("CMBZGYLX_GXSH asc")
dw_gylx.sort()

Return 1
