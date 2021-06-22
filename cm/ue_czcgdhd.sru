//==============================================================================
// Event: ue_cgrkd_czcgdhd::u_kc_dj_cgrkd()
//------------------------------------------------------------------------------
// Description: 采购入库单参照采购到货单
//------------------------------------------------------------------------------
// Arguments:(None)
//------------------------------------------------------------------------------
// Returns:  None
//------------------------------------------------------------------------------
// Author:	gaowd		Date: 2007.10.12
//------------------------------------------------------------------------------
// Modify History: 
//	
//==============================================================================

String vslsbh,vslybz,vs_lbbh,vsbmbh,vszgbh,vsdwbh,vs_ckbh,vs_ckbh1,ls_bgdh,vs_dhls,vs_dhfl,vs_dhls1,vs_dhfl1,vszzrq,vstmp
String vs_fllx,vs_xmbh,vs_wlbh,vs_hwbh,vs_pch,vsjjff,vscgjl,vsxsjl,vsQxSQL
int    i
dec    vdmrsl,vd_sl[3],vd_data[4],vd_jhdj,vdjskz,vd_sssl,vd_yssl
long   vl_row,vl_rownum
BOOLEAN VB_SAMEDJ
string vsSQL,vsSyDj,vsflbh,vscopyLsbh,vs_ydhfl,vstemp
n_canzhao_stru stru_canzhao
string vsDJLS[]
string vsddls,vsRegisterLSBH,vsRegisterWhere,vserror
nvo_select lnv_select
string vshwqx,vsErr,vshwgl
int vi_sqlrtn
string vsdwlbqx,vsdwqx,vssqlcz,vscgddls,vscgddfl
if is_action='VIEW' then return

dw_master.accepttext()
//--------------------------------------------------------------------
//if not rb_blue.checked then
//	messagebox("提示信息","只有蓝单可以拷贝到货单!")
//	return 
//end if
//--------------------------------------------------------------------
vslsbh = dw_master.object.kcrkd1_lsbh[dw_master.getrow()]
if isnull(vslsbh) then vslsbh=' '
vslybz = dw_master.object.kcrkd1_ywbs[dw_master.getrow()]
if not isnull(vslsbh) and trim(vslsbh) <> '' and  vslybz <> 'SGLR' and  vslybz<> 'CGDHD' then
	messagebox("提示信息","该入库单由其他单据生成，不能参照到货单!")
	return 
end if

vs_ckbh = dw_master.object.kcrkd1_ckbh[dw_master.getrow()]
//If (isnull(vs_ckbh) or Trim(vs_ckbh)='') Then
//	Messagebox("提示信息","请先确定仓库编号")
//   dw_master.post setcolumn("kcrkd1_ckbh")
//	return
//end if 
	
vs_lbbh = dw_master.object.kcrkd1_lbbh[dw_master.getrow()]
if (isnull(vs_lbbh) or trim(vs_lbbh)='') and is_ljbm='CGRKD' then
	messagebox("提示信息","请先确定业务类别!")
   dw_master.post setcolumn("kcrkd1_lbbh")
	return
end if 

vsTmp = dw_Master.GetItemString(dw_master.getrow(),'kcrkd1_kcywrq')
If IsNull(vsTmp) OR Trim(vsTmp) = '' Then
	MessageBox("提示信息","请首先维护[库存业务日期]信息")
	dw_Master.SetColumn('kcrkd1_kcywrq')
	Return 
End If
vszzrq =vstmp

//Stru_canzhao.is_where = " CGDHD1_PJLX='CGDHD' JCDHD AND CGDHD1_SFQR = '1' AND CGDHD5_RKBZ='1' " 
//Stru_canzhao.is_where = " (CGDHD1_PJLX='CGDHD' or CGDHD1_PJLX='JCDHD') AND CGDHD1_SFQR = '1' AND CGDHD5_RKBZ='1' " 
Stru_canzhao.is_where = " (CGDHD1_PJLX='CGDHD' or CGDHD1_PJLX='JCDHD') AND CGDHD1_SFQR = '1' AND CGDHD1_SHBZ='1' AND CGDHD5_RKBZ='1' " 

vsbmbh = dw_master.object.kcrkd1_bmbh[dw_master.getrow()]
If len(vsbmbh)>0 Then
	Stru_canzhao.is_where += " AND CGDHD1_BMBH='"+vsbmbh+"' "
End if
vszgbh = dw_master.object.kcrkd1_zgbh[dw_master.getrow()]
If Len(vszgbh)>0 Then
	Stru_canzhao.is_where += " AND CGDHD1_ZGBH='"+vszgbh+"' "
End if
vsdwbh = dw_master.object.kcrkd1_dwbh[dw_master.getrow()]
If len(vsdwbh)>0 THen
	Stru_canzhao.is_where += " AND CGDHD1_DDJSF='"+vsdwbh+"' "
