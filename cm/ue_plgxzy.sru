//====================================================================
// 事件: u_cj_xacm_cjplgxzy.ue_plgxzy()
//--------------------------------------------------------------------
// 描述: 批量工序转移
//--------------------------------------------------------------------
// 参数:
//--------------------------------------------------------------------
// 返回:  integer
//--------------------------------------------------------------------
// 依赖:
//--------------------------------------------------------------------
// 作者:	yukk		日期: 2017年09月08日
//--------------------------------------------------------------------
//	PS事业部
//--------------------------------------------------------------------
// 修改历史:
//
//====================================================================
// 考虑下末道工序转序怎么处理
// 末道工序只是入库就可以了，不需要再转序了
string lsSql,lsErr // sql语句、sql执行Err
long liCount
integer i
string lsSelect // 是否选择
string lsLsbh,lsFlbh,lsCpbh,lsGxsh // 流水编号、分录编号、产品编号、工序顺号
string lsParm // 参数
string lsWlbh // 物料编号
nvo_select lNvoSelect // 利用sql取值对象
long llWlgs,llGxgs // 物料个数、工序个数
string lsNextGxsh // 下道工序顺号
n_ds lnDs // 数据存储
string lsScrwlsbh,lsScrwRwbh // 生产任务流水编号、生产任务编号
long llRow
n_ds lndsDjbh // 单据编号生成使用数据存储
n_bhff_bhcreate iuo_bhff // 单据编号生成对象
string lsNextgxbh // 下道工序编号
decimal ldZgs
string lsScrwh
string lsSfzxFilter
string lsSfzx
string lsGxbh
string lsYjjfGxbh // 已机加否工艺路线
string lsNextGylxbh,lsNextGylxFlbh // 下道工艺路线的流水编号、分录编号
String lsZxbh // 转序编号
String lsLsbhMax,lsFlbhMax,lsGxshMax // 要转序的最大的工序顺号，对应的流水号、分录号
string lsnextgxbh1  // 20210324 下道 工序编号
decimal vdfsl1 
string vsgylxbhori,vsxgsj,vsgxmcnew,vsgxmsnew

gf_sethelp("正在进行工序转移处理......")

// 如果是转序后，就直接返回
lsSfzxFilter = dw_filter.getitemstring(dw_filter.getrow(),"f_sfzx")
If isnull(lsSfzxFilter) or trim(lsSfzxFilter) = "" Then
	lsSfzxFilter = "1" // 未获取到就设置为已转序
End If
If lsSfzxFilter = "1" Then
	messagebox("提示信息","转序后工序不允许重复进行转序！")
	gf_closehelp()
	Return -1
End If

// 看是否有需要进行工序转移的数据
If dw_data.rowcount() < 1 Then
	messagebox("提示信息","没有进行工序转移的数据！")
	gf_closehelp()
	Return -1
End If

