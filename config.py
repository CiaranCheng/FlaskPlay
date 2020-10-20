import os

class Config :
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'anniesb'


    # 通过类来定义系统参数

    # os.environ 是从哪里获取的？


    # 有了这样一个配置文件之后，我们还需要在生成Flask应用之后去使用它