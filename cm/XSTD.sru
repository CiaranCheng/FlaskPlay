//==============================================================================
// Function: u_kc_dj_xsckd::uf_xsckd_gxxstd()
//------------------------------------------------------------------------------
// Description: 销售出库单更新销售提单
//------------------------------------------------------------------------------
// Arguments: 
//		value    	string	ps_action		当前操作
//		reference	string	ps_error 		错误提示
//------------------------------------------------------------------------------
// Returns:  integer －1失败 ；1 成功
//------------------------------------------------------------------------------
// Author:	gaowd		Date: 2007.11.01
//------------------------------------------------------------------------------
// Modify History: 
//	
//==============================================================================
string vslsbh,vssql,vsthdh,vsgxtd,vsflag,vstdls,vstdfl,vswlbh,vsjz,vsTdlx
string vsAllTdls,vshdbz,vstdyl,vstemp
long vlrow,vlcnt
string vsDwbh,vsRybh,vsfalgbz,ls_pch,vsexists
int i,xsjedecn,vidjzzsdecn,vidjptsdecn
dec vdcksl,vdzsl
datastore vds_tdls
//销售精度，为了更新提单用
SELECT  LSWBZD_JD into :xsjedecn  FROM LSWBZD WHERE LSWBZD_BWB='1';
if isnull(xsJedecn) then xsJedecn = 2

if gfGetConfig("XS_PTSDECN",vsTemp)<0 then
	vidjptsdecn = 4
else
	vidjptsdecn = integer(vsTemp)
end if
//------------------------------------------------------------------------------
//普通税精度：用于销售单据中含税单价精度
//------------------------------------------------------------------------------
if gfGetConfig("XS_ZZSDECN",vsTemp)<0 then
	vidjzzsdecn = 2
else
	vidjzzsdecn = integer(vsTemp)
end if
vlrow=dw_master.getrow()
vslsbh=dw_master.getitemstring(vlrow,"kcckd1_lsbh")
vstdls=dw_master.getitemstring(vlrow,"kcckd1_tdls")
vsgxtd=dw_master.getitemstring(vlrow,"kcckd1_gxtd")
vsthdh=dw_master.getitemstring(vlrow,"kcckd1_thdh")
vsDwbh = dw_Master.GetItemString(vlRow,"kcckd1_dwbh")
vsRybh = dw_Master.GetItemString(vlRow,"kcckd1_lyr")
vshdbz = dw_Master.GetItemString(vlRow,"kcckd1_hdbz")
if isnull(vslsbh) then vslsbh=''
if isnull(vstdls) Then vstdls=' '
if isnull(vsgxtd) then vsgxtd='0'
if isnull(vsthdh) then vsthdh=' '
If IsNull(vsDwbh) Then vsDWBH = ' '
iF IsNull(vsRybh) Then vsRybh = ' '

If trim(vslsbh)='' Then
	ps_error = "单据流水编号不存在"
	Return -1
End if

//--------------------------------------------------------------
//判断是否选择多张提货单
//--------------------------------------------------------------
vssql = " SELECT DISTINCT KCCKD2_TDLS FROM KCCKD2 WHERE KCCKD2_LSBH = '"+vsLsbh+"' "
If Gf_createds(vsSql,vds_tdls)<0 Then
	Messagebox("提示信息","创建提单流水数据存储错误！")
	Return -1
End if

For i = 1 to vds_tdls.Rowcount()
	vstdls = vds_tdls.Getitemstring(i,"kcckd2_tdls")
	if isnull(vstdls) Then vstdls=' '
	SELECT XSTD_PJLX INTO :vsTdLx FROM XSTD WHERE XSTD_TDLS=:vstdls;
	If IsNull(vsTdlx) Then vsTdlx = ''
	
	If Trim(vsGxtd) = '1' Then
		If Trim(vsTdlx) = 'BZCPTD' or Trim(vsTdlx) = 'JSJQTD' or Trim(vsTdlx) = 'XJYWTD' Then
			ps_error = "参照标准产品提单、寄售结清提单、现金业务提单时不允许更新提单数量。"
			Return -1
		End If
	End If
	
	vsAllTdls += "'"+vstdls+"',"
Next

vsAllTdls = mid(vsAllTdls,1,len(vsAllTdls) -1)

If Upper(ps_action) = 'ADD' Then
	vsFlag = '+'
Else
	vsFlag = '-'
End If
vsfalgbz = vsFlag
//==============================================================================
// 删除临时表数据
//==============================================================================

vsSql = "Delete From " + iscztmptbl

If GfExeSql(vsSql,SQLCA) < 0 Then
	ps_Error = "临时表数据删除错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
	Return -1
End If
//--------------------------------------------------------------
//ZHANGDONGCHAGN BEGING 2009年12月24日 FOR　ABB
//借用了出库单的KCCKD2_SCSQFL、KCCKD2_SCSQLS记录参照拆卸单对应入库单的信息
//只要KCCKD2_SCSQFL有值，一定为0000000001之类数据。
//因此 通过 isnull(KCCKD2_SCSQFL,' ') NOT LIKE '0000%' ，可提高一下效率
//如果KCCKD2_SCSQFL、KCCKD2_SCSQLS有值，表明是参照订单拆卸单的，不需要更新提单的信息
//--------------------------------------------------------------
choose case gsKind
	case 'ORA'
		vsSql = " INSERT INTO "+iscztmptbl+"(F_LSBH,F_FLBH,F_PCH,F_SL,F_FSL1,F_FSL2)"+&
			  " SELECT KCCKD2_TDLS,KCCKD2_TDFL,MAX(KCCKD2_PCH),SUM(KCCKD2_SL),SUM(KCCKD2_FSL1),SUM(KCCKD2_FSL2) "+&
			  " FROM KCCKD2 WHERE KCCKD2_LSBH = '"+vsLsbh+"' AND nvl(KCCKD2_SCSQFL,' ') NOT LIKE '0000%' GROUP BY KCCKD2_TDLS,KCCKD2_TDFL "
	case else
	vsSql = " INSERT INTO "+iscztmptbl+"(F_LSBH,F_FLBH,F_PCH,F_SL,F_FSL1,F_FSL2)"+&
			  " SELECT KCCKD2_TDLS,KCCKD2_TDFL,MAX(KCCKD2_PCH),SUM(KCCKD2_SL),SUM(KCCKD2_FSL1),SUM(KCCKD2_FSL2) "+&
			  " FROM KCCKD2 WHERE KCCKD2_LSBH = '"+vsLsbh+"' AND isnull(KCCKD2_SCSQFL,' ') NOT LIKE '0000%' GROUP BY KCCKD2_TDLS,KCCKD2_TDFL "
