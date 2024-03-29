from greendale import app
from flask import render_template
from jinja2 import Markup
from greendale.forms import LoginForm
from pyecharts.charts.basic_charts.bar import Bar 

import pymssql
import csv

conn = pymssql.connect(
    host='127.0.0.1',
    user='lc0519999',
    password='cwpass12!',
    database='cwbase51',
    charset='utf8'
)

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

@app.route('/data')
def getdata():
    cur = conn.cursor()
    tablename = "CGDD1"
    
	# 获取表头
    sql = "SELECT Name FROM SysColumns Where id=Object_Id('"+tablename+"')"
    cur.execute(sql)
    labels = cur.fetchall()
    fieldstr = ""
    for field in labels:
        fieldstr += (field[0] + ",")
    fieldstr = fieldstr[:-1]
    labels = [l[0] for l in labels]
    
	# 数据
    sql = "SELECT "+fieldstr+" from " + tablename
    cur.execute(sql)
    content = cur.fetchall()

    return render_template('tabletest.html', tablename = tablename ,labels=labels, content=content)


@app.route('/csvdata')
def getcsv():
    # cur.fetchall()返回多个记录(rows) 类型是 元组
    tablename = 'Airbab of NYC'
    # 此处数量过大，可分页加载
    filename = r'F:/AsCoder/Flask_test/FlaskPlay/AB_NYC_2019.csv/AB_NYC_2019.csv'
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
        .add("1",["衬衫", "羊毛衫", "雪纺衫", "裤子", "高跟鞋", "袜子"],[5, 20, 36, 10, 75, 90])
    )
    return c


@app.route("/chartrender")
def chartrender():
    c = bar_base()
    return Markup(c.render_embed())

@app.route('/render')
def setecharts():
    
    bar = Bar()
    bar.add("1",["衬衫", "羊毛衫", "雪纺衫", "裤子", "高跟鞋", "袜子"],[5, 20, 36, 10, 75, 90])
    
    # render 会生成本地 HTML 文件，默认会在当前目录生成 render.html 文件
    # 也可以传入路径参数，如 bar.render("mycharts.html")
    # bar.render()
    
    # return render_template('render.html',  myechart=bar.render_embed)

    return Markup(bar.render_embed())