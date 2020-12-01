from greendale import app
from flask import render_template
from jinja2 import Markup
from greendale.forms import LoginForm
from pyecharts.charts.basic_charts.bar import Bar 


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
    # filename = r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/AB_NYC_2019.csv/AB_NYC_2019.csv'
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
    return c

    # 上面的这种方式是 链式调用
    # -> Bar是指返回的数据类型是Bar类
@app.route("/echartbar")
def chartrender():
    c = bar_base()
    return Markup(c.render_embed())

@app.route("/bar")
def csvrender():
    filename = r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/AB_NYC_2019.csv/AB_NYC_2019.csv'
    df_tb = pd.read_csv(filename)
    