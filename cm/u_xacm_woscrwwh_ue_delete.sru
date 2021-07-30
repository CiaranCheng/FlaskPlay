//====================================================================
// 事件: u_xacm_woscrwwh.ue_delete()
//--------------------------------------------------------------------
// 描述: 任务单删除
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2017年11月16日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
string lsFpbz,lsLsbh,lsCpbh
long llcnt
string lsYwbs
string lsSql,lsErr
long llRowCount
long llMessageNum
integer i
string lsRwbh
string  lsWlbh,lsGxsh,lsSfll,lsScckdlsbh,lsScckdflbh
string lsCkdshbz,lsCkdbh
integer llCount

//boolean vbselect

// 1、删除合法性判断
If dw_list.modifiedcount() + dw_list.deletedcount() > 0 Then
	messagebox("提示信息","单据尚未保存，请首先保存单据再进行删除")
	Return -1
End If

// 删除前确认提示
If messagebox("提示信息","确实要删除选中数据吗？",exclamation!,yesno!,2) <> 1 Then
	event ue_refresh()
	dw_list.setredraw(true)
	Return -1
End If

llRowCount = dw_list.rowcount( )

// 选中了就进行删除
For i = llRowCount to 1 step -1
	If dw_list.isselected(i) Then // 被选中
		
		//vbselect = dw_list.isselected(1)
		
		// 判断是否是可以删除的生产任务单
		lsLsbh = dw_list.getitemstring(i,"cmscrw_lsbh")
		lsRwbh = dw_list.getitemstring(i,"cmscrw_rwbh")
		lsWlbh = dw_list.getitemstring(i, "cmscrw_wlbh")
		lsGxsh = dw_list.getitemstring( i, "cmscrw_gxsh")
		lsSfll = dw_list.getitemstring( i, "cmscrw_sfll")
		lsScckdlsbh = dw_list.getitemstring(i,"cmscrw_scckdlsbh")
		lsScckdflbh = dw_list.getitemstring( i, "cmscrw_scckdflbh")
		
		If isnull(lsLsbh) or trim(lsLsbh) = "" Then
			messagebox('提示信息','空行记录无需删除!')
			Return -1
		End If
		
		If isnull(lsSfll) or trim(lsSfll) = "" Then
			lsSfll = "0"
		End If
		
		// 要取消的是已经领料的
		If lsSfll = '1' Then
			Select KCCKD1_SHBZ,KCCKD1_SJDH
				Into :lsCkdshbz,:lsCkdbh
				From KCCKD1
				Where KCCKD1_LSBH = :lsScckdlsbh;
			If lsCkdshbz = '1' Then
				llCount++
				//messagebox("提示信息","生产领料单（"+lsCkdbh+"）已经审批通过，请先取消审批！")
				Continue
			End If
			// 将产品编号记录到临时表中
			lsSql =  " insert into "+isSelCmscrwTempTable+&
				"  (F_LSBH,F_CPBH,F_WLBH,F_GXSH,F_SFLL,F_SCCKDLSBH,F_SCCKDFLBH,F_FLAG) "+&
				"  values('"+lsLsbh+"','"+lsCpbh+"','"+lsWlbh+"','"+lsGxsh+"','"+lsSfll+"','"+lsScckdlsbh+"','"+lsScckdflbh+"','0') "
			If gfexesql(lsSql,sqlca) < 0 Then
				lsErr = sqlca.sqlerrtext
				Rollback;
				messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
				Return -1
			End If
		End If
		
		Select CMSCRW_FPBZ,CMSCRW_CPBH
			Into :lsFpbz,:lsCpbh
			From CMSCRW
			Where CMSCRW_LSBH = :lsLsbh;
			
		if isnull(lsFpbz) or trim(lsFpbz)="" then // 没取到就认为分配标志为未分配
			lsFpbz = "0"
		end if
		
		If lsFpbz <> '0' Then
			messagebox("提示信息","任务（"+lsRwbh+"）已经进行后续计划制定，不允许进行删除！")
			Continue
			//Return -1
		End If
		// 直接从数据库删除和更新 循环外根据临时表删除
		//Delete from CMSCRW Where CMSCRW_LSBH = :lsLsbh;
		//Update kcrkd3 Set kcrkd3_rwpcbz = '0' Where kcrkd3_jh = :lsCpbh;
	End If
Next

// f_test(isSelCmscrwTempTable,"d:\555.xls", sqlca )
// 判断出库单的审批状态
If llCount <> 0 Then
	messagebox("提示信息","领料单已经审批通过，不能取消领料！")
	Return  -1
End If

// 生产领料的时候物料要处理一下，物料编号前边加Y-
lsSql = "update "+ isSelCmscrwTempTable+" set F_WLBH='Y-'+F_WLBH where F_FLAG='0' "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","处理预置体编号时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	Return -1
End If

