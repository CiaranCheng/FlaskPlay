using System;
using System.Collections.Generic;
using PsAppService.Models;
using PsAppService.Services;
using PsAppService.Utils;
using Newtonsoft.Json;

using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace PsAppService.Controllers
{
    public class DispatchController : Controller
    {
        // GET: Dispatch
        public ActionResult Index()
        {
            return View();
        }
        /// <summary>
        /// 保存派工单
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        //[TokenAuthorize(true)]
        public ActionResult Save()
        {
            string str_data = Request.Params["dispatchdata"];
            //string tel = Request.Headers["tel"]; //"18660803819";//Request.Form["tel"];
            string tel = "15628873500";

            string[] ret = null;

            //LogHelper.Info(str_data);

            //Log.WriteLog("Run", "RunLog", str_data);

            DispatchModel pgd = JsonConvert.DeserializeObject<DispatchModel>(str_data);
            ret = DispatchService.saveorupdate(tel, pgd).Split(';');

            object resp = null;
            if (ret[0].Equals("0"))
            {
                resp = new { code = 0, msg = ret[1] };
            }
            else
            {
                resp = new { code = -1, msg = ret[0] };

                Log.WriteLog("Err", "ErrLog", ret[0]);

            }
            return Json(resp, JsonRequestBehavior.AllowGet);
        }

        // 生产任务列表
        [HttpGet]
        //[TokenAuthorize(true)]
        public JsonResult ProductAssignmentList()
        {
            //string tel = Request.Headers["tel"];
            string tel = "15628873500";
            object resp = DispatchService.ProductAssignmentList(tel);
            return Json(resp, JsonRequestBehavior.AllowGet);
        }

        // 生产任务列表(根据尾号过滤)
        [HttpGet]
        //[TokenAuthorize(true)]
        public JsonResult ProductAssignmentSearch()
        {

            //string tel = Request.Headers["tel"];
            string cpbhend = Request.Params["cpbhend"];
            string gxmc = Request.Params["gxmc"];
            string wlmc = Request.Params["wlmc"];
            string tel = "15628873500";
            object resp = DispatchService.ProductAssignmentSearch(tel,cpbhend,gxmc,wlmc);
            return Json(resp, JsonRequestBehavior.AllowGet);
        }

        // 待完工任务列表 CompleteAssignmentList
        [HttpGet]
        //[TokenAuthorize(true)]
        public JsonResult CompleteAssignmentList()
        {
            //string tel = Request.Headers["tel"];
            string tel = "15628873500";
            object resp = DispatchService.CompleteAssignmentList(tel);
            return Json(resp, JsonRequestBehavior.AllowGet);
        }

        // 待完工任务列表(根据尾号过滤)
        [HttpGet]
        //[TokenAuthorize(true)]
        public JsonResult CompleteAssignmentSearch()
        {
            //string tel = Request.Headers["tel"];
            string cpbhend = Request.Params["cpbhend"];
            string tel = "15628873500";
            object resp = DispatchService.CompleteAssignmentSearch(tel, cpbhend);
            return Json(resp, JsonRequestBehavior.AllowGet);
        }

        // 这里jsonresult 和 actionresult有何区别
        // 炉次列表
        [HttpGet]
        //[TokenAuthorize(true)]
        public JsonResult FurnacePlanList()
        {
            //string tel = Request.Headers["tel"];
            string tel = "15628873500";
            object resp = DispatchService.FurnacePlanList(tel);
            return Json(resp, JsonRequestBehavior.AllowGet);
        }
        [HttpGet]
        //[TokenAuthorize(true)]
        public JsonResult FurnacePlanSearch()
        {
            //string tel = Request.Headers["tel"];
            string sbbh = Request.Params["sbbh"];
            string tel = "15628873500";
            object resp = DispatchService.FurnacePlanSearch(tel,sbbh);
            return Json(resp, JsonRequestBehavior.AllowGet);
        }
    }
}