end choose
If GfExeSql(vsSql,SQLCA) < 0 Then
	ps_Error = "临时表数据插入错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
	Return -1
End If
//屏蔽原来处理方式
//vsSql = " INSERT INTO "+iscztmptbl+"(F_LSBH,F_FLBH,F_PCH,F_SL,F_FSL1,F_FSL2)"+&
//		  " SELECT KCCKD2_TDLS,KCCKD2_TDFL,MAX(KCCKD2_PCH),SUM(KCCKD2_SL),SUM(KCCKD2_FSL1),SUM(KCCKD2_FSL2) "+&
//		  " FROM KCCKD2 WHERE KCCKD2_LSBH = '"+vsLsbh+"' GROUP BY KCCKD2_TDLS,KCCKD2_TDFL "
//If GfExeSql(vsSql,SQLCA) < 0 Then
//	ps_Error = "临时表数据插入错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
//	Return -1
//End If
//--------------------------------------------------------------
//end
//--------------------------------------------------------------
//--------------------------------------------------------------
//无有效数据，直接返回
//--------------------------------------------------------------
if sqlca.sqlnrows = 0 then return 1
//--------------------------------------------------------------
//更新出库数量
//--------------------------------------------------------------
choose case gskind
	case 'ORA','DB2'
		vssql=" Update XSTDMX SET (XSTDMX_CKSL,XSTDMX_CKFSL1,XSTDMX_CKFSL2,XSTDMX_YHZSL,XSTDMX_YHFSL1,XSTDMX_YHFSL2)=(SELECT "+&
				" XSTDMX_CKSL  "+vsFlag+" ROUND(F_SL,  "+String(iisldecn)+"),"+& 
				" XSTDMX_CKFSL1 "+vsFlag+" ROUND(F_FSL2,"+String(iisldecn)+"),"+&
				" XSTDMX_CKFSL2 "+vsFlag+" ROUND(F_FSL1,"+String(iisldecn)+"),"+&
				" XSTDMX_YHZSL  "+vsFlag+" ROUND(F_SL,  "+String(iisldecn)+"),"+&
				" XSTDMX_YHFSL1 "+vsFlag+" ROUND(F_FSL2,"+String(iisldecn)+"),"+&
				" XSTDMX_YHFSL2 "+vsFlag+" ROUND(F_FSL1,"+String(iisldecn)+") "+&
				" FROM "+iscztmptbl+" "+&
				"WHERE F_LSBH=XSTDMX_TDLS "+&
				"and F_FLBH=XSTDMX_TDFL ) "+&
				"WHERE XSTDMX_TDLS IN("+vsAllTdls+") AND EXISTS (SELECT 1 FROM "+iscztmptbl+"   "+&
				"WHERE F_LSBH=XSTDMX_TDLS and F_FLBH=XSTDMX_TDFL )"
	case else
		vssql=" Update XSTDMX SET "+&
				" XSTDMX_CKSL  =XSTDMX_CKSL   "+vsFlag+" ROUND(F_SL,  "+String(iisldecn)+"),"+&
				" XSTDMX_CKFSL1=XSTDMX_CKFSL1 "+vsFlag+" ROUND(F_FSL2,"+String(iisldecn)+"),"+&
				" XSTDMX_CKFSL2=XSTDMX_CKFSL2 "+vsFlag+" ROUND(F_FSL1,"+String(iisldecn)+"),"+&
				" XSTDMX_YHZSL =XSTDMX_YHZSL   "+vsFlag+" ROUND(F_SL,  "+String(iisldecn)+"),"+&
				" XSTDMX_YHFSL1=XSTDMX_YHFSL1 "+vsFlag+" ROUND(F_FSL2,"+String(iisldecn)+"),"+&
				" XSTDMX_YHFSL2=XSTDMX_YHFSL2 "+vsFlag+" ROUND(F_FSL1,"+String(iisldecn)+") "+&
				" FROM "+iscztmptbl+" "+&
				" WHERE F_LSBH=XSTDMX_TDLS AND F_FLBH=XSTDMX_TDFL "+&
				" AND XSTDMX_TDLS IN("+vsAllTdls+")"
end choose
if gfexesql(vssql,sqlca)<0 then
	ps_error="更新提单出库数量失败。原因:~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
	return -1
end if

