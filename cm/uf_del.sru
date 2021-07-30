//==============================================================================
// Function: u_js_zd_cmbzgylxzd::uf_del()
//------------------------------------------------------------------------------
// Description: 
//------------------------------------------------------------------------------
// Arguments:(None)
//------------------------------------------------------------------------------
// Returns:  integer
//------------------------------------------------------------------------------
// Author:	yukk		Date: 2017.xx.xx
//------------------------------------------------------------------------------
// Modify History: 
//	
//==============================================================================
dwItemStatus vdisTmp
long row,vlHandle,vlused
string vssql,vsErr
string vsCurTable,vsTmp
string lsgylxbh
string lsSql,lsErr
vsTmp=tv_1.data

vsCurTable=tv_1.CurrentTable
if pos(isTTable,'::')>0 then
	if vsCurTable='t1' then
		MessageBox("提示信息","只能在明细类别中删除工艺路线！")
		return 0
	end if
end if

if vsTmp="" or isnull(vsTmp) then 
	MessageBox("提示信息","工艺路线无效，无法删除！")
	return 0
end if
//判断是否可以删除
if uf_validatedelete()<1 then return 0

row = dw_1.getrow()
lsGylxbh = dw_1.getitemstring(row,"cmbzgylxbt_gylxbh")
if row <= 0 then return 0
// 添加使用校验  20210707 mod by chengxsh
SELECT COUNT(1) INTO :vlused FROM CMCJSCRWGY
	WHERE CMCJSCRWGY_GYLXBH = :lsGylxbh ;

if vlused > 0 then
    MessageBox('提示信息','该条工艺路线已投入使用，不可删除')
    return	0
end if
//
if MessageBox("提示信息","确实要删除该记录吗？",Question!,YesNo!,2)=2 then
	return	0
end if

dw_1.SetRedraw(false)

vdisTmp = dw_1.GetItemStatus(row,0,Primary!)

if vdisTmp=New! or vdisTmp=NewModified! then 
	dw_1.deleterow(row)
	tv_1.EVENT SelectionChanged (tv_1.currenthandle,tv_1.currenthandle)
	dw_1.SetRedraw(True)
	return 1
end if

sqlca.autocommit=false

dw_1.DeleteRow(dw_1.GetRow())

If dw_1.update() = -1 Then
	Rollback;
	messagebox("提示信息","删除工艺路线［"+tv_1.name+"］失败,~r~n"+sqlca.sqlerrtext)	
	return -1
ENd If
lsSql = "delete from cmbzgylx "+&
	"where cmbzgylx_gylxbh = '"+lsgylxbh+"' "
If gfexeSql(lsSql,Sqlca) < 0 Then
	lsErr = Sqlca.sqlerrtext
	MessageBox("提示信息","删除工艺路线列表出错！"+lsErr+"~r~n"+ lsSql)
	rollback;
	return -1
End If
commit;

if vdisTmp<>New! and vdisTmp<>NewModified! and ibTUpdate then 
	tv_1.DeleteItem()
end if

if vsTmp="" or isnull(vsTmp) then
	uf_add()
else
	tv_1.EVENT SelectionChanged (tv_1.currenthandle,tv_1.currenthandle)
	dw_1.SetRedraw(True)
	return 1
end if

return 1