// 根据生产领料单的流水编号汇总一下，便于删除领料单
lsSql = "insert into "+isSelCmscrwTempTable+&
	" ( F_LSBH,F_CPBH,F_WLBH,F_GXSH,F_SFLL,F_SCCKDLSBH,F_SCCKDFLBH,F_FLAG)"+&
	" select max(F_LSBH),max(F_CPBH),max(F_WLBH),max(F_GXSH),max(F_SFLL),max(F_SCCKDLSBH),max(F_SCCKDFLBH),'1' "+&
	" from "+isSelCmscrwTempTable+&
	" where F_FLAG='0' "+&
	" group by F_SCCKDLSBH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","临时表数据处理时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	Return -1
End If

// 把领料单对应的所有的单件号都归集到临时表中
lsSql = " insert into "+isSelCmscrwTempTable+&
	" (F_LSBH,F_CPBH,F_WLBH,F_GXSH,F_SFLL,F_SCCKDLSBH,F_SCCKDFLBH,F_FLAG) "+&
	"  select '',KCCKD3_JH,'','','',KCCKD3_LSBH,KCCKD3_FLBH,'2' "+&
	"  from KCCKD3,"+isSelCmscrwTempTable+&
	"  where F_FLAG='1'  "+&
	"  and KCCKD3.KCCKD3_LSBH="+isSelCmscrwTempTable+".F_SCCKDLSBH"

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","临时表数据处理时发生错误~r~n"+lsErr+"~r~n"+lsSql)
	Return -1
End If

// 删除出库单
// 根据流水编号删除出库单1
lsSql = " delete KCCKD1 from "+isSelCmscrwTempTable+&
	"  where  KCCKD1.KCCKD1_LSBH="+isSelCmscrwTempTable+".F_SCCKDLSBH "+&
	" and "+isSelCmscrwTempTable+".F_FLAG='1' "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 根据流水编号删除出库单2
lsSql = " delete KCCKD2  from "+isSelCmscrwTempTable+&
	" where  KCCKD2.KCCKD2_LSBH="+isSelCmscrwTempTable+".F_SCCKDLSBH  "+&
	"  and  "+isSelCmscrwTempTable+".F_FLAG='1'  "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 根据流水编号删除出库单3
lsSql = " delete KCCKD3  from "+isSelCmscrwTempTable+&
	" where  KCCKD3.KCCKD3_LSBH="+isSelCmscrwTempTable+".F_SCCKDLSBH "+&
	"  and  "+isSelCmscrwTempTable+".F_FLAG='1' "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新超码生产任务的标志
lsSql = " update  CMSCRW  set  CMSCRW_SCCKDLSBH='', CMSCRW_SCCKDFLBH='' "+&
	"  from "+isSelCmscrwTempTable+&
	"  where  CMSCRW.CMSCRW_CPBH="+isSelCmscrwTempTable+".F_CPBH  "+&
	"  and  "+isSelCmscrwTempTable+".F_FLAG='2' "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 回写已领料标志
//  更新产品状态为未领料
// 根据临时表去更新
lsSql = " update CMSCRW set CMSCRW_SFLL='0' "+&
	" from "+isSelCmscrwTempTable+&
	" where CMSCRW.CMSCRW_CPBH="+isSelCmscrwTempTable+".F_CPBH "+&
	" and   "+isSelCmscrwTempTable+".F_FLAG='2' "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 更新入库单单件的状态KCRKD3_RWPCBZ 更新成0
lsSql = " update KCRKD3 set KCRKD3.KCRKD3_RWPCBZ='0'  from KCRKD3, "+isSelCmscrwTempTable+&
	" where  KCRKD3.KCRKD3_JH="+isSelCmscrwTempTable+".F_CPBH  "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

// 删除生产任务
lsSql = "  delete  CMSCRW from  "+isSelCmscrwTempTable+"  "+&
	"  where  CMSCRW.CMSCRW_LSBH="+isSelCmscrwTempTable+".F_LSBH  "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	Return -1
End If

Commit;

// 列表刷新一下
dw_list.retrieve( )
llcnt = dw_list.rowcount()
If llcnt < 1 Then
	//	dw_master.reset()
	//	dw_master.insertrow(0)
Else
	dw_list.scrolltorow(1)
	dw_list.selectrow(0,false)
	dw_list.selectrow(1,true)
	lsLsbh = dw_list.getitemstring(1,'cmscrw_lsbh')
	//	dw_master.retrieve(lslsbh)
End If

isDjModel = "QUERY"

Return 1

//vbselect = dw_list.isselected(1)

//		If dw_list.deleterow(i) < 1 Then
//			messagebox("提示信息","任务（"+lsRwbh+"）删除失败！")
//			Continue
//			//			Exit;
//			//			Return -1
//		Else
////			vbselect = dw_list.isselected(1)
//			//dw_list.update()
//			// 将入库单3的任务排产标志更新一下，更新为尚未排产
//			Update kcrkd3 Set kcrkd3_rwpcbz = '0' Where kcrkd3_jh = :lsCpbh;
////			vbselect = dw_list.isselected(1)
//			//Commit;
//		End If
// 本表数据删除
// 删除当前行
//If dw_list.deleterow(0) = 1 Then
//	dw_list.update()
//	Update kcrkd3 Set kcrkd3_rwpcbz = '0' Where kcrkd3_jh = :lsCpbh;
//	Commit;
//End If