//zhaoQiang 2009.06.30 增加销售提单批次明细表处理
if ib_use_tdpcmx then
	//用于更新xstdpcmx
	vsSql = " INSERT INTO "+iscztmptbl+"(F_LSBH,F_FLBH,F_PCH,F_SL,F_FSL1,F_FSL2,F_XH)"+&
			  " SELECT KCCKD2_TDLS,KCCKD2_TDFL,MAX(KCCKD2_PCH),SUM(KCCKD2_SL),SUM(KCCKD2_FSL1),SUM(KCCKD2_FSL2),'TDPCMX' "+&
			  " FROM KCCKD2 WHERE KCCKD2_LSBH = '"+vsLsbh+"' GROUP BY KCCKD2_TDLS,KCCKD2_TDFL,KCCKD2_PCH "
	If GfExeSql(vsSql,SQLCA) < 0 Then
		ps_Error = "临时表数据插入错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
		Return -1
	End If

	choose case gskind
		case 'ORA','DB2'
			vssql=" Update XSTDPCMX SET (XSTDPCMX_CKSL,XSTDPCMX_CKFSL1,XSTDPCMX_CKFSL2)=(SELECT "+&
					" XSTDPCMX_CKSL  "+vsFlag+" ROUND(F_SL,  "+String(iisldecn)+"),"+& 
					" XSTDPCMX_CKFSL1 "+vsFlag+" ROUND(F_FSL2,"+String(iisldecn)+"),"+&
					" XSTDPCMX_CKFSL2 "+vsFlag+" ROUND(F_FSL1,"+String(iisldecn)+")"+&
					" FROM "+iscztmptbl+" "+&
					"WHERE F_LSBH=XSTDPCMX_TDLS "+&
					"and F_FLBH=XSTDPCMX_TDFL AND F_PCH = XSTDPCMX_PCH and F_XH='TDPCMX' ) "+&
					"WHERE XSTDPCMX_TDLS IN ("+vsAllTdls+") AND EXISTS (SELECT 1 FROM "+iscztmptbl+"   "+&
					"WHERE F_LSBH=XSTDPCMX_TDLS and F_FLBH=XSTDPCMX_TDFL AND F_PCH = XSTDPCMX_PCH and F_XH='TDPCMX')"+&
					" AND XSTDPCMX_TDLS IN (SELECT XSTD_TDLS FROM XSTD WHERE XSTD_PJLX='BZHSTD' AND XSTD_TDLS IN ("+vsAllTdls+"))"
		case else
			vssql=" Update XSTDPCMX SET "+&
					" XSTDPCMX_CKSL  =XSTDPCMX_CKSL   "+vsFlag+" ROUND(F_SL,  "+String(iisldecn)+"),"+&
					" XSTDPCMX_CKFSL1=XSTDPCMX_CKFSL1 "+vsFlag+" ROUND(F_FSL2,"+String(iisldecn)+"),"+&
					" XSTDPCMX_CKFSL2=XSTDPCMX_CKFSL2 "+vsFlag+" ROUND(F_FSL1,"+String(iisldecn)+")"+&
					" FROM "+iscztmptbl+" "+&
					" WHERE F_LSBH=XSTDPCMX_TDLS AND F_FLBH=XSTDPCMX_TDFL AND F_PCH = XSTDPCMX_PCH and F_XH='TDPCMX' "+&
					" AND XSTDPCMX_TDLS IN("+vsAllTdls+")" +&
					" AND XSTDPCMX_TDLS IN (SELECT XSTD_TDLS FROM XSTD WHERE XSTD_PJLX='BZHSTD' AND XSTD_TDLS IN ("+vsAllTdls+"))"
	end choose
	if gfexesql(vssql,sqlca)<0 then
		ps_error="更新提单出库数量失败。原因:~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
		return -1
	end if
	
	vsSql = "Delete From " + iscztmptbl+" where F_XH='TDPCMX' "
	If GfExeSql(vsSql,SQLCA) < 0 Then
		ps_Error = "临时表数据删除错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
		Return -1
	End If
end if	
//++++++++++++++++++++++++++++++++++++++++++++++++++

//--------------------------------------------------------------------------
//如果参数设定不允许更新提单数量或者单据设定不允许更新提单数量，则判断
//--------------------------------------------------------------------------
vstdyl='0' 
for i=1 to dw_detail.rowcount()
	vsflag=' '
	vdzsl=0
	vdcksl=0
	vswlbh=dw_detail.getitemstring(i,"kcckd2_wlbh")
	if isnull(vswlbh) or trim(vswlbh)='' then exit
	vstdls=dw_detail.getitemstring(i,"kcckd2_tdls")//wang
	if isnull(vslsbh) then vslsbh=''
	vstdfl=dw_detail.getitemstring(i,"kcckd2_tdfl")
	if isnull(vstdfl) then vstdfl=''
	select 'EXISTS',XSTDMX_ZSL,XSTDMX_CKSL,XSTDMX_KCYL into :vsexists,:vdzsl,:vdcksl,:vstemp from XSTDMX 
	WHERE XSTDMX_TDLS=:vstdls and XSTDMX_TDFL=:vstdfl;// AND round(abs(XSTDMX_ZSL),:iisldecn) < round(abs(XSTDMX_CKSL),:iisldecn) ;
	if isnull(vsexists) then vsexists = ''
	IF len(trim(vsexists)) < 1 THEN 
		ps_error="第["+string(i)+"]行分录对应的提单不存在，无法更新提单数量，请确认!"
		return -1
	END IF 
	if trim(vsgxtd)='0' or trim(is_xs_yxkcgxtd)='0' then
		IF Round(Abs(vdZsl),iisldecn) < Round(Abs(vdcksl),iisldecn) then
			string vsconfig = ''
			gfGetconfig('KC_CTDCK',vsconfig)//yudw联盛纸业超提单出库控制.因后续有单独开发配合使用故此处产品上不要随意放开。
			if vsconfig = '' then
				ps_error="提单["+vsthdh+"]的["+vstdfl+"]分录的出库数量["+string(round(vdcksl,iisldecn))+"]超出了主数量["+string(round(vdzsl,iisldecn))+"]"
				return -1
			end if
		end if
	else
		//判断该提单是否记账，已经记账的提单不允许更新提单数量
		if Round(Abs(vdZsl),iisldecn) < Round(Abs(vdcksl),iisldecn) then
			select XSTD_JZBZ into :vsjz from XSTD WHERE XSTD_TDLS=:vstdls ;
			IF ISNULL(vsjz) then vsjz='0'
			if trim(vsjz)='1' then
				ps_error="提单["+vsthdh+"]已经记账，不能更新提单数量。"
				return -1
			end if
		end if
	end if
	//记录提单上是否有预留的数据
	if vstemp='1' then
		//用vstdyl 记录下来存在预留数据
		vstdyl='1' 
	end if
	
	//==============================================================================
	// 不允许更新提单时，对于蓝提单，出库数量不允许小于0，红提单不允许出库数量大于0
	//==============================================================================
	//zhaoQiang 2009.09.12
	if (Trim(vsGxtd) = '0' OR Trim(is_xs_yxkcgxtd) = '0') then
		If Round(vdZsl,iisldecn) > 0 AND Round(vdCksl,iisldecn) < 0 Then
			ps_error = "提单["+vsthdh+"]主数量大于0，不允许出库数量为负数。"
			Return -1
		End If
		
		If Round(vdZsl,iisldecn) < 0 AND Round(vdCksl,iisldecn) > 0 Then
			ps_error = "提单["+vsthdh+"]主数量小于0，不允许出库数量为正数。"
			Return -1
		End If
		
		//zhaoQiang 2009.09.12 判断库存批次明细出库信息
		SELECT XSTD_PJLX INTO :LS_PCH FROM XSTD WHERE XSTD_TDLS =:VSTDLS;
		IF ISNULL(LS_PCH) THEN LS_PCH=""
		if ib_use_tdpcmx AND UPPER(TRIM(LS_PCH)) ='BZHSTD' then
			ls_pch = dw_detail.getitemstring(i,"kcckd2_pch")
			select XSTDPCMX_ZSL,XSTDPCMX_CKSL into :vdzsl,:vdcksl from XSTDPCMX 
			WHERE XSTDPCMX_TDLS=:vstdls and XSTDPCMX_TDFL=:vstdfl AND XSTDPCMX_PCH = :LS_PCH;
			
			IF Round(Abs(vdZsl),iisldecn) < Round(Abs(vdcksl),iisldecn) then
				ps_error="提单批次明细["+vsthdh+"]的["+vstdfl+"]分录的["+LS_PCH+"]批次的出库数量["+string(round(vdcksl,iisldecn))+"]超出了主数量["+string(round(vdzsl,iisldecn))+"]"
				return -1
			end if	
		end if	
	end if	
