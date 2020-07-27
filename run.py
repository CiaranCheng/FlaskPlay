from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
   return 'Hello XBB'
@app.route('/index')
def hello_world():
   return 'Hello XBB'

# 注意这里，app.run默认的主机是127.0.0.1,是不能被外部访问的
if __name__ == '__main__':
   app.run(host='0.0.0.0', port=5000)