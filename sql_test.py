from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column,Integer,String

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
# 设置数据库URI
# app.config['SQLALCHEMY_DATABASE_URI'] = 'mssql+pyodbc://HARRISONS-THINK/LendApp'
# db = SQLAlchemy(app)
# SQLALCHEMY_TRACK_MODIFICATIONS = False

# ---------第一部分：定义表-----------
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
#----------第三部分：进行数据操作--------
if __name__ == '__main__':
    #提交新数据
    session.add(Enhancer(chr="例子",start=200,end=400))#只能加一条数据
    session.add_all([Enhancer(chr="例子12",start=200,end=400),Enhancer(chr="例子12",start=200,end=400)])
    # 使用add_all可以一次传入多条数据，以列表的形式。
    session.commit()#提交数据
