import pymysql
from flask_sqlalchemy import SQLAlchemy
from flask import Flask, request, flash, url_for, redirect, render_template


app = Flask(__name__,template_folder="templates",)
# 设置数据库URI
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:cxs123123.@localhost:3306/football?charset=utf8'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = True
db = SQLAlchemy(app)
# db应在上述设置之后声明

# 注意缩进
class students(db.Model):
    id = db.Column('student_id', db.Integer, primary_key = True)
    name = db.Column(db.String(100))
    city = db.Column(db.String(50))  
    addr = db.Column(db.String(200))
    pin = db.Column(db.String(10))
    def __init__(self, name, city, addr,pin):
        self.name = name
        self.city = city
        self.addr = addr
        self.pin = pin

@app.route('/')
def show_all():
    return render_template('show_all.html', students = students.query.all() )

@app.route('/new', methods = ['GET', 'POST'])
def new():
    if request.method == 'POST':
        if not request.form['name'] or not request.form['city'] or not request.form['addr']:
            flash('Please enter all the fields', 'error')
        else:
            student = students(request.form['name'], request.form['city'],request.form['addr'], request.form['pin'])
            db.session.add(student)
            db.session.commit()
            flash('Record was successfully added')
            return redirect(url_for('show_all'))
    return render_template('new.html')

@app.route('/login', methods = ['GET', 'POST'])
def login():
    if request.method == 'POST':
        return redirect(url_for('show_all'))
    return render_template('login.html', students = students.query.all() )
if __name__ == '__main__':
    # db.create_all()
    # stu1 = students('ciaran','Jinan','Tangye','无')
    # stu2 = students('binbin','Jinan','Gaoxin','无')
    # db.session.add(stu1)
    # db.session.add(stu2)
    # db.session.commit()
    # result = students.query.all()
    # for res in result:
    #     print(res.name)
    app.run(host='0.0.0.0', port=5000)
    