// 清空一下临时表----待转移产品工序临时表
lsSql = "truncate table " + isDzyCpGxTempTable
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox('提示信息','出错!'+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

lsSql = "truncate table " + isusedgxbh
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox('提示信息','出错!'+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If


// 循环数据窗口将选择的数据存入临时表中，便于后续操作
// 必须是工序顺号相同的才能指定相同的下道工序
lsLsbhMax = ""
lsFlbhMax = ""
lsGxshMax = ""
liCount = 0

// 考虑两人同时转序的情况，两个人都刷新出来了，
// 然后都转序，就会重复生成，考虑如何处理20180626
// 业务场景：两个人都将待转序的同样的内容刷新出来了，
// 其中一个人转序了，另外一个人还能转序
// 这样就造成了重复转序
For i = 1 to dw_data.rowcount( )
	lsSelect = dw_data.getitemstring( i,"f_select")
	If lsSelect <> '1' Then
		Continue
	End If
	lsLsbh = dw_data.getitemstring(i,"cmcjscrwgy_lsbh")
	lsFlbh = dw_data.getitemstring(i,"cmcjscrwgy_flbh")
	lsCpbh = dw_data.getitemstring(i,"cmcjscrwgy_cpbh")
	lsGxsh = dw_data.getitemstring(i,"cmcjscrwgy_gxsh")
	lsWlbh = dw_data.getitemstring(i,"cmcjscrwcp_wlbh")
	lsScrwh = dw_data.getitemstring(i,"cmcjscrwcp_scrwh")
	lsSfzx = dw_data.getitemstring(i,"cmcjscrwgy_sfzx")
	lsGxbh = dw_data.getitemstring( i, "cmcjscrwgy_gxbh")
	vdfsl1 = dw_data.getitemdecimal( i, "cmcjscrwgy_fsl1")
	if isnull(vdfsl1) then vdfsl1= 0

	vsgylxbhori= dw_data.getitemstring( i, "cmcjscrwgy_gylxbh")
	
	// 已转序的直接跳过去
	If lsSfzx = "1" Then
		Continue
	End If
	
	// 是否转序标志从数据库中获取一下更保险，更真实
	// 如果从当前界面获取，可能会出现重复转序的情况
	
	
	// 记录转序转序到最大的工序顺号的零件
	if lsGxsh > lsGxshMax then
		lsLsbhMax = lsLsbh
		lsFlbhMax = lsFlbh
		lsGxshMax = lsGxsh
	end if
	
	// 将产品编号记录到临时表中
	lsSql =  " insert into "+isDzyCpGxTempTable+"(F_ID,F_LSBH,F_FLBH,F_WLBH,F_CPBH,F_GYLXBH,F_GXSH,F_SCRWH ,F_GXBH,F_FSL1)  "+&
			" values("+string(liCount+1)+",'"+lsLsbh+"','"+lsFlbh+"','"+lsWlbh+"','"+lsCpbh+"','"+vsgylxbhori+"', '"+lsGxsh+"','"+lsScrwh+"','"+lsGxbh+"', "+string(vdfsl1)+") "
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
		gf_closehelp()
		Return -1
	End If
	
	lsSql =  " insert into "+isusedgxbh+"( F_CPBH )   values( '"+lsCpbh+"' ) "
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
		gf_closehelp()
		Return -1
	End If
	
	liCount++
Next

If liCount < 1 Then
	messagebox("提示消息","请选择需要进行工序转移的任务！")
	gf_closehelp()
	Return -1
End If

// 考虑根据流水编号、分录编号联查CMCJSCRWGY
// 将数据库中已经转序的数据从临时表中删掉



// 合法性判断
// 批量选择的考虑如何判断是否是允许批量指定下道工序的
// 工序编号相同的话就可以批量指定下道工序
// 客户要求屏蔽
//lsSql = "select count(distinct(F_WLBH)) as F_WLGS from "+isDzyCpGxTempTable
//lNvoSelect.of_select( lsSql, llWlgs, lsErr)
//If isnull(llWlgs) Then
//	llWlgs = 0
//End If
//
//lsSql = "select count(distinct(F_GXSH)) as F_WLGS from "+isDzyCpGxTempTable
//lNvoSelect.of_select( lsSql, llGxgs, lsErr)
//If isnull(llGxgs) Then
//	llGxgs = 0
//End If
//
////If llWlgs <> 1 Then
////	Rollback;
////	messagebox("提示信息","批量进行下道工序指定时，只能选择同一种物料！")
////	Return -1
////Else
//	If llGxgs <> 1 Then
//		Rollback;
//		messagebox("提示信息","批量进行下道工序指定时，只能选择同一工序顺号！")
//		gf_closehelp()
//		Return -1
//	End If
////End If

// 打开弹窗选择下道工序
// 用的循环取的最后一个的，实际上都是一样的工艺路线
// 取最后的是不可以的，需要取目前最大的
string lsGylxbh,lsGylxFlbh // 工艺路线编号、工艺路线分录编号

//Select CMCJSCRWGY_GYLXBH,CMCJSCRWGY_GYLXFLBH
//	Into :lsGylxbh,:lsGylxFlbh
//	From CMCJSCRWGY
//	Where CMCJSCRWGY_LSBH = :lsLsbh and CMCJSCRWGY_FLBH = :lsFlbh;
Select CMCJSCRWGY_GYLXBH,CMCJSCRWGY_GYLXFLBH
	Into :lsGylxbh,:lsGylxFlbh
	From CMCJSCRWGY
	Where CMCJSCRWGY_LSBH = :lsLsbhMax and CMCJSCRWGY_FLBH = :lsFlbhMax;

If isnull(lsGylxbh) or trim(lsGylxbh) = "" or isnull(lsGylxFlbh) or trim(lsGylxFlbh) = "" Then
	Rollback;
	messagebox("提示信息","获取工艺路线失败！")
	gf_closehelp()
	Return -1
End If

//lsParm = lsLsbh+";"+lsFlbh+";"+lsGxsh
//lsParm = lsGylxbh+";"+lsFlbh+";"+lsGxsh

lsParm = lsGylxbh+";"+lsFlbhMax+";"+lsGxshMax+";"+isusedgxbh //20210519 工序选择放开自由选择

//lsParm = lsGylxbh+";"+lsFlbhMax+";"+lsGxshMax //20210519 工序选择放开自由选择

if lsGylxbh ='01' then
	 lsParm = "01" +";"+"0000000002"  +";;" + isusedgxbh
end if
 
//lsNextGylxbh = "01"
//lsNextGylxflbh = "0000000002"
//lsParm = "01" +";"+"0000000002"  +";"
 
openwithparm(w_cj_xacm_xdgxxz,lsParm)

lsParm = message.stringparm
If isnull(lsParm) or trim(lsParm) = "" or lsParm = "cancel" Then
	Rollback;
	messagebox("提示信息","未选择下道工序，转序失败！")
	gf_closehelp()
	Return -1
End If

// 下道工序（要转序到）的工艺路线编号、工艺路线分录编号、工序顺号
//lsNextGxsh = lsParm // 下道工序的工序顺号
lsNextGylxbh = get_token(lsParm,";")
lsNextGylxFlbh = get_token(lsParm,";")
lsNextGxsh = get_token(lsParm,";")
lsYjjfGxbh = get_token(lsParm,";")
lsZxbh = get_token(lsParm,";") // 交接单号（转序编号）
lsnextgxbh1 = get_token(lsParm,";") // 20210324 下道工序编号

string vspswcbz 
long llfind
// 20210520 判断下道工序如果是包装工序 需要判断评审完成标志
//if lsnextgxbh1 = '10' then
//	//vspswcbz = //lsGxsh = dw_data.getitemstring(i,"cmcjscrwgy_gxsh")
//	llfind = dw_data.find("f_select='1' and cmcjscrwgy_pswcbz <> '1' ",1,dw_data.rowcount())
//	if llfind > 0 then 
//		messagebox("提示信息","第 "+ string (llfind)+" 行审批未完成 ，不能转到包装工序")
//		gf_closehelp()
//		Return -1
//	end if
//end if

//begin 20210602 自动生成转序交接单，记录交接单号，  不使用工序选择窗口中手工录入的交接单号
//更新转序前的工序名称、工序描述
//生成单据编号
string vsjjdlsh ,vsjjdbh
vsjjdlsh = gsf_getnbbm_new("ZXJJD")
If isnull(vsjjdlsh) or trim(vsjjdlsh) = "" Then
	Rollback;
	setpointer(Arrow!)
	messagebox("提示信息","获取交接单流水编号失败！")
	gf_closehelp()
	Return -1
End If
 
If isvalid(lndsDjbh) Then
	lndsDjbh.reset()
Else
	lndsDjbh = create n_ds
	lndsDjbh.dataobject = "dw_cj_zxjjd_master"
End If

llRow = lndsDjbh.insertrow(0)

lndsDjbh.setitem(llRow,"zxjjd1_djrq",gsCwrq)
//lndsDjbh.setitem(llRow,'kcrkd1_kcywrq',lsKcywrq)
//lndsDjbh.setitem(llRow,'kcrkd1_lbbh',lsLbbh)
//lndsDjbh.setitem(llRow,'kcrkd1_bmbh',lsBmbh)
//lndsDjbh.setitem(llRow,'kcrkd1_ckbh',lsCkbh)
iuo_bhff.ib_auto_updatelsbh = true
iuo_bhff.uf_createbh("ZXJJD",vsjjdbh,lndsDjbh,1,lsErr,sqlca)
If vsjjdbh = '' Then
	Rollback;
	messagebox("提示信息","获取交接单编号失败!"+lsErr)
	gf_closehelp()
	Return -1
End If

lsSql =  " UPDATE "+isDzyCpGxTempTable+" SET F_GXMC = CMBZGYLX_GXMC,F_GXMS  =CMBZGYLX_GXMS  "+&
		" FROM CMBZGYLX WHERE CMBZGYLX_GYLXBH = F_GYLXBH AND CMBZGYLX_GXSH = F_GXSH AND CMBZGYLX_GXBH = F_GXBH "		
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

lsSql =  " UPDATE "+isDzyCpGxTempTable+" SET F_JJDLS = '"+vsjjdlsh+"' ,F_JJDFL = right(10000000000+ F_ID  ,10)  "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If


//ZXJJD1
vsxgsj = gfgetservertime()
SELECT  CMBZGYLX_GXMC,CMBZGYLX_GXMS INTO :vsgxmcnew,:vsgxmsnew FROM CMBZGYLX 
WHERE CMBZGYLX_GYLXBH = :lsNextGylxbh AND CMBZGYLX_GXBH = :lsnextgxbh1 AND CMBZGYLX_GXSH = :lsNextGxsh ;
if isnull(vsgxmcnew) then vsgxmcnew = ''
if isnull(vsgxmsnew) then vsgxmsnew = ''
lssql = "INSERT INTO ZXJJD1(ZXJJD1_LSBH,ZXJJD1_SJDH,ZXJJD1_DJRQ,ZXJJD1_XGSJ,ZXJJD1_ZDR,ZXJJD1_GYLXBH,ZXJJD1_GXBH,ZXJJD1_GXMC,ZXJJD1_GXSH,ZXJJD1_GXMS,ZXJJD1_BZ) "	+&
		 " VALUES ('"+vsjjdlsh+"','"+vsjjdbh+"','"+gscwrq+"','"+vsxgsj+"','"+gsusername+"','"+lsNextGylxbh+"','"+lsnextgxbh1+"','"+vsgxmcnew+"','"+lsNextGxsh+"','"+vsgxmsnew+"','"+lsZxbh+"'   ) "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

//zxjjd2 
lssql = "INSERT INTO ZXJJD2(ZXJJD2_LSBH,ZXJJD2_FLBH,ZXJJD2_WLBH,ZXJJD2_WLMC,ZXJJD2_CPBH,ZXJJD2_SL ,ZXJJD2_FSL1,ZXJJD2_GYLXBH,ZXJJD2_GXBH ,ZXJJD2_GXMC,ZXJJD2_GXSH,ZXJJD2_GXMS ) "	+&
		 " SELECT F_JJDLS,F_JJDFL,F_WLBH,LSWLZD_WLMC,F_CPBH,1,F_FSL1,F_GYLXBH,F_GXBH,F_GXMC,F_GXSH,F_GXMS FROM "+isDzyCpGxTempTable +" , LSWLZD WHERE F_WLBH = LSWLZD_WLBH "
If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If
//lsZxbh = vsjjdbh
//end 20210602 


// 临时表数据放入datastore中进行循环
lnDs = create n_ds
lsSql = " select F_LSBH,F_FLBH,F_WLBH,F_CPBH,F_GXSH,F_NEXTSCRWLSBH,F_NEXTSCRWRWBH,F_SCRWH,F_FSL1 from " + isDzyCpGxTempTable
If gf_createds(lsSql,lnDs) = -1 Then
	messagebox("提示信息","创建datastore失败！")
	gf_closehelp()
	Return -1
End If

For i = 1 to lnDs.rowcount()
	// 生成新的生产任务
	// 生产任务流水编号
	lsScrwlsbh = gsf_getnbbm_new("CMSCRW")
	If isnull(lsScrwlsbh) or trim(lsScrwlsbh) = "" Then
		Rollback;
		setpointer(Arrow!)
		messagebox("提示信息","获取生产任务流水编号失败！")
		gf_closehelp()
		Return -1
	End If
	
	// 生产任务单据编号，生产任务编号的产生
	// 实际单号生成 ，需要再测试验证
	If isvalid(lndsDjbh) Then
		lndsDjbh.dataobject = "dw_scrwd_master"
		lndsDjbh.reset()
	Else
		lndsDjbh = create n_ds
		lndsDjbh.dataobject = "dw_scrwd_master"
	End If
	
	llRow = lndsDjbh.insertrow(0)
	
	lndsDjbh.setitem(llRow,"cmscrw_csrq",gsCwrq)
	//lndsDjbh.setitem(llRow,'kcrkd1_kcywrq',lsKcywrq)
	//lndsDjbh.setitem(llRow,'kcrkd1_lbbh',lsLbbh)
	//lndsDjbh.setitem(llRow,'kcrkd1_bmbh',lsBmbh)
	//lndsDjbh.setitem(llRow,'kcrkd1_ckbh',lsCkbh)
	iuo_bhff.ib_auto_updatelsbh = true
	iuo_bhff.uf_createbh("CMSCRW",lsScrwRwbh,lndsDjbh,1,lsErr,sqlca)
	If lsScrwRwbh = '' Then
		Rollback;
		messagebox("提示信息","获取生产任务单任务编号失败!"+lsErr)
		gf_closehelp()
		Return -1
	End If
	
	lsLsbh = lnDs.getitemstring(i,"f_lsbh")
	lsFlbh = lnDs.getitemstring(i,"f_flbh")
	
	// 把新生成的流水编号、任务编号更新回临时表中
	lsSql = "update " + isDzyCpGxTempTable + " set F_NEXTSCRWLSBH='"+lsScrwlsbh+"',F_NEXTSCRWRWBH='"+lsScrwRwbh+"',F_GXSH ='"+lsNextGxsh+"',F_GXBH='"+lsYjjfGxbh+"' "+&
		" where F_LSBH='"+lsLsbh+"' and F_FLBH='"+lsFlbh+"' "
	
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新任务流水编号，任务编号出错！"+lsErr+"~r~n"+ lsSql)
		gf_closehelp()
		Return -1
	End If
	
Next

// 注销掉datastore
//destroy lnDs //20210324 生成条码号再销毁


// 此处可能因工序顺号的变动造成查询不到对应的生产任务工艺数据
// 因此这里需要判断是否可以在CMCJSCRWGY中查到对应工序编号，如果没有就新增一条

// 工艺路线一样的情况下，查询不到分以下几种情况，
// 1.在这条工艺路线下新增了一条工序，现在要转到这条新增的工序中，此时生产任务工艺并没有更新，因此查不到
// 2.修改了要转到的工序的顺号，导致用当前的顺号查不到生产任务工艺中的数据
// 20210624 by chengxsh

For i = 1 to lnDs.rowcount()
	lsLsbh = lnDs.getitemstring(i,"f_lsbh")
	lsFlbh = lnDs.getitemstring(i,"f_flbh")

	Select  CMCJSCRWGY_GXBH,CMCJSCRWGY_ZGS
		Into :lsNextGxbh,:ldZgs
		From CMCJSCRWGY
		Where CMCJSCRWGY_LSBH = :lsLsbh
		and CMCJSCRWGY_GXSH = :lsNextGxsh;
	// And CMCJSCRWGY_FLBH = :lsFlbh	
	If isnull(lsCpbh) or trim(lsCpbh) = "" Then
		Rollback;
		lsCpbh = ""
		messagebox("提示信息","获取生产任务单产品编号失败!")
		gf_closehelp()
		Return -1
	End If

	If isnull(lsNextgxbh) or trim(lsNextgxbh) = "" Then

		lsSql = "INSERT INTO CMCJSCRWGY (CMCJSCRWGY_LSBH,CMCJSCRWGY_FLBH,CMCJSCRWGY_CPBH,CMCJSCRWGY_GXSH,"+&
			" CMCJSCRWGY_GXBH,CMCJSCRWGY_RWLS,CMCJSCRWGY_RWBH,CMCJSCRWGY_JHLS,CMCJSCRWGY_JHFL,"+&
			" CMCJSCRWGY_JHBH,CMCJSCRWGY_KGRY,CMCJSCRWGY_KGRQ,CMCJSCRWGY_WGRY,CMCJSCRWGY_WGRQ,"+&
			" CMCJSCRWGY_GXZT,CMCJSCRWGY_SFCJ,CMCJSCRWGY_SFZX,CMCJSCRWGY_GZZX,CMCJSCRWGY_ZGS,CMCJSCRWGY_SJGS,"+&
			" CMCJSCRWGY_ZSL,CMCJSCRWGY_HGSL,CMCJSCRWGY_BFSL,CMCJSCRWGY_SFSDGX,CMCJSCRWGY_SFMDGX,"+&
			" CMCJSCRWGY_ZJJG,CMCJSCRWGY_NEXTSCRWLSBH,CMCJSCRWGY_GYLXBH,CMCJSCRWGY_GYLXFLBH,"+&
			" CMCJSCRWGY_SCPC,CMCJSCRWGY_ZXRY,CMCJSCRWGY_ZXRQ,CMCJSCRWGY_ZXBH,CMCJSCRWGY_PSWCBZ,"+&
			" CMCJSCRWGY_PSWCRQ,CMCJSCRWGY_FSL1,CMCJSCRWGY_JJDLS,CMCJSCRWGY_JJDFL)"+&
			" SELECT CMCJSCRWGY_LSBH,'"+lsNextGylxFlbh+"',CMCJSCRWGY_CPBH,'"+lsNextGxsh+"','"+lsYjjfGxbh+"',CMCJSCRWGY_RWLS,"+&
			" CMCJSCRWGY_RWBH,CMCJSCRWGY_JHLS,CMCJSCRWGY_JHFL,CMCJSCRWGY_JHBH,'','','','','G0','0','1',CMCJSCRWGY_GZZX,CMCJSCRWGY_ZGS,CMCJSCRWGY_SJGS,CMCJSCRWGY_ZSL,"+&
			" CMCJSCRWGY_HGSL,CMCJSCRWGY_BFSL,'0','0',CMCJSCRWGY_ZJJG,"+&
			" '',CMCJSCRWGY_GYLXBH,'"+lsNextGylxFlbh+"',CMCJSCRWGY_SCPC,'"+gsusername+"',"+&
			" '"+gscwrq+"','','0','',CMCJSCRWGY_FSL1,"+&
			" CMCJSCRWGY_JJDLS,CMCJSCRWGY_JJDFL FROM CMCJSCRWGY WHERE CMCJSCRWGY_LSBH = '"+lsLsbh+"' "+&
			" AND CMCJSCRWGY_FLBH ='"+lsFlbh+"' ";

		If gfexesql(lsSql,sqlca) < 0 Then
			lsErr = sqlca.sqlerrtext
			Rollback;
			messagebox("提示信息","新增生产任务工艺数据时出错！"+lsErr+"~r~n"+ lsSql)
			gf_closehelp()
			Return -1
		End If

		// Select  CMCJSCRWGY_GXBH,CMCJSCRWGY_ZGS
		// 	Into :lsNextGxbh,:ldZgs
		// 	From CMCJSCRWGY
		// 	Where CMCJSCRWGY_LSBH = :lsLsbh
		// 	and CMCJSCRWGY_GXSH = :lsNextGxsh;
		// If isnull(lsNextgxbh) or trim(lsNextgxbh) = "" Then
		// 	Rollback;
		// 	lsNextgxbh = ""
		// 	messagebox("提示信息","获取生产任务工序编号失败!")
		// 	gf_closehelp()
		// 	Return -1
		// End If
	End If
Next

// If isnull(ldZgs) Then
// 	ldZgs = 0
// End If
// 总工时没用,之前这种取值方法也是错的,只能取到一条 (｀_ゝ´),这里直接置为0
// 20210624	by chengxsh
ldZgs = 0



sqlca.autocommit = false
// 此处工艺路线分录编号总是更新为01，不知道为啥
// 是否领料更新为1，已领料
lsSql = 	"insert into CMSCRW( CMSCRW_LSBH,CMSCRW_RWBH,CMSCRW_RWLY,CMSCRW_CPBH,"+&
	" CMSCRW_GXSH,CMSCRW_GXBH,CMSCRW_CSRQ,"+&
	" CMSCRW_SFLL,CMSCRW_FPBZ,CMSCRW_FPRY,CMSCRW_FPRQ,CMSCRW_DEGS,CMSCRW_WLBH,CMSCRW_GYLXBH,CMSCRW_SCRWH,CMSCRW_GYLXFLBH, CMSCRW_FSL1 ) "+&
	" select F_NEXTSCRWLSBH,F_NEXTSCRWRWBH,'GXZYD',F_CPBH,"+&
	" '"+lsNextGxsh+"','"+lsNextgxbh+"','"+gsCwrq+"',"+&
	" '1','0','','',"+string(ldZgs)+",F_WLBH,'"+lsNextGylxbh+"',F_SCRWH,'"+lsNextGylxFlbh+"' ,F_FSL1 "+&
	" from "+isDzyCpGxTempTable

//lsSql = 	"insert into CMSCRW( CMSCRW_LSBH,CMSCRW_RWBH,CMSCRW_RWLY,CMSCRW_CPBH,"+&
//	" CMSCRW_GXSH,CMSCRW_GXBH,CMSCRW_CSRQ,"+&
//	" CMSCRW_FPBZ,CMSCRW_FPRY,CMSCRW_FPRQ,CMSCRW_DEGS,CMSCRW_WLBH,CMSCRW_GYLXBH,CMSCRW_SCRWH,CMSCRW_GYLXFLBH) "+&
//	" select F_NEXTSCRWLSBH,F_NEXTSCRWRWBH,'GXZYD',F_CPBH,"+&
//	" '"+lsNextGxsh+"','"+lsNextgxbh+"','"+gsCwrq+"',"+&
//	" '0','','',"+string(ldZgs)+",F_WLBH,'"+lsNextGylxbh+"','"+lsNextGylxFlbh+"',F_SCRWH "+&
//	" from "+isDzyCpGxTempTable
//

//lsSql = 	"insert into CMSCRW( CMSCRW_LSBH,CMSCRW_RWBH,CMSCRW_RWLY,CMSCRW_CPBH,"+&
//	" CMSCRW_GXSH,CMSCRW_GXBH,CMSCRW_CSRQ,"+&
//	" CMSCRW_FPBZ,CMSCRW_FPRY,CMSCRW_FPRQ,CMSCRW_DEGS,CMSCRW_WLBH,CMSCRW_GYLXBH,CMSCRW_GYLXFLBH,CMSCRW_SCRWH) "+&
//	" select F_NEXTSCRWLSBH,F_NEXTSCRWRWBH,'GXZYD',F_CPBH,"+&
//	" '"+lsNextGxsh+"','"+lsNextgxbh+"','"+gsCwrq+"',"+&
//	" '0','','',"+string(ldZgs)+",F_WLBH,'"+lsNextGylxbh+"','0000000005',F_SCRWH "+&
//	" from "+isDzyCpGxTempTable

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","生成新的生产任务时出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

//  更新工序转序状态为已转序，工序状态更新为已转序，转序生成的生产任务的流水编号，
// 记录转序时间和转序人员
lsSql = "update CMCJSCRWGY "+&
	" set CMCJSCRWGY_SFZX='1',CMCJSCRWGY_GXZT='G5',"+&
	" CMCJSCRWGY_NEXTSCRWLSBH = F_NEXTSCRWLSBH,"+&
	" CMCJSCRWGY_ZXRY='"+GsUserName+"',"+&
	" CMCJSCRWGY_ZXRQ='"+gsCwrq+"', "+&
	" CMCJSCRWGY_ZXBH='"+vsjjdbh+"' ,CMCJSCRWGY_JJDLS = F_JJDLS,CMCJSCRWGY_JJDFL=F_JJDFL,CMCJSCRWGY_BZ='"+lsZxbh+"'  "+&
	" from "+isDzyCpGxTempTable +&
	" where CMCJSCRWGY_LSBH=F_LSBH and CMCJSCRWGY_FLBH=F_FLBH "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","更新工序状态时出错！"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If

// 根据自身的工序顺号来更新裁剪与否
// 中间跳过的工序更改为已裁剪
//lsSql = "update CMCJSCRWGY set CMCJSCRWGY_SFCJ='1',CMCJSCRWGY_GXZT='G6' "+&
//	" from "+isDzyCpGxTempTable +&
//	" where CMCJSCRWGY_LSBH=F_LSBH and CMCJSCRWGY_GXSH>'"+lsGxsh+"' and CMCJSCRWGY_GXSH<'"+lsNextGxsh+"' "

/* 20210524 去掉裁剪标志
lsSql = "update CMCJSCRWGY set CMCJSCRWGY_SFCJ='1',CMCJSCRWGY_GXZT='G6' "+&
	" from "+isDzyCpGxTempTable +&
	" where CMCJSCRWGY_LSBH=F_LSBH and CMCJSCRWGY_GXSH>"+isDzyCpGxTempTable+".F_GXSH and CMCJSCRWGY_GXSH<'"+lsNextGxsh+"' "

If gfexesql(lsSql,sqlca) < 0 Then
	lsErr = sqlca.sqlerrtext
	Rollback;
	messagebox("提示信息","裁剪工序时出错!"+lsErr+"~r~n"+ lsSql)
	gf_closehelp()
	Return -1
End If
*/
//f_test(isDzyCpGxTempTable,"d:\333.xls",sqlca)

// 工序编号为08 机加工序的 要更新产品编制为已机加，15为机加外协
//If lsYjjfGxbh = '08'  or  lsYjjfGxbh = '15' Then
//	// 更新已机加否标志
//	lsSql =  " update CMCJSCRWCP set CMCJSCRWCP_YJJF='1'  "+&
//		" from "+isDzyCpGxTempTable +&
//		" where CMCJSCRWCP.CMCJSCRWCP_LSBH="+isDzyCpGxTempTable+".F_LSBH "
//	If gfexesql(lsSql,sqlca) < 0 Then
//		lsErr = sqlca.sqlerrtext
//		Rollback;
//		messagebox("提示信息","更新已机加否标志!"+lsErr+"~r~n"+ lsSql)
//		gf_closehelp()
//		Return -1
//	End If
//End If

// 转序工序编号为08 和15 的工序的时候将机加标志更新为1
lsSql =  " update CMCJSCRWCP set CMCJSCRWCP_YJJF='1'  "+&
		" from "+isDzyCpGxTempTable +&
		" where CMCJSCRWCP.CMCJSCRWCP_LSBH="+isDzyCpGxTempTable+".F_LSBH "+&
		" and ("+isDzyCpGxTempTable+".F_GXBH='08' or "+isDzyCpGxTempTable+".F_GXBH='15') "
	If gfexesql(lsSql,sqlca) < 0 Then
		lsErr = sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新已机加否标志!"+lsErr+"~r~n"+ lsSql)
		gf_closehelp()
		Return -1
	End If

// 提交数据库
Commit;

//begin add 20210323 如果下道工序是组套包装工序  编号10，需要判断生成条码
// 获取条码的流水编号
///string lsminrq,lsnumber
string lsTmlsbh,lsbmbh,lsywrq,lstmflbh
if lsnextgxbh1 = '10' then 
	lsTmlsbh = gsf_getnbbm("TMBASE")
	
	if isnull(lsTmlsbh) or lsTmlsbh = '' then
		Rollback;
		setpointer(Arrow!)
		messagebox('提示信息','未取得条码的流水编号!')
		return -1
	end if
	for i = 1 to lnDs.rowcount()
		//F_WLBH,F_CPBH,F_GXSH
		lsBmbh = ""
		lsYwrq = string(now(),'yyyymmdd')
		lsWlbh = lnds.object.F_WLBH[i]
		
		lsCpbh = lnds.object.F_CPBH[i]
		//lsCpbm = lnDs.getitemstring(i,"cmscrwd3_bm")
		///////产品编码 尾数与产品编号一致，年份取该产品编号首次生产任务开工日期
//		条码号直接用产品编号，条形码可以识别字母和- ,不同型号产品尾数有重复，规则不确定
		///SELECT MIN(CMSCRW_FPRQ) INTO:lsminrq  FROM CMSCRW WHERE CMSCRW_CPBH = :lsCpbh;
		////if isnull(lsminrq) then lsminrq =lsYwrq
		
		lsTmflbh = string(i,"0000000000")
		// 条码类别默认设置为99，条码编号默认设置为产品编号，序号默认设置为编码后五位
		// TMBASE_FZ20存储编号，条码号为编码
		if gif_exists("TMBASE","TMBASE_TMH ='"+lsCpbh+"' ") <= 0 then
			lsSql = "insert into TMBASE(TMBASE_TMLB,TMBASE_LSBH,TMBASE_FLH,TMBASE_TMH, "+&
				" TMBASE_WLBH,TMBASE_PCH,TMBASE_ZYX1,TMBASE_ZYX2,TMBASE_ZYX3,TMBASE_ZYX4,TMBASE_ZYX5, "+&
				" TMBASE_CKBH,TMBASE_HW,TMBASE_XH,TMBASE_DATE,TMBASE_BMBH, "+&
				" TMBASE_SCBC,TMBASE_CZY,TMBASE_STATE, "+&
				" TMBASE_ZSL,TMBASE_FSL1,TMBASE_FSL2,TMBASE_DJ,TMBASE_JE, "+&
				" TMBASE_DYKZ,TMBASE_DYZS,TMBASE_DYPERSON,TMBASE_DYDATE,TMBASE_BZ, "+&
				" TMBASE_FZ20 ) "+&
				" values('99','"+lsTmlsbh+"','"+lsTmflbh+"','"+lsCpbh+"', "+&
				" '"+lsWlbh+"','',' ',' ',' ',' ',' ',"+&
				" '','','','"+lsYwrq+"','"+lsBmbh+"',"+&
				" '','"+GsUserName+"','0',"+&
				" 1,1,1,0,0,"+&
				" '0',0,'','','',"+&
				" '"+lsCpbh+"' )"
			if gfexesql(lsSql,Sqlca) < 0 then
				lsErr = Sqlca.sqlerrtext
				Rollback;
				messagebox("提示信息","生成条码信息时发生错误~r~n"+lsErr+"~r~n"+lsSql)
				gf_closehelp()
				return -1
			end if
		end if
	 next
	
	// 没有的进行插入
	lsSql = "insert into CMCPGLGX(CMCPGLGX_BM,CMCPGLGX_BH,CMCPGLGX_TMLS,CMCPGLGX_TMFL) "+&
		" select TMBASE_FZ20,TMBASE_TMH,TMBASE_LSBH,TMBASE_FLH "+&
		" from TMBASE "+&
		" where TMBASE_LSBH='"+lsTmlsbh+"' "+&
		" and not exists(select 1 from CMCPGLGX where CMCPGLGX_BM=TMBASE_FZ20 )"
	
	if gfexesql(lsSql,Sqlca) < 0 then
		lsErr = Sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","生成条码关联关系时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		gf_closehelp()
		return -1
	end if
	
	
	// 有的进行更新
	lsSql = "update CMCPGLGX "+&
		" set CMCPGLGX_TMLS=TMBASE_LSBH,CMCPGLGX_TMFL=TMBASE_FLH "+&
		" from TMBASE "+&
		" where CMCPGLGX_BM=TMBASE_TMH and TMBASE_LSBH='"+lsTmlsbh+"' "+&
		" and exists(select 1 from CMCPGLGX where CMCPGLGX_BM=TMBASE_FZ20 )"
	if gfexesql(lsSql,Sqlca) < 0 then
		lsErr = Sqlca.sqlerrtext
		Rollback;
		messagebox("提示信息","更新条码关联关系时发生错误~r~n"+lsErr+"~r~n"+lsSql)
		gf_closehelp()
		return -1
	end if
	
end if
destroy lnds
commit;
//end add
gf_closehelp()
messagebox("提示信息","批量进行下道工序指定完成！")


dw_data.retrieve()

Return 1