next

//----------------------------------------------------------------------
//对于允许更新提单数量情况，保存时应修改主数量等相应数据
//新增单据需要先减后增
//----------------------------------------------------------------------
IF ( ( (is_action='NEW' AND ps_action="ADD") OR   ps_action="MOD" or ps_action = 'DEL') or is_sfqrbg='1' )  and trim(is_xs_yxkcgxtd)='1' and trim(vsgxtd)='1' then
	For i =1 to vds_tdls.rowcount( )
		vstdls = vds_tdls.Getitemstring(i,"kcckd2_tdls")
		SELECT XSTD_PJLX INTO :vsTdLx FROM XSTD WHERE XSTD_TDLS=:vstdls;
		If IsNull(vsTdlx) Then vsTdlx = ''

		//允许更新提单时,首先取消该提单实时账
		If vsTdlx = 'BZHSTD' Then
			If uo_ThdJz.uf_ss_Jz(vstdls,0,ps_error) = -1 Then Return -1
		End If
	Next
end if 
//--------------------------------------------------------------
//更新提单主数量
//--------------------------------------------------------------
IF ps_action='ADD' and trim(is_xs_yxkcgxtd)='1' and trim(vsgxtd)='1' then
	choose case gskind
		case 'DB2','ORA'	
			//考虑到红单和蓝单问题,将出库数量由>0改<>0.
			vssql="update XSTDMX SET(XSTDMX_ZSL,XSTDMX_FSL1,XSTDMX_FSL2,XSTDMX_YXSE,XSTDMX_BXSE,XSTDMX_YSE,XSTDMX_BSE,XSTDMX_YHSE,XSTDMX_BHSE)=(SELECT "+&
			      "ROUND(XSTDMX_CKSL,  "+String(iisldecn)+"), "+&
					"ROUND(XSTDMX_CKFSL1,"+String(iisldecn)+"), "+&
					"ROUND(XSTDMX_CKFSL2,"+String(iisldecn)+"), "+&
					"ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZXSJ ELSE ROUND(XSTDMX_YXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END, "+String(xsJedecn)+"), "+&
					"ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZXSJ ELSE ROUND(XSTDMX_BXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END  , "+String(xsJedecn)+"), "+&
					"CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_CKSL * XSTDMX_YZXSJ* XSTDMX_SL/100,"+String(xsJedecn)+") ELSE ROUND(XSTDMX_CKSL *  ROUND(XSTDMX_YSE  / XSTDMX_ZSL,"+String(vidjzzsdecn)+"),"+String(xsJedecn)+" ) END , "+&
					"CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_CKSL * XSTDMX_BZXSJ* XSTDMX_SL/100,"+String(xsJedecn)+") ELSE ROUND(XSTDMX_CKSL * XSTDMX_BSE  / XSTDMX_ZSL,"+String(xsJedecn)+" ) END , "+&
					"ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZHSJ ELSE  ROUND(XSTDMX_YHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END ,  "+String(xsJedecn)+"), "+&
					"ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZHSJ ELSE ROUND(XSTDMX_BHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END , "+String(xsJedecn)+")  "+&
					" FROM XSTD,"+iscztmptbl+" where "+&
					" XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' ) WHERE EXISTS(SELECT 1  " +&
					" FROM XSTD,"+iscztmptbl+" where "+&			
					" XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' )"
		case else
			//考虑到红单和蓝单问题,将出库数量由>0改<>0.
			vssql="UPDATE XSTDMX SET "+&
					"XSTDMX_ZSL =ROUND(XSTDMX_CKSL,  "+String(iisldecn)+"),"+&
			      "XSTDMX_FSL1=ROUND(XSTDMX_CKFSL1,"+String(iisldecn)+"),"+&
					"XSTDMX_FSL2=ROUND(XSTDMX_CKFSL2,"+String(iisldecn)+"),"+&
					"XSTDMX_YXSE=ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZXSJ ELSE ROUND(XSTDMX_YXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END,  "+String(xsJedecn)+"),"+&
					"XSTDMX_BXSE=ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZXSJ ELSE ROUND(XSTDMX_BXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END,   "+String(xsJedecn)+"),"+&
					"XSTDMX_YSE =CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_CKSL * XSTDMX_YZXSJ* XSTDMX_SL/100,"+String(xsJedecn)+") ELSE ROUND(XSTDMX_CKSL * XSTDMX_YSE  / XSTDMX_ZSL,"+String(xsJedecn)+") END , "+&
					"XSTDMX_BSE =CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_CKSL * XSTDMX_BZXSJ* XSTDMX_SL/100,"+String(xsJedecn)+") ELSE ROUND(XSTDMX_CKSL * XSTDMX_BSE  / XSTDMX_ZSL,"+String(xsJedecn)+") END , "+&
					"XSTDMX_YHSE=ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZHSJ ELSE ROUND(XSTDMX_YHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END ,   "+String(xsJedecn)+"),"+&
					"XSTDMX_BHSE=ROUND(XSTDMX_CKSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZHSJ ELSE ROUND(XSTDMX_BHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END ,   "+String(xsJedecn)+") "+&
					"FROM XSTD,"+iscztmptbl+" "+&
					" where XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_JZBZ='0' "						
		end choose
		if gfexesql(vssql,sqlca)<0 then
			ps_error="更新提单出库数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
			return -1
		end if
		//当预留数量大于主数量时，根据主数量更新预留数量
		IF SQLCA.SQLNROWS > 0 THEN
			CHOOSE case gskind
				case 'DB2','ORA'	
				vssql="UPDATE XSTDMX SET(XSTDMX_YLZSL,XSTDMX_YLFSL1,XSTDMX_YLFSL2)=(SELECT "+&
						"ROUND(XSTDMX_ZSL, "+String(iisldecn)+"),"+&
						"ROUND(XSTDMX_FSL1,"+String(iisldecn)+"),"+&
						"ROUND(XSTDMX_FSL2,"+String(iisldecn)+") "+&
						"FROM XSTD,"+iscztmptbl+"  where "+&
						"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_JZBZ='0' and abs(XSTDMX_YLZSL) >= abs(XSTDMX_ZSL) ) WHERE EXISTS(SELECT 1   "+&
						" FROM XSTD,"+iscztmptbl+"  where "+&
						" XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_JZBZ='0' and abs(XSTDMX_YLZSL) >= abs(XSTDMX_ZSL) ) "
				case else	
				vssql="UPDATE XSTDMX SET "+&
						"XSTDMX_YLZSL =ROUND(XSTDMX_ZSL, "+String(iisldecn)+"),"+&
						"XSTDMX_YLFSL1=ROUND(XSTDMX_FSL1,"+String(iisldecn)+"),"+&
						"XSTDMX_YLFSL2=ROUND(XSTDMX_FSL2,"+String(iisldecn)+") "+&
						"FROM XSTD,"+iscztmptbl+"  "+&
						"where XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_JZBZ='0' and abs(XSTDMX_YLZSL) >= abs(XSTDMX_ZSL) "						
				end choose
				if gfexesql(vssql,sqlca)<0 then
					ps_error="更新提单预留数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
					return -1
				end if
		END IF	
