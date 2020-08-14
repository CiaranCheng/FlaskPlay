from flask import Flask
app = Flask(__name__)
from greendale import routes

# 需要注意的有以下几点
# routes需要在最下方引用和导入 这是为了解决 循环导入的问题
# 