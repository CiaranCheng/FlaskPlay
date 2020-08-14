from greendale import app

@app.route('/')

@app.route('/index')
def index():
    return "Greendale is where I belong"