//---------------------------------------------------------------------------------
//对于允许更新提单情况,删除出库单时应修改相应的提单主数量等数据
//---------------------------------------------------------------------------------
elseIF ps_action = 'DEL' and trim(is_xs_yxkcgxtd)='1' and trim(vsgxtd)='1' then
	choose case gskind
		case 'DB2','ORA'
			//更新辅数量
			vssql="UPDATE XSTDMX SET(XSTDMX_FSL1,XSTDMX_FSL2,XSTDMX_YXSE,XSTDMX_BXSE,XSTDMX_YSE,XSTDMX_BSE,XSTDMX_YHSE,XSTDMX_BHSE) = (SELECT "+&
			      " CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_FSL1 ELSE ROUND(ROUND(XSTDMX_YZSL,"+String(iisldecn)+")*ROUND(XSTDMX_FSL1,"+string(iisldecn)+")/ROUND(XSTDMX_ZSL,"+string(iisldecn)+"),"+string(iisldecn)+") END , "+&
					" CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_FSL2 ELSE ROUND(ROUND(XSTDMX_YZSL,"+String(iisldecn)+")*ROUND(XSTDMX_FSL2,"+string(iisldecn)+")/ROUND(XSTDMX_ZSL,"+string(iisldecn)+"),"+string(iisldecn)+") END , "+&
					"ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZXSJ ELSE ROUND(XSTDMX_YXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END,  "+String(xsJedecn)+"),"+&
					"ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZXSJ ELSE ROUND(XSTDMX_BXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END  ,  "+String(xsJedecn)+"),"+&
					"CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_YZSL * XSTDMX_YZXSJ* XSTDMX_SL/100,"+String(xsJedecn)+") ELSE ROUND(XSTDMX_YZSL * XSTDMX_YSE  / XSTDMX_ZSL,"+String(xsJedecn)+") END , "+&
					"CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_YZSL * XSTDMX_BZXSJ* XSTDMX_SL/100,"+String(xsJedecn)+") ELSE ROUND(XSTDMX_YZSL * XSTDMX_BSE  / XSTDMX_ZSL,"+String(xsJedecn)+") END , "+&
					"ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZHSJ ELSE ROUND(XSTDMX_YHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END , "+String(xsJedecn)+"),"+&
					"ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZHSJ ELSE ROUND(XSTDMX_BHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END ,  "+String(xsJedecn)+") "+&
					"FROM XSTD,"+iscztmptbl+" where "+&
					"XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_ZSL<>0 AND XSTDMX_TDLS IN ("+vsAlltdls+")) WHERE EXISTS(SELECT 1 "+&
					"  FROM XSTD,"+iscztmptbl+"  WHERE  XSTD_TDLS=XSTDMX_TDLS  AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_ZSL<>0 AND XSTDMX_TDLS IN ("+vsAlltdls+"))"
			if gfexesql(vssql,sqlca)<0 then
				ps_error="更新提单数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
				return -1
			end if
			//更新主数量
			vssql="UPDATE XSTDMX SET(XSTDMX_ZSL) = (SELECT "+&
			      " XSTDMX_YZSL  FROM XSTD,"+iscztmptbl+" where "+&
					"XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_ZSL<>0 AND XSTDMX_TDLS IN ("+vsAlltdls+")) WHERE EXISTS(SELECT 1  "+&
					"FROM XSTD,"+iscztmptbl+" where "+&
					"XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_ZSL<>0 AND XSTDMX_TDLS IN ("+vsAlltdls+"))"
			if gfexesql(vssql,sqlca)<0 then
				ps_error="更新提单数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
				return -1
			end if
		case else
			//更新辅数量
			vssql="UPDATE XSTDMX SET "+&
			      "XSTDMX_FSL1=CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_FSL1 ELSE ROUND(ROUND(XSTDMX_YZSL,"+String(iisldecn)+")*ROUND(XSTDMX_FSL1,"+string(iisldecn)+")/ROUND(XSTDMX_ZSL,"+string(iisldecn)+"),"+string(iisldecn)+") END, "+&
					"XSTDMX_FSL2=CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_FSL2 ELSE ROUND(ROUND(XSTDMX_YZSL,"+String(iisldecn)+")*ROUND(XSTDMX_FSL2,"+string(iisldecn)+")/ROUND(XSTDMX_ZSL,"+string(iisldecn)+"),"+string(iisldecn)+") END, "+&
					"XSTDMX_YXSE=ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZXSJ ELSE ROUND(XSTDMX_YXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END,   "+String(xsJedecn)+"),"+&
					"XSTDMX_BXSE=ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZXSJ ELSE ROUND(XSTDMX_BXSE / XSTDMX_ZSL,"+String(vidjptsdecn)+") END,   "+String(xsJedecn)+"),"+&
					"XSTDMX_YSE =CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_YZSL * XSTDMX_YZXSJ* XSTDMX_SL/100,"+string(xsJedecn)+") ELSE ROUND(XSTDMX_YZSL * XSTDMX_YSE  / XSTDMX_ZSL,"+string(xsJedecn)+") END , "+&
					"XSTDMX_BSE =CASE XSTDMX_ZSL WHEN 0 THEN ROUND(XSTDMX_YZSL * XSTDMX_BZXSJ* XSTDMX_SL/100,"+string(xsJedecn)+") ELSE ROUND(XSTDMX_YZSL * XSTDMX_BSE  / XSTDMX_ZSL,"+string(xsJedecn)+") END , "+&
					"XSTDMX_YHSE=ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_YZHSJ ELSE ROUND(XSTDMX_YHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END , "+String(xsJedecn)+"),"+&
					"XSTDMX_BHSE=ROUND(XSTDMX_YZSL * CASE XSTDMX_ZSL WHEN 0 THEN XSTDMX_BZHSJ ELSE ROUND(XSTDMX_BHSE / XSTDMX_ZSL,"+String(vidjzzsdecn)+") END , "+String(xsJedecn)+") "+&
					"FROM XSTD,"+iscztmptbl+" "+&
					"where XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_ZSL<>0 AND XSTDMX_TDLS IN ("+vsAlltdls+") "
			if gfexesql(vssql,sqlca)<0 then
				ps_error="更新提单数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
				return -1
			end if
			//更新主数量
			vssql="UPDATE XSTDMX SET "+&
			      "XSTDMX_ZSL =XSTDMX_YZSL "+&
					"FROM XSTD,"+iscztmptbl+" "+&
					"where XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_TDLS IN ("+vsAlltdls+") "
			if gfexesql(vssql,sqlca)<0 then
				ps_error="更新提单主数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
				return -1
			end if
			
	end choose
