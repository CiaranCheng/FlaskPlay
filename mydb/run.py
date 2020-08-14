from flask import Flask
from utils import ms_con
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column,Integer,String
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker


app = Flask(__name__)
# Flask的构造函数以当前模块的名称__name__作为参数
# Flask的一个对象就是一个WSGI应用程序

Base = declarative_base()#实例,创建基类
#所有的表必须继承于Base
class Enhancer(Base):
    __tablename__='enhancer'#定义该表在mysql数据库中的实际名称
    # 定义表的内容
    id=Column(Integer,primary_key=True)
    chr=Column(String(5),nullable=False)
    start=Column(Integer,nullable=False)
    end=Column(Integer,nullable=False)
db_connect_string='mysql+pymysql://root:cxs123123.@localhost:3306/football?charset=utf8'
#以mysql数据库为例：mysql+数据库驱动：//用户名：密码@localhost:3306/数据库
engine=create_engine(db_connect_string)#创建引擎
Sesssion=sessionmaker(bind=engine)#产生会话
session=Sesssion() #创建Session实例

@app.route('/')
def hello_world():
   return 'Hello world'

# 注意这里，app.run默认的主机是127.0.0.1,是不能被外部访问的
if __name__ == '__main__':
   # app.run(host='0.0.0.0', port=5000)
   # sel = ms_con.dbUtils.sel()
   enc = Enhancer()
   encall = enc.
   print(enc)