End if
//红对红，蓝对蓝。红单增加冲销编号的限制,对于参照蓝到货单制作的红到货没必要退库,红到货已经严格控制只能参照蓝到货的未入库部分
if  rb_blue.checked then
	Stru_canzhao.is_where += " AND CGDHD1_HDBZ='0' " 
	Stru_canzhao.is_where +=" AND CGDHD5_SSSL<>0 AND ROUND((CGDHD5_SSSL - CGDHD5_RKSL -  ABS(CGDHD5_THSL) - CGDHD5_JSKZ),"+String(iisldecn)+")>0 "+&
                        " AND EXISTS(SELECT 1 FROM CGDHD2 WHERE CGDHD2_LSBH=CGDHD5.CGDHD5_LSBH "+&
			               " AND CGDHD2_FLBH=CGDHD5.CGDHD5_YFLBH AND ROUND((CGDHD2_SSSL - CGDHD2_RKSL -  ABS(CGDHD2_THSL)),"+String(iisldecn)+")>0) "

else
	Stru_canzhao.is_where += " AND CGDHD1_HDBZ='1'   AND (CGDHD1_CXBH='' OR CGDHD1_CXBH=' ' OR CGDHD1_CXBH IS NULL) " 
	Stru_canzhao.is_where +=" AND CGDHD5_SSSL<>0 AND ROUND((CGDHD5_SSSL - CGDHD5_RKSL -  ABS(CGDHD5_THSL) - CGDHD5_JSKZ),"+String(iisldecn)+")<0 "+&
                        " AND EXISTS(SELECT 1 FROM CGDHD2 WHERE CGDHD2_LSBH=CGDHD5.CGDHD5_LSBH "+&
			               " AND CGDHD2_FLBH=CGDHD5.CGDHD5_YFLBH AND ROUND((CGDHD2_SSSL - CGDHD2_RKSL -  ABS(CGDHD2_THSL)),"+String(iisldecn)+")<0) "

end if
// 仓库权限
//==============================================================================

string vs_qx
vi_sqlrtn = gif_jxc_getwherestr("KCCKQX",1,vs_qx)
if vi_sqlrtn <= 0 then 
	return 
end if

If len(vs_ckbh)>0 Then
	Stru_canzhao.is_where += " AND (CGDHD5_CKBH='"+vs_ckbh+"' or CGDHD5_CKBH='' OR CGDHD5_CKBH=' ' OR CGDHD5_CKBH IS NULL) "
else
	if isnull(vs_qx) or vs_qx = '' then 
	else
		Stru_canzhao.is_where += "AND (CGDHD5_CKBH "+vs_qx+" or CGDHD5_CKBH='' OR CGDHD5_CKBH=' ' OR CGDHD5_CKBH IS NULL) "		
	end if
ENd if

//往来单位权限
vi_sqlrtn = gif_jxc_getwherestr("GGDWLBQX",1,vs_qx)
vsdwlbqx=get_Token(vs_qx,'@ZDC@')
vsdwqx = get_Token(vs_qx,'@ZDC@')
if len(vsdwqx)>0 then
	Stru_canzhao.is_where  +=" AND  CGDHD1_DDJSF " + vsdwqx
end if

//处理物料类别权限
vsQxSQL=''
For i = 1 to upperBound(is_qx_cols[])
	if lower(is_qx_cols[i])='kcrkd2_wlbh' then
		vsQxSQL = is_qx_cxwhere[i]
		exit
	end if
Next
if trim(vsQxSQL)<>'' and not isnull(vsQxSQL) then
	Stru_canzhao.is_where +=" AND " +vsQxSQL
end if

//清除临时表
vssqlcz = "DELETE FROM "+ isdjcztem
IF gfexesql(vssqlcz,sqlca) = -1 THEN
	rollback;
	MessageBox("提示信息","删除临时表数据时出错："+sqlca.SQLErrText+gsrl+vssql)
	return 
END IF

//将参照过来的记录插入到临时表
for vl_rownum = 1 to dw_detail.rowcount()
	vscgddls= dw_detail.GetItemString(vl_rownum,"kcrkd2_dhls")
	vscgddfl = dw_detail.GetItemString(vl_rownum,"kcrkd2_dhfl")
	if NOT(vscgddls='' or isnull(vscgddls)) then
		vssqlcz = "insert into " + isdjcztem + "(F_LSBH,F_FLH) values('"+vscgddls+"','"+vscgddfl+"')"
		IF gfExeSql(vssqlcz,sqlca) = -1 THEN
			rollback;
			MessageBox("提示信息","插入查询单据时出错："+sqlca.SQLErrText+gsrl+vssql)
			return 
		END IF
	end if
next
stru_canzhao.is_Where +=" @ NOT EXISTS (SELECT 1 FROM " + isdjcztem + " WHERE " + isdjcztem + ".F_LSBH=CGDHD5_LSBH AND " + isdjcztem + ".F_FLH=CGDHD5_FLBH ) "
//For i = 1 to upperBound(is_qx_cols[])
//	if trim(is_qx_cxwhere[i]) <> '' and not isnull(is_qx_cxwhere[i]) and is_qx_cols[i] <> 'KCRKD1_CKBH' then 
//		if  is_qx_cols[i] = 'KCRKD1_DWBH'  then 
//			if is_kc_dqxzdw = '1' then
//				Stru_canzhao.is_where +=" AND ZWWLDW_DWBH " +is_qx_cxwhere[i]
//			else
//				Stru_canzhao.is_where +=" AND ZWWLDW_LBBH " +is_qx_cxwhere[i]
//			end if
//			
//		else
//			Stru_canzhao.is_where +=" AND " +is_qx_cxwhere[i]
//		end if
//	end if 
//Next