end if
//==============================================================================
//对提单预留耗用数量的有效性处理
//==============================================================================
//--------------------------------------------------------------
//如果预留耗用数量大于出库数量，将预留耗用数量=出库数量
//--------------------------------------------------------------
//如果提单中存在预留数据，再处理
//IF gif_exists("XSTDMX,"+iscztmptbl ,"   XSTDMX_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTDMX_KCYL='1'  AND XSTDMX_TDLS IN ("+vsAlltdls+")")>0 then 
if vstdyl='1' then
	
	CHOOSE case gskind
		case 'DB2','ORA'	
		vssql="UPDATE XSTDMX SET(XSTDMX_YHZSL,XSTDMX_YHFSL1,XSTDMX_YHFSL2)=(SELECT "+&
				"ROUND(XSTDMX_CKSL, "+String(iisldecn)+"),"+&
				"ROUND(XSTDMX_CKFSL1,"+String(iisldecn)+"),"+&
				"ROUND(XSTDMX_CKFSL2,"+String(iisldecn)+") "+&
				"FROM XSTD,"+iscztmptbl+" where "+&
				"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTDMX_KCYL='1' and abs(XSTDMX_YHZSL) >= abs(XSTDMX_CKSL) ) WHERE EXISTS(SELECT 1 "+&
				"FROM XSTD,"+iscztmptbl+" where "+&
				"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTDMX_KCYL='1' and abs(XSTDMX_YHZSL) >= abs(XSTDMX_CKSL) ) "
		case else	
		vssql="UPDATE XSTDMX SET "+&
				"XSTDMX_YHZSL =ROUND(XSTDMX_CKSL, "+String(iisldecn)+"),"+&
				"XSTDMX_YHFSL1=ROUND(XSTDMX_CKFSL1,"+String(iisldecn)+"),"+&
				"XSTDMX_YHFSL2=ROUND(XSTDMX_CKFSL2,"+String(iisldecn)+") "+&
				"FROM XSTD,"+iscztmptbl+" "+&
				"where XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTDMX_KCYL='1' and abs(XSTDMX_YHZSL) >= abs(XSTDMX_CKSL) "						
	end choose
	if gfexesql(vssql,sqlca)<0 then
		ps_error="更新提单预留数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
		return -1
	end if
	
	//--------------------------------------------------------------
	//更新提单时，将预留数量=预留耗用数量
	//--------------------------------------------------------------
	IF  trim(is_xs_yxkcgxtd)='1' and trim(vsgxtd)='1' then
		if ps_action = "DEL" then
			CHOOSE case gskind
				case 'DB2','ORA'	
				vssql="UPDATE XSTDMX SET(XSTDMX_YLZSL,XSTDMX_YLFSL1,XSTDMX_YLFSL2,XSTDMX_YHZSL,XSTDMX_YHFSL1,XSTDMX_YHFSL2)=(SELECT "+&
						"XSTDMX_ZSL,XSTDMX_FSL1,XSTDMX_FSL2,"+& 
						"0,"+&
						"0,"+&
						"0 "+&
						"FROM XSTD,"+iscztmptbl+" where "+&
						"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0' AND XSTDMX_KCYL='1' ) WHERE EXISTS(SELECT 1 "+&
						"FROM XSTD,"+iscztmptbl+" where "+&
						"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'  AND XSTDMX_KCYL='1' ) "
				case else	
				vssql="UPDATE XSTDMX SET "+&
						"XSTDMX_YLZSL =XSTDMX_ZSL,"+&
						"XSTDMX_YLFSL1=XSTDMX_FSL1,"+&
						"XSTDMX_YLFSL2=XSTDMX_FSL2,"+&
						"XSTDMX_YHZSL =0,XSTDMX_YHFSL1=0,XSTDMX_YHFSL2=0 "+&
						"FROM XSTD,"+iscztmptbl+" "+&
						"where XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'   AND XSTDMX_KCYL='1' "						
			end choose
		else
			CHOOSE case gskind
				case 'DB2','ORA'	
				vssql="UPDATE XSTDMX SET(XSTDMX_YHZSL,XSTDMX_YHFSL1,XSTDMX_YHFSL2)=(SELECT "+&
						"ROUND(XSTDMX_YLZSL, "+String(iisldecn)+"),"+&
						"ROUND(XSTDMX_YLFSL1,"+String(iisldecn)+"),"+&
						"ROUND(XSTDMX_YLFSL2,"+String(iisldecn)+") "+&
						"FROM XSTD,"+iscztmptbl+" where "+&
						"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'  AND XSTDMX_KCYL='1' ) WHERE EXISTS(SELECT 1 "+&
						"FROM XSTD,"+iscztmptbl+" where "+&
						"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'  AND XSTDMX_KCYL='1') "
				case else	
				vssql="UPDATE XSTDMX SET "+&
						"XSTDMX_YHZSL =XSTDMX_YLZSL,"+&
						"XSTDMX_YHFSL1=XSTDMX_YLFSL1,"+&
						"XSTDMX_YHFSL2=XSTDMX_YLFSL2 "+&
						"FROM XSTD,"+iscztmptbl+" "+&
						"where XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'  AND XSTDMX_KCYL='1' "						
			end choose
		end if
	else
		//--------------------------------------------------------------
		//如果预留耗用数量大于预留数量，将预留耗用数量=预留数量
		//--------------------------------------------------------------
		CHOOSE case gskind
			case 'DB2','ORA'	
			vssql="UPDATE XSTDMX SET(XSTDMX_YHZSL,XSTDMX_YHFSL1,XSTDMX_YHFSL2)=(SELECT "+&
					"ROUND(XSTDMX_YLZSL, "+String(iisldecn)+"),"+&
					"ROUND(XSTDMX_YLFSL1,"+String(iisldecn)+"),"+&
					"ROUND(XSTDMX_YLFSL2,"+String(iisldecn)+") "+&
					"FROM XSTD,"+iscztmptbl+" where "+&
					"XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'  AND XSTDMX_KCYL='1' and abs(XSTDMX_YHZSL) >= abs(XSTDMX_YLZSL) ) WHERE EXISTS(SELECT 1 "+&
					" FROM XSTD,"+iscztmptbl+" where "+&
					" XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'   AND XSTDMX_KCYL='1' and abs(XSTDMX_YHZSL) >= abs(XSTDMX_YLZSL) ) "
			case else	
			vssql="UPDATE XSTDMX SET "+&
					"XSTDMX_YHZSL =ROUND(XSTDMX_YLZSL, "+String(iisldecn)+"),"+&
					"XSTDMX_YHFSL1=ROUND(XSTDMX_YLFSL1,"+String(iisldecn)+"),"+&
					"XSTDMX_YHFSL2=ROUND(XSTDMX_YLFSL2,"+String(iisldecn)+") "+&
					"FROM XSTD,"+iscztmptbl+" "+&
					"where XSTDMX_TDLS IN ("+vsAlltdls+") AND XSTD_TDLS=XSTDMX_TDLS AND XSTD_TDLS = F_LSBH AND XSTDMX_TDFL = F_FLBH AND XSTD_JZBZ='0'   AND XSTDMX_KCYL='1' and abs(XSTDMX_YHZSL) >= abs(XSTDMX_YLZSL) "						
		end choose
	
	END IF
	if gfexesql(vssql,sqlca)<0 then
		ps_error="更新提单预留数量失败。原因：~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
		return -1
	end if

