from greendale import app
from flask import render_template

from greendale.forms import LoginForm

import pymssql

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

