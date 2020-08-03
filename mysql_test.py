import pymysql
from flask_sqlalchemy import SQLAlchemy
from flask import Flask


app = Flask(__name__)
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

if __name__ == '__main__':
    # db.create_all()
    stu1 = students('ciaran','Jinan','Tangye','无')
    stu2 = students('binbin','Jinan','Gaoxin','无')
    # db.session.add(stu1)
    # db.session.add(stu2)
    # db.session.commit()