end if

//--------------------------------------------------------------
//删除时(not pbflag and psErr="DEL")或者完成修改或增加时(pbflag)更新销售提单
//--------------------------------------------------------------
IF (ps_action="ADD" or ps_action = 'DEL')  and trim(is_xs_yxkcgxtd)='1' and trim(vsgxtd)='1' then
	For i =1 to vds_tdls.rowcount( )
		vstdls = vds_tdls.Getitemstring(i,"kcckd2_tdls")
		SELECT XSTD_PJLX INTO :vsTdLx FROM XSTD WHERE XSTD_TDLS=:vstdls;
		If IsNull(vsTdlx) Then vsTdlx = ''
	
		//更新提单完成后,登记实时账
		If vsTdlx = 'BZHSTD' Then
			If uo_ThdJz.uf_ss_Jz(vstdls,1,ps_error) = -1 Then Return -1
		End If
	Next
end if 

//----------------------------------------------------------
//更新提单出库标志
//-----------------------------------------------------------
vsSQL=" UPDATE XSTDMX SET XSTDMX_CKBZ='1' "+&
		" where XSTDMX_TDLS IN ("+vsAllTdls+")  AND "+&
		" ROUND(XSTDMX_CKSL+XSTDMX_THSL,"+String(iisldecn)+") = ROUND(XSTDMX_ZSL,"+String(iisldecn)+") " 
if gfExeSql(vsSql,sqlca)<0 then 
	ps_error="更新提单出库标志错误~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
	return -1
end if

vsSQL=" UPDATE XSTDMX SET XSTDMX_CKBZ='0' "+&
		" Where XSTDMX_TDLS IN ("+vsAllTdls+")  AND "+&
		" ROUND(XSTDMX_CKSL + XSTDMX_THSL,"+String(iisldecn)+") <> ROUND(XSTDMX_ZSL,"+String(iisldecn)+") "	
if gfExeSql(vsSql,sqlca)<0 then 
	ps_error="更新提单出库标志错误~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
	return -1
end if
//zhaoQiang 2009.06.30 增加销售提单批次明细表处理
if ib_use_tdpcmx then
	vsSQL=" UPDATE XSTDPCMX SET XSTDPCMX_CKBZ=(CASE WHEN ROUND(ROUND(ISNULL(XSTDPCMX_CKSL,0),"+STRING(iisldecn)+") + ROUND(ISNULL(XSTDPCMX_THSL,0),"+STRING(iisldecn)+"),"+STRING(iisldecn)+") = ROUND(ISNULL(XSTDPCMX_ZSL,0),"+STRING(iisldecn)+") THEN '1' ELSE '0' END) "+&
			" Where XSTDPCMX_TDLS IN ("+vsAllTdls+") "	+&
			" AND XSTDPCMX_TDLS IN (SELECT XSTD_TDLS FROM XSTD WHERE XSTD_PJLX='BZHSTD' AND XSTD_TDLS IN ("+vsAllTdls+"))"
	if gfExeSql(vsSql,sqlca)<0 then 
		ps_error="更新提单批次明细出库标志错误~r~n"+vssql+"~r~n"+sqlca.sqlerrtext
		return -1
	end if
