from flask import Flask
from config import Config

app = Flask(__name__)
app.config.from_object(Config)

from greendale import routes


# 需要注意的有以下几点
# routes需要在最下方引用和导入 这是为了解决 循环导入的问题

# import pymssql
# from flask_sqlalchemy import SQLAlchemy

# app.config['SQLALCHEMY_DATABASE_URI'] = 'mssql+pymssql://lc0049999:cwpass12!@localhost:1433/cwbase4?charset=utf8'
# app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = True
# db = SQLAlchemy(app)

# conn = pymssql.connect(
#     host='127.0.0.1',
#     user='lc0049999',
#     password='cwpass12!',
#     db='cwbase4',
#     charset='utf8'
# )
# def get_conn():
#     conn = pymssql.connect("localhost", "root", "root@123", "jike")
#     return conn