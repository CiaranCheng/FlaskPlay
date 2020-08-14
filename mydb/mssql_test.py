import pymssql
from flask_sqlalchemy import SQLAlchemy
from flask import Flask


app = Flask(__name__)
# 设置数据库URI
app.config['SQLALCHEMY_DATABASE_URI'] = 'mssql+pymssql://lc0049999:cwpass12!@localhost:1433/cwbase4?charset=utf8'
# connect = pymssql.connect('(local)', 'lc0049999', 'cwpass12!', 'cwbase4')  #建立连接
# app.config['SQLALCHEMY_DATABASE_URI']='mssql+pymssql://sa:0@localhost:1433/py1db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = True
# SQLALCHEMY_TRACK_MODIFICATIONS = False
db = SQLAlchemy(app)

# 注意缩进
class studentsps(db.Model):
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

if __name__ == '__main__':
   db.create_all()