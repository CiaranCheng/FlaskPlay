from greendale import app
from flask import render_template


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
@app.route('/simplate')
def simplate():
    return render_template('simplate.html',saying = 'alllhell:')
# 实际上这里使用的render_template是flask所用的原生的Jinja2模版引擎

@app.route('/data')
def getdata():
    cur = conn.cursor()
    tablename = "CGDD1"
    sql = "select * from " + tablename
    cur.execute(sql)
    content = cur.fetchall()
	# 获取表头
    sql = "Select Name FROM SysColumns Where id=Object_Id('"+tablename+"')"
    cur.execute(sql)
    labels = cur.fetchall()
    labels = [l[0] for l in labels]
    return render_template('tabletest.html', tablename = tablename ,labels=labels, content=content)

