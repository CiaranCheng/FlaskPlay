from greendale import app
from flask import render_template
from jinja2 import Markup
from greendale.forms import LoginForm
from pyecharts.charts.basic_charts.bar import Bar 
from pyecharts import options as opts
from pyecharts.charts import Map
import pandas as pd
import csv


# conn = pymssql.connect(host='127.0.0.1:1433',user='sa',password='123456',database='NEWPFJDB',charset='UTF-8')
@app.route('/')

@app.route('/index')
def index():
    teacher = {"dean":"Craig"}
    # if 1==2:
    #     return "Greendale is where I belong"
    # else:
    #return render_template('index.html',title = 'studyroom',teacher = teacher,saying = 'Cool!')
    return render_template('index.html', title='Home', teacher=teacher, saying='Cool!')

# 表单
@app.route('/login',methods=['POST'])
def login():
    forms = LoginForm()
    return render_template('forms.html', title='Please Login', form = forms )

@app.route('/simplate')
def simplate():
    return render_template('simplate.html',saying = 'alllhell:')
# 实际上这里使用的render_template是flask所用的原生的Jinja2模版引擎

@app.route('/csvdata')
def getcsv():
    # cur.fetchall()返回多个记录(rows) 类型是 元组
    tablename = 'Airbab of NYC'
    # 此处数量过大，可分页加载
    filename = r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/AB_NYC_2019.csv/AB_NYC_2019.csv'
    # filename = r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/Lego/乐高淘宝数据.csv'
    with open(filename,encoding = 'UTF-8') as datafile:
        # 使用DictReader可以像字典那样获取数据
        reader = csv.reader(datafile)
        datalist = list(reader)
        dreader = csv.DictReader(datafile)
        labels = dreader.fieldnames

        # 这里csv.reader函数返回的，只是可以
        labels = datalist[0]
        content = datalist
    return render_template('tabletest.html', tablename = tablename ,labels=labels, content=content)



def bar_base() -> Bar:
    c = (
        Bar()
        .add_xaxis(["衬衫", "羊毛衫", "雪纺衫", "裤子", "高跟鞋", "袜子"])
        .add_yaxis("商家A", [5, 20, 36, 10, 75, 90])
        .add_yaxis("商家B", [15, 25, 16, 55, 48, 8])
    )

    df_tb = pd.read_csv(r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/Lego/乐高淘宝数据.csv')
   
    shop_top10 = df_tb.groupby('shop_name')['purchase_num'].sum().sort_values(ascending=False).head(10)

    return c

    # 上面的这种方式是 链式调用
    # -> Bar是指返回的数据类型是Bar类

def map_base() -> Map:
    map1 = Map()

    # 取出数据
    df_tb = pd.read_csv(r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/Lego/乐高淘宝数据.csv')
   
    # 去除重复值
    df_tb.drop_duplicates(inplace=True) 
    # 删除购买人数为空的记录 
    df_tb = df_tb[df_tb['purchase_num'].str.contains('人付款')] 
    # 重置索引 
    df_tb = df_tb.reset_index(drop=True)
    df_tb['purchase_num'] = df_tb['purchase_num'].str.extract('(\d+)').astype('int')

    # 计算销售额 
    df_tb['sales_volume'] = df_tb['price'] * df_tb['purchase_num']

    #location
    df_tb['province'] = df_tb['location'].str.split(' ').str[0]

    province_num = df_tb.groupby('province')['purchase_num'].sum().sort_values(ascending=False)
    map1.add("",[list(z) for z in zip(province_num.index.tolist(),province_num.values.tolist())],maptype='china')
    # 这里第二个参数是省份列表
    # 第三个参数是省份数据列表
    
    map1.set_global_opts(title_opts = opts.TitleOpts(title='国内各产地乐高销量分布图'),visualmap_opts = opts.VisualMapOpts(max_=172277))
    return map1
    # 上面的这种方式是 链式调用
    # -> Bar是指返回的数据类型是Bar类

    # 在安装了python-dotenv之后，读取系统配置文件的顺序是  1手工设置的环境配置 2.env文件  3.flaskenv 

@app.route("/echartbar")
def chartrender():
    # c = bar_base()
    m = map_base()
    return Markup(m.render_embed())

    