//Stru_canzhao.is_where +=" AND CGDHD5_SSSL<>0 AND ROUND((ABS(CGDHD5_SSSL - CGDHD5_RKSL -  ABS(CGDHD5_THSL) - CGDHD5_JSKZ)),"+String(iisldecn)+")>0 "+&
//                        " AND EXISTS(SELECT 1 FROM CGDHD2 WHERE CGDHD2_LSBH=CGDHD5.CGDHD5_LSBH "+&
//			               " AND CGDHD2_FLBH=CGDHD5.CGDHD5_YFLBH AND ROUND((ABS(CGDHD2_SSSL - CGDHD2_RKSL -  ABS(CGDHD2_THSL))),"+String(iisldecn)+")>0) "
//
//------------------------------------------------------------------------------
//参照窗口显示内容构造
//------------------------------------------------------------------------------
stru_canzhao.is_val_cols[1]   = 'F_BMBH'
stru_canzhao.is_val_vals[1]   = vsbmbh
stru_canzhao.is_qx_cxwhere[1] = is_qx_cxwhere[1]

stru_canzhao.is_val_cols[2]   = 'F_ZGBH'
stru_canzhao.is_val_vals[2]   = vszgbh
stru_canzhao.is_qx_cxwhere[2] = is_qx_cxwhere[2]

stru_canzhao.is_val_cols[3]   = 'F_QSRQ'
stru_canzhao.is_val_vals[3]   = Left(Gscwrq,6) + '01'
stru_canzhao.is_qx_cxwhere[3] = ''

stru_canzhao.is_val_cols[4]   = 'F_ZZRQ'
stru_canzhao.is_val_vals[4]   = vszzrq
stru_canzhao.is_qx_cxwhere[4] = ''

stru_canzhao.is_val_cols[5]   = 'F_DWBH'
stru_canzhao.is_val_vals[5]   = vsdwbh
stru_canzhao.is_qx_cxwhere[5] = ''

stru_canzhao.is_validCols[1] = 'cgdhd1_ddjsf'
stru_canzhao.is_validCols[2] = 'cgdhd1_bmbh'
stru_canzhao.is_validCols[3] = 'cgdhd1_zgbh'
//stru_canzhao.is_validCols[4] = 'cgdhd5_CKbh'   //mod by renjunguo 到货单有可能不录入仓库，限制没多大意义
	//is_validCols[4] = 'cgdd1_ddlx'
	stru_canzhao.is_Valid_error  = '所选择单据的单位、部门、人员、仓库必须一致。'	

//------------------------------------------------------------------------------
//设置精度
//------------------------------------------------------------------------------
stru_canzhao.ii_decn[1] = iiSldecn
stru_canzhao.ii_decn[2] = iiJedecn
stru_canzhao.ii_decn[3] = iiDjdecn
stru_canzhao.ii_decn[4] = iizdyxdecn
stru_canzhao.ii_decn[5] = iinssldecn
//------------------------------------------------------------------------------
//返回值初始
//------------------------------------------------------------------------------
 if isnull(psczbz) then  psczbz=''
 if psczbz=''  then
	Openwithparm(w_kc_dj_cz_cgdhd,stru_canzhao)
	
	if message.StringParm = 'cancel' then return
	stru_canzhao = message.PowerObjectParm
	
	i = stru_canzhao.ids_ds.Rowcount()
	if i < 1 then return
end if

if psczbz='CGDHD' then
   stru_canzhao.ids_ds=ps_czstore
   vsddls= stru_canzhao.ids_ds.Getitemstring(1,"cgdhd5_lsbh")
	vstemp="CGDHD5_LSBH ='"+vsddls+"' AND CGDHD1_LSBH=CGDHD5_LSBH AND  CGDHD5_WLBH = LSWLZD_WLBH AND CGDHD1_DDJSF = ZWWLDW_DWBH AND  CGDHD1_BMBH = KCBMZD_BMBH  and  CGDHD1_ZGBH = ZWZGZD_ZGBH  AND "+Stru_canzhao.is_where
	if gif_exists("CGDHD1,CGDHD5,ZWWLDW,KCBMZD,ZWZGZD,LSWLZD ",vstemp) =0 then
		messagebox("提示信息","此张采购到货单没有审批通过或者已经生成了其他单据，没法生成入库单")
		RETURN 
	end if
end if
//2注册冲突控制
//==============================================================================


vsDJLS[] = stru_canzhao.ids_ds.object.CGDHD5_LSBH.CURRENT


if len(isCZRegister)>0 then 	iuoctjc.uifclear(isCZRegister)
isCZRegister="CGDHCZ" 
for i= 1  to upperBound(vsDjls[])
	vstmp = vsDjls[i]
	if pos(vsRegisterLSBH,vstmp) < 1 then 	vsRegisterLSBH+="'"+vstmp+"',"
next
vsRegisterLSBH=left(vsRegisterLSBH,len(vsRegisterLSBH) - 1)
vsRegisterWhere=" CGDHD1_LSBH FROM CGDHD1 WHERE CGDHD1_LSBH IN ("+vsRegisterLSBH+")"

if iuoctjc.uifregister(is_xtbh,gsusername,isCZRegister,vsRegisterWhere,vserror)= - 1 then
	iuoctjc.uifclear(isCZRegister)
	rollback;
	messagebox("提示信息",vserror)
	gf_closehelp()
	return 
end if


//处理单件
If is_kc_sfsyjh='1' Then
	vsSQL = "DELETE FROM "+isJhMxTbl
	If GfExeSQL(vsSQL,sqlca)<0 Then
		MessageBox("提示信息","删除临时表数据失败："+SQLCA.SQLErrText+"~r~n"+vsSQL)
		Return
	End If
End If

//==============================================================================
// 复制表头数据
//==============================================================================
dw_master.object.kcrkd1_bmbh[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_bmbh")
vs_ckbh1 =vs_ckbh
vs_ckbh = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd5_ckbh")
//if isnull(vs_ckbh) then vs_ckbh=''
//if vs_ckbh<>'' then
//  dw_master.object.kcrkd1_ckbh[1] = vs_ckbh
//end if
if isnull(vs_ckbh) then vs_ckbh=''
if trim(vs_ckbh)='' AND trim(vs_ckbh1)<>''  then vs_ckbh=vs_ckbh1
if trim(vs_ckbh)<>'' then
   dw_master.object.kcrkd1_ckbh[1] = vs_ckbh
  //处理是否记存货帐
	string flag="1"
	SELECT LSCKZD_DXBZ INTO :flag FROM LSCKZD WHERE LSCKZD_CKBH = :vs_ckbh ;
	if flag="1" then
		dw_master.object.kcrkd1_sfjchz[1]="0"
	else
		dw_master.object.kcrkd1_sfjchz[1]="1"
	end if
end if
dw_master.object.kcrkd1_zgbh[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_zgbh")
dw_master.object.kcrkd1_dwbh[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_ddjsf")
dw_master.object.kcrkd1_dwgc[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_dwgc")
dw_master.object.kcrkd1_ywbs[1] = 'CGDHD'
dw_master.object.kcrkd1_bz[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_bz")
if stru_canzhao.ib_sfcz_zyxlm_d= true then //chenjh
	dw_master.object.kcrkd1_c1[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c1")
	dw_master.object.kcrkd1_c2[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c2")
	dw_master.object.kcrkd1_c3[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c3")
	dw_master.object.kcrkd1_c4[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c4")
	dw_master.object.kcrkd1_c5[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c5")
	dw_master.object.kcrkd1_c6[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c6")
	dw_master.object.kcrkd1_c7[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c7")
	dw_master.object.kcrkd1_c8[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c8")
	dw_master.object.kcrkd1_c9[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c9")
	dw_master.object.kcrkd1_c10[1] = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_c10")
	dw_master.object.kcrkd1_u1[1] = stru_canzhao.ids_ds.Getitemdecimal(1,"cgdhd1_u1")
	dw_master.object.kcrkd1_u2[1] = stru_canzhao.ids_ds.Getitemdecimal(1,"cgdhd1_u2")
	dw_master.object.kcrkd1_u3[1] = stru_canzhao.ids_ds.Getitemdecimal(1,"cgdhd1_u3")
	dw_master.object.kcrkd1_u4[1] = stru_canzhao.ids_ds.Getitemdecimal(1,"cgdhd1_u4")
	dw_master.object.kcrkd1_u5[1] = stru_canzhao.ids_ds.Getitemdecimal(1,"cgdhd1_u5")
	dw_master.object.kcrkd1_u6[1] = stru_canzhao.ids_ds.Getitemdecimal(1,"cgdhd1_u6")
end if
//==============================================================================
// 获取汇率
//==============================================================================
string vswbbh,vsbjff
dec vd_hl
int vihldecn
vswbbh = stru_canzhao.ids_ds.Getitemstring(1,"cgdhd1_wbbh")
vd_hl = stru_canzhao.ids_ds.GetitemDecimal(1,"cgdhd1_hl")
if Gfgetconfig('ZW_HLDECN',vstemp) < 0 then  vstemp= '1'
vihldecn = integer(vstemp)
if isnull(vd_hl) then vd_hl = 1
IF vswbbh = gsbwbh THEN
	vd_hl = 1
ELSE
	IF NOT IsNull(vd_hl) AND vd_hl <> 0 THEN
		SELECT LSWBZD_BJFF INTO :vsbjff FROM LSWBZD Where LSWBZD_WBBH = :vswbbh;
		IF vsbjff <> '1' THEN
			vd_hl = 1/vd_hl
		END IF
		vd_hl = Round(vd_hl,vihldecn)
	ELSE
		vd_hl = 1
	END IF
END IF

//==============================================================================
// 复制表体数据
//==============================================================================
FOR i=1 to stru_canzhao.ids_ds.rowcount() 
	 vs_dhls = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_lsbh")
	 vs_dhfl = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_flbh")
	 vs_ydhfl = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_yflbh")
	 VB_SAMEDJ=FALSE
	 vl_row=1
	 do while vl_row <= dw_detail.ROWCOUNT()
		 IF TRIM(dw_detail.getitemstring(vl_row,'KCRKD2_WLBH'))<>'' THEN 
			 vs_dhls1=dw_detail.GetitemString(vl_row,'kcrkd2_dhls')
			 vs_dhfl1=dw_detail.GetitemString(vl_row,'kcrkd2_dHfl')
			 IF vs_dhls=vs_dhls1 and vs_dhfl=vs_dhfl1 then
				VB_SAMEDJ=TRUE
				exit
			 ELSE
				vl_row++
				CONTINUE
			 END IF
			
		 ELSE
			EXIT
		 END IF
	loop
	IF VB_SAMEDJ=TRUE THEN CONTINUE
	IF vl_row > DW_DETAIL.ROWCOUNT() THEN
		vl_row = dw_detail.insertrow(0)
	END IF
	 dw_detail.object.kcrkd2_flbh[vl_row] = string(vl_row,'0000000000')
	 vs_wlbh = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_wlbh")
	 dw_detail.object.kcrkd2_wlbh[vl_row] = vs_wlbh
	 
	 dw_detail.object.kcrkd2_jhls[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_jhls")
	 dw_detail.object.kcrkd2_jhfl[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_jhfl")
	 dw_detail.object.kcrkd2_cgddls[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_ddls")
	 dw_detail.object.kcrkd2_cgddfl[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_ddfl")
	 
	 vs_pch = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_pch")
	 dw_detail.object.kcrkd2_pch[vl_row] = vs_pch

	 dw_detail.accepttext()

	 uf_kcdj_getwlsx(vs_wlbh,vl_row)
	 
	 dw_detail.object.kcrkd2_wlzt[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_wlzt")
	 dw_detail.object.kcrkd2_wlbz[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_wlbz")
	 vs_hwbh = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_hwbh")
	 
	 //制药版质检相关字段处理 wangxiaoyan 20090610
	 if gsproduct = PRO_YYHY then
		dw_detail.object.kcrkd2_zjwc[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zjwc")
		dw_detail.object.kcrkd2_zjjl[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zjjl")
		dw_detail.object.kcrkd2_clfs[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_clfs")
		ls_bgdh=stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_bgdh")
		dw_detail.object.kcrkd2_bgdh[vl_row] = ls_bgdh
		if isnull(ls_bgdh) or trim(ls_bgdh)='' then
			dw_detail.object.kcrkd2_zjzt[vl_row] = '0'//0 未请验,1 请验,2 质检完成,8 免检,9 质检终止
		else
			dw_detail.object.kcrkd2_zjzt[vl_row] = '2'
		end if
	 end if
	 //end 
	 //上面的函数还会判断分录是否自动生成了批次号,如果生成了ib_auto_pch值为true zhangqiang at 20070412
	 //if ib_auto_pch then 
	 If Len(Trim(vs_pch))>0 Then
	 	uf_kcdj_getpcsx(vs_pch,vl_row)
	 End if
	  
	 dw_detail.object.kcrkd2_dhls[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_lsbh")
	 dw_detail.object.kcrkd2_dhfl[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_flbh")
	 
	 vs_fllx = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_fllx")
	 vs_xmbh = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_xgdx")
	 
	 if vs_fllx='PT' then
		dw_detail.object.kcrkd2_tskc[vl_row] = 'Z'    //正常库存
		dw_detail.object.kcrkd2_xgdx[vl_row] = ' '
		uf_kcdj_check_tskc(vl_row,'Z','RKD')
	 elseif vs_fllx='XM' then
		dw_detail.object.kcrkd2_tskc[vl_row] = 'Q'    //项目库存
		dw_detail.object.kcrkd2_xgdx[vl_row] = vs_xmbh
		uf_kcdj_check_tskc(vl_row,'Q','RKD')
	 elseif vs_fllx='DD' then
		dw_detail.object.kcrkd2_tskc[vl_row] = 'E'    //订单库存
		dw_detail.object.kcrkd2_xgdx[vl_row] = vs_xmbh
		dw_detail.object.kcrkd2_ddls[vl_row] = Get_token(vs_xmbh,'@')
		dw_detail.object.kcrkd2_ddfl[vl_row] = vs_xmbh
		uf_kcdj_check_tskc(vl_row,'E','RKD')
	 else
		dw_detail.object.kcrkd2_tskc[vl_row] = 'K'    //寄存库存
		dw_detail.object.kcrkd2_xgdx[vl_row] = vs_xmbh
		Dw_Master.Modify("kcrkd1_sfjchz.protect='1'")
		dw_Master.SetItem(1,'kcrkd1_sfjchz','0')
		uf_kcdj_check_tskc(vl_row,'K','RKD')
	 end if
//	 vdmrsl = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_taxrate")
//	 //如果参照到的税率为0，则从物料字典上取税率 added by sunjsh 2007-04-11
//	 IF vdmrsl=0 THEN
//		 SELECT LSWLZD_ZZSL INTO :vdmrsl FROM LSWLZD WHERE LSWLZD_WLBH=:vs_wlbh;
//    	 if gif_sqlcode(sqlca)<>0 then
//			 MESSAGEBOX("错误信息","取物料字典的税率出错！")
//			 vdmrsl=0
//		 END IF
//	 END IF
//	 dw_detail.setitem(i,"kcrkd2_sl",vdmrsl )
	
	 vdjskz = stru_canzhao.ids_ds.Getitemdecimal(i,"cgdhd5_jskz")
	if isnull(vdjskz) then vdjskz=0
	 dw_detail.setitem( vl_row, "kcrkd2_yssl",  stru_canzhao.ids_ds.Getitemdecimal(i,"cgdhd5_yssl") - vdjskz)
	 vd_yssl = stru_canzhao.ids_ds.Getitemdecimal(i,"cgdhd5_yssl")
	IF is_kc_dwhsff='1' OR is_kc_dwhsff='3' THEN
			vd_sl[1]= stru_canzhao.ids_ds.Getitemdecimal(i,"cgdhd5_yssl") - vdjskz
			gf_pub_jxc_hsdata('KC',vs_wlbh,vs_pch,vd_sl[],vd_data[])  				
			if not IsNull(vd_data[3]) and vd_data[3] <> 0 then
			  dw_detail.setitem( vl_row, "kcrkd2_fyssl1", vd_data[3])
			end if
			if not IsNull(vd_data[2]) and vd_data[2] <> 0 then
				dw_detail.setitem( vl_row, "kcrkd2_fyssl2", vd_data[2])
			end if
	END IF
	
	if not IsNull(vd_data[2]) and vd_data[2] <> 0 then
	else
		vd_sl[1]= stru_canzhao.ids_ds.Getitemdecimal(i,"cgdhd5_yssl") - vdjskz
		 vd_data[3]=stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_fyssl1") 
		 if vd_yssl <> 0 then
			dw_detail.setitem( vl_row, "kcrkd2_fyssl1", vd_sl[1]/vd_yssl*vd_data[3])
		end if
	end if
	if not IsNull(vd_data[2]) and vd_data[2] <> 0 then
	else
		vd_sl[1]= stru_canzhao.ids_ds.Getitemdecimal(i,"cgdhd5_yssl") - vdjskz
		vd_data[2]=stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_fyssl2")
		if vd_yssl <> 0 then
			dw_detail.setitem( vl_row, "kcrkd2_fyssl2", vd_sl[1]/vd_yssl*vd_data[2])
		end if
	end if
		 
	 vd_sl[1]= stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_czsl")
	 vd_data[2]=stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_czfsl1") 
	 dec vd
	 vd=stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_czfsl2")
	 vd_data[3]=stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_czfsl2")
	 vscgjl =stru_canzhao.ids_ds.GetitemString(i,"LSWLZD_CGJL")
	 vsxsjl =stru_canzhao.ids_ds.GetitemString(i,"LSWLZD_XSJL")
	 dw_detail.setitem( vl_row, "kcrkd2_sssl", vd_sl[1])
	 //换算计量单位
	 dw_detail.setitem(vl_row,"kcrkd2_fsssl1",vd_data[2])
	 IF vscgjl = vsxsjl THEN 
	    dw_detail.setitem(vl_row,"kcrkd2_fsssl2",vd_data[3])
	 ELSE
		 gf_jxc_hsdata('KC',vs_wlbh,vd_sl[],vd_data[])
		 dw_detail.setitem(vl_row,"kcrkd2_fsssl2",vd_data[3])
	 END IF 
	 
	 dw_detail.object.kcrkd2_zyx1[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zyx1")
	 dw_detail.object.kcrkd2_zyx2[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zyx2")
	 dw_detail.object.kcrkd2_zyx3[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zyx3")
	 dw_detail.object.kcrkd2_zyx4[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zyx4")
	 dw_detail.object.kcrkd2_zyx5[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_zyx5")	 
	 if stru_canzhao.ib_sfcz_zyxlm_d= true then //chenjh
		 dw_detail.object.kcrkd2_c1[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c1")	 
		 dw_detail.object.kcrkd2_c2[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c2")
		 dw_detail.object.kcrkd2_c3[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c3")
		 dw_detail.object.kcrkd2_c4[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c4")
		 dw_detail.object.kcrkd2_c5[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c5")
		 dw_detail.object.kcrkd2_c6[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c6")
		 dw_detail.object.kcrkd2_c7[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c7")
		 dw_detail.object.kcrkd2_c8[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c8")
		 dw_detail.object.kcrkd2_c9[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c9")
		 dw_detail.object.kcrkd2_c10[vl_row] = stru_canzhao.ids_ds.GetitemString(i,"cgdhd5_c10")
		 dw_detail.object.kcrkd2_u1[vl_row] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_u1")
		 dw_detail.object.kcrkd2_u2[vl_row] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_u2")
		 dw_detail.object.kcrkd2_u3[vl_row] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_u3")
		 dw_detail.object.kcrkd2_u4[vl_row] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_u4")
		 dw_detail.object.kcrkd2_u5[vl_row] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_u5")
		 dw_detail.object.kcrkd2_u6[vl_row] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_u6")
	 end if
//    dw_detail.object.kcrkd2_dj[i] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_dj")
////	 vd_jhdj = dw_detail.object.kcrkd2_jhdj[i]
////	 if isnull(vd_jhdj) or vd_jhdj=0 then
////		 dw_detail.object.kcrkd2_jhdj[i] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")
////	 end if
//	 dw_detail.object.kcrkd2_je[i] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_je")
//	 dw_detail.object.kcrkd2_hsdj[i] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")
//	 dw_detail.object.kcrkd2_hsje[i] = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsje")
//	 dw_detail.object.kcrkd2_se[i]=0
 	//----------------------------------------------------------------------------
	//税率、含税、不含税
	//----------------------------------------------------------------------------
	dec vd_dj,vd_je,vd_hsdj,vd_hsje,vd_se
	 vdmrsl = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_taxrate")
	 
	 //如果参照到的税率为0，则从物料字典上取税率.如果在物料字典上取出合适税率重新计算
	 //相应信息
	 lb_Recalc = false
//	 IF vdmrsl=0 THEN
//		 SELECT LSWLZD_ZZSL INTO :vdmrsl FROM LSWLZD WHERE LSWLZD_WLBH=:vs_wlbh;
//    	 if gif_sqlcode(sqlca)<>0 then
//			 vdmrsl=0
//		 else
//			lb_Recalc = true
//		 END IF
//	 END IF
	 dw_detail.setitem(vl_row,"kcrkd2_sl",vdmrsl )
	 vd_sssl = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_sssl")
	 //需要考虑一下外币汇率问题,前面代码中已经处理使用本币时汇率为1,外币换算=本币*相乘
	 if vd_sssl = vd_sl[1] then   //如果可参照数量与实收数量相等就不重新计算了，用于避免误差
		vd_dj = round(stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_dj")*vd_hl,iidjdecn)
		vd_je = round(stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_je")*vd_hl,iijedecn)
		vd_hsdj = round(stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")*vd_hl,iidjdecn)
		vd_hsje = round(stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsje")*vd_hl,iijedecn)
		vd_se = Round(vd_hsje - vd_je,iidjdecn)
	 else	 
		 if lb_Recalc = false then
			 vd_je    = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_dj")*vd_sl[1]*vd_hl
			 if vd_sl[1] <> 0 then
				 vd_dj    = round(vd_je/vd_sl[1],iidjdecn)
			 else
				 vd_dj    = round(stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_dj")*vd_hl,iidjdecn)
			 end if
			 vd_hsje  =stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")*vd_sl[1]*vd_hl
			 if vd_sl[1] <> 0 then
				 vd_hsdj  = round(vd_hsje/vd_sl[1],iidjdecn)
			 else
				 vd_hsdj = round(stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")*vd_hl,iidjdecn)
			 end if	
			 vd_hsje = Round(vd_hsje,iijedecn)
			 vd_je = Round(vd_je,iijedecn)
			 vd_se    = vd_hsje - vd_je
		 else
			 if is_cg_DJXGLX = '2' then
				vd_hsje  =stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")*vd_sl[1]*vd_hl
				if isnull(vd_hsje) then vd_hsje=0
				if vd_sl[1] <> 0 then
					 vd_hsdj  = vd_hsje/vd_sl[1]
				else
					 vd_hsdj    = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_hsdj")*vd_hl
				end if
				if isnull(vd_hsdj) then vd_hsdj=0			
				vd_dj = Round(vd_hsdj/(1 + vdmrsl/100),iidjdecn)
				vd_je = Round(vd_dj*vd_sl[1],iijedecn)
				vd_hsdj = Round(vd_hsdj,iidjdecn)
				vd_hsje = Round(vd_hsje,iijedecn)
				vd_se = Round(vd_hsje - vd_je,iidjdecn)
			elseif is_cg_DJXGLX='1' then
				vd_je    = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_dj")*vd_sl[1]*vd_hl
				if vd_sl[1] <> 0 then
					 vd_dj    = vd_je/vd_sl[1]
				else
					 vd_dj    = stru_canzhao.ids_ds.GetitemDecimal(i,"cgdhd5_dj")*vd_hl
				end if
				vd_hsdj = Round(vd_dj*(1 + vdmrsl/100),iidjdecn)
				vd_hsje = Round(vd_je*(1 + vdmrsl/100),iijedecn)
				vd_dj = Round(vd_dj,iidjdecn)
				vd_je = Round(vd_je,iijedecn)
				vd_se= round(vd_hsje - vd_je,iijedecn)
			END IF
		 end if
	 end if		 
	 SELECT LSWLZD_JJFF,LSWLZD_JHDJ,LSWLZD_SFDJ INTO :vsjjff,:vd_jhdj,:vsSyDj FROM LSWLZD WHERE LSWLZD_WLBH=:vs_wlbh;
	if vsjjff='6' and vd_dj=0  then
		vd_dj=vd_jhdj
		vd_je = vd_dj * vd_sl[1]
		vd_hsdj = Round(vd_dj*(1 + vdmrsl/100),iidjdecn)
		vd_hsje = Round(vd_je*(1 + vdmrsl/100),iijedecn)
		vd_se= round(vd_hsje - vd_je,iijedecn)
	end if
	 dw_detail.object.kcrkd2_dj[vl_row]   = vd_dj
	 dw_detail.object.kcrkd2_je[vl_row]   = vd_je
	 dw_detail.object.kcrkd2_hsdj[vl_row] = vd_hsdj
	 dw_detail.object.kcrkd2_hsje[vl_row] = vd_hsje
	 dw_detail.object.kcrkd2_se[vl_row]   = vd_se 
//-------------------------end ---------------------------

	 vd_jhdj = dw_detail.object.kcrkd2_jhdj[vl_row]*vd_hl
	 if isnull(vd_jhdj) then vd_jhdj=0
    dw_detail.object.kcrkd2_jhje[vl_row] = round(vd_sl[1]*vd_jhdj,iijedecn)
	 
	 if isnull(vs_ckbh) then vs_ckbh = ''
	 vs_ckbh = trim(vs_ckbh)
	 vs_hwbh=' '
	 if vs_ckbh <>'' and trim(vs_hwbh)='' then 
		 vs_hwbh=' '
		 SELECT LSCKZD_HWGL into :vshwgl FROM LSCKZD WHERE LSCKZD_CKBH = :vs_ckbh ;
		 vs_hwbh=' '
		IF vshwgl = '1' THEN
			vi_sqlrtn = gif_jxc_getwherestr("GGHWQX",1,vshwqx)
			if vi_sqlrtn <= 0 then 
				return  
			end if						
			 vssql = " SELECT KCHWZD_HWBH   FROM KCHWWL, KCHWZD, LSCKZD  WHERE KCHWWL_HWBH = KCHWZD_HWBH  and  KCHWZD_CKBH = LSCKZD_CKBH    "+&
				" and KCHWWL_WLBH = '"+vs_wlbh+"' AND  KCHWZD_CKBH = '"+vs_ckbh+"' AND  LSCKZD_HWGL = '1'  "
			if len(trim((vshwqx)))> 0 then
				vssql = vssql + " AND KCHWZD_HWBH " +vshwqx
			end if	
			lnv_select.of_select(vsSql,vs_hwbh,vsErr)
		END IF
//		 SELECT KCHWZD_HWBH  into :vs_hwbh FROM KCHWWL, KCHWZD, LSCKZD  WHERE KCHWWL_HWBH = KCHWZD_HWBH  and  KCHWZD_CKBH = LSCKZD_CKBH  and  
//				KCHWWL_WLBH = :vs_wlbh AND  KCHWZD_CKBH = :vs_ckbh AND  LSCKZD_HWGL = '1'  ;
	end if
	if isnull(vs_hwbh) or vs_hwbh = '' then vs_hwbh=' '
	dw_detail.object.kcrkd2_hwbh[vl_row] = vs_hwbh
	If vsSyDj = '1' AND is_kc_sfsyjh='1' Then
			vsFlbh = dw_detail.GetItemString(vl_row,"kcrkd2_flbh")

			vsSQL = "INSERT INTO "+isJhMxTbl+"(KCJHB_LSBH,KCJHB_FLBH,KCJHB_JH,KCJHB_SL,KCJHB_FSL1,KCJHB_FSL2,KCJHB_F1,"+&
					  "KCJHB_F2,KCJHB_F3)"+&
					  "SELECT '"+vslsbh+"','"+vsFlbh+"',CGDHD3_JH,CGDHD3_SL,CGDHD3_FSL1,CGDHD3_FSL2,CGDHD3_LSBH,"+&
					  "CGDHD3_FLBH,CGDHD3_JH "+&
					  "FROM CGDHD3 "+&
					  "WHERE CGDHD3_LSBH='"+vs_dhLs+"' AND CGDHD3_FLBH='"+vs_ydhFl+"'"
			If GfExeSQL(vsSQL,SQLCA)<0 Then
				MessageBox("提示信息","复制单据件号信息失败："+SQLCA.SQLErrText+"~r~n"+vsSQL)
				Return 
			End If
		End If
	
NEXT



//==============================================================================
// 其它后续处理
//==============================================================================

uf_fillfl(0)

of_buttonenable("m_fl_add",false)
of_buttonenable("m_fl_insert",false)
vsdwbh = dw_master.object.kcrkd1_dwbh[dw_master.getrow()]
if not isnull(vsdwbh) and trim(vsdwbh) <> '' then
	dw_master.modify("kcrkd1_dwbh.protect=1")
end if

vsbmbh = dw_master.object.kcrkd1_bmbh[dw_master.getrow()]
if not isnull(vsbmbh) and trim(vsbmbh) <> '' then
	dw_master.modify("kcrkd1_bmbh.protect=1")
end if
vszgbh = dw_master.object.kcrkd1_zgbh[dw_master.getrow()]
if not isnull(vszgbh) and trim(vszgbh) <> '' then
	dw_master.modify("kcrkd1_zgbh.protect=1")
end if

dw_detail.modify("kcrkd2_wlbh.protect=1")
//dw_Detail.Modify("kcrkd2_yssl.protect=1")
//dw_detail.modify("kcrkd2_tskc.protect=1")
//dw_detail.modify("kcrkd2_xgdx.protect=1")
//dw_detail.modify("kcrkd2_wlzt.protect=0")
//dw_detail.modify("kcrkd2_wlbz.protect=0")

//参照后,由于字段不触发itemchanged事件,重新生成单据编号
string ls_bh
iuo_bhff.uf_createbh(is_bhff,ls_bh,dw_master,SQLCA)
dw_master.SetItem(1,is_m_col_djbh,ls_bh)

//平台公式触发
If IsValid(inv_createform) Then
	inv_createform.Uf_form_recaculate()
End If

of_buttonenable("m_save",true)
rb_blue.enabled = false
rb_red.enabled = false
dw_detail.setredraw(true)