END IF
//+++++++++++++++++++++++++++++++++++++++++++++++
//==============================================================================
// 更新预留数量
//==============================================================================
//预留余额使用试图实现，不需要再重新归集
if is_kcyl_view='0' then
	Choose Case GsKind
		Case 'ORA'
			vsSql = "UPDATE KCYLYE SET (KCYLYE_DFSL,KCYLYE_DFFSL1,KCYLYE_DFFSL2,KCYLYE_JFSL,KCYLYE_JFFSL1,KCYLYE_JFFSL2,KCYLYE_SLYE,KCYLYE_FSLYE1,KCYLYE_FSLYE2)="+&
					  "(SELECT  XSTDMX_YHZSL," +&
					  "XSTDMX_YHFSL2,"+&
					  "XSTDMX_YHFSL1, "+&
					  "XSTDMX_YLZSL," +&
					  "XSTDMX_YLFSL2, "+&
					  "XSTDMX_YLFSL1, "+&
					  "XSTDMX_YLZSL - XSTDMX_YHZSL,   "+&
					  "XSTDMX_YLFSL2 - XSTDMX_YHFSL2, "+&
					  "XSTDMX_YLFSL1 - XSTDMX_YHFSL1  FROM XSTDMX,"+iscztmptbl+" "+&
					  " WHERE F_LSBH=KCYLYE_DJLS AND F_FLBH=KCYLYE_DJFL AND  XSTDMX_TDLS=F_LSBH AND XSTDMX_TDFL=F_FLBH AND XSTDMX_TDLS=KCYLYE_DJLS AND XSTDMX_TDFL=KCYLYE_DJFL AND KCYLYE_DJLX='XSTD') WHERE EXISTS (SELECT 1 FROM XSTDMX,"+iscztmptbl+" "+&
					  " WHERE F_LSBH=KCYLYE_DJLS AND F_FLBH=KCYLYE_DJFL AND  XSTDMX_TDLS=F_LSBH AND XSTDMX_TDFL=F_FLBH AND XSTDMX_TDLS=KCYLYE_DJLS AND XSTDMX_TDFL=KCYLYE_DJFL AND KCYLYE_DJLX='XSTD')"
		Case Else
			vsSql = "UPDATE KCYLYE SET KCYLYE_DFSL = XSTDMX_YHZSL," +&
					  "KCYLYE_DFFSL1 = XSTDMX_YHFSL2, "+&
					  "KCYLYE_DFFSL2 = XSTDMX_YHFSL1, "+&
					  "KCYLYE_JFSL   = XSTDMX_YLZSL," +&
					  "KCYLYE_JFFSL1 = XSTDMX_YLFSL2, "+&
					  "KCYLYE_JFFSL2 = XSTDMX_YLFSL1, "+&
					  "KCYLYE_SLYE   = XSTDMX_YLZSL - XSTDMX_YHZSL,   "+&
					  "KCYLYE_FSLYE1 = XSTDMX_YLFSL2 - XSTDMX_YHFSL2, "+&
					  "KCYLYE_FSLYE2 = XSTDMX_YLFSL1 - XSTDMX_YHFSL1 "+&
					  " FROM XSTDMX,"+iscztmptbl+" "+&
					  " Where F_LSBH=KCYLYE_DJLS AND F_FLBH=KCYLYE_DJFL AND  XSTDMX_TDLS=F_LSBH AND XSTDMX_TDFL=F_FLBH AND XSTDMX_TDLS=KCYLYE_DJLS AND XSTDMX_TDFL=KCYLYE_DJFL AND KCYLYE_DJLX='XSTD'"
	End Choose
	//去掉红出库单不更新预留帐 changed by sunjsh 2007-07-03
	//if vshdbz='0'  then //红单不处理预留 zhengym 2006.12.7
		If GfExeSql(vsSql,SQLCA) < 0 Then
			ps_error = "更新预留余额错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
			Return -1
		End If	
End If			
//end if
// 红提单来源于蓝提单的处理
//if vshdbz = '1' then
//	string vsytdls,vsytdfl,vsAllTdfl,vs_error
//	long vlcount
//	vsAlltdls = ''
//	vsAllTdfl = ''
//	for i = 1 to dw_detail.rowcount()
//		 vsytdls = ''
//		 vsytdfl = ''
//		 vstdls = dw_detail.getitemstring(i,"kcckd2_tdls")
//		 if trim(vstdls)='' or isnull(vstdls) then vstdls=''
//		 vstdfl = dw_detail.getitemstring(i,"kcckd2_tdfl")
//		 if trim(vstdfl)='' or isnull(vstdfl) then vstdfl=''
//		 select XSTDMX_YTDLS,XSTDMX_YTDFL into :vsytdls,:vsytdfl FROM XSTDMX WHERE XSTDMX_TDLS=:vstdls AND XSTDMX_TDFL=:vstdfl ;
//		 if trim(vsytdls)<>'' and not isnull(vsytdls) and trim(vsytdfl)<>'' and not isnull(vsytdfl) and trim(vsytdls)<>'@' then
//			vsAlltdls += "'"+vsytdls+"',"
//			vsAllTdfl += "'"+vsytdfl+"',"
//			vlcount +=1
//		 end if
//	next
//	vsAllTdls = mid(vsAllTdls,1,len(vsAllTdls) -1)
//	vsAllTdfl = mid(vsAllTdfl,1,len(vsAllTdfl) -1)
//	vsAllTdls = vsAllTdls+";"+vsAllTdfl
//	if vlcount >0 then
//		vsSql = "Delete From " + iscztmptbl
//		If GfExeSql(vsSql,SQLCA) < 0 Then
//			ps_Error = "临时表数据删除错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
//			Return -1
//		End If
//		
//		vsSql = " INSERT INTO "+iscztmptbl+"(F_LSBH,F_FLBH,F_PCH,F_SL,F_FSL1,F_FSL2)"+&
//				  " SELECT MAX(XSTDMX_YTDLS),MAX(XSTDMX_YTDFL),MAX(KCCKD2_PCH),SUM(KCCKD2_SL),SUM(KCCKD2_FSL1),SUM(KCCKD2_FSL2) "+&
//				  " FROM KCCKD2,XSTDMX WHERE XSTDMX_TDLS=KCCKD2_TDLS AND XSTDMX_TDFL=KCCKD2_TDFL AND  KCCKD2_LSBH = '"+vsLsbh+"' GROUP BY KCCKD2_TDLS,KCCKD2_TDFL "
//		If GfExeSql(vsSql,SQLCA) < 0 Then
//			ps_Error = "临时表数据插入错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
//			Return -1
//		End If	
//		if uf_xsckd_gxxstdld(vsAllTdls,vsfalgbz,'',vs_error)<>1 then
//			ps_error = vs_error
////			ps_error = "更新红单对应蓝单错误：" + SQLCA.SQLErrText + "~r~n" + vsSql
//			Return -1
//		end if
//	end if
//end if
//
//----------------------------------------------------------
//更新资信限额:仅对于使用更新提单的出库单时更新
//-----------------------------------------------------------
if trim(is_xs_yxkcgxtd)='1' and trim(vsgxtd)='1' then
	ps_error = ''
	If Not Gbf_Xs_CheckCredit(vsDwbh,vsRybh,ps_error)  Then Return -1
	
	If Len(ps_error)>0 Then
		If MessageBox("提示信息",ps_error,Exclamation!,YesNo!,2)=2 Then
			Return -1
		Else
			Return 1
		End If
	End If
end if

destroy vds_tdls
return 1