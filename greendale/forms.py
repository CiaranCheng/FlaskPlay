from flask_wtf import FlaskForm
from wtforms import SubmitField,StringField,PasswordField,BooleanField
from wtforms.validators import DataRequired

# flask_wtf是flask的表单验证模块，实际上，很多Flask的模块都是通过flask_<name>的形式导入的
# 这里的校验器只引入了DataRequired 这个是用来校验字段必填的,以后还会用到更多的校验器

# 创建类的时候这里的这个FlaskForm参数
class LoginForm(FlaskForm):
    username = StringField('Username',validators=[DataRequired()])
    password = PasswordField('Password',validators=[DataRequired()])
    remember_me = BooleanField('Remember Me')
    submit = SubmitField('Sign In')



# 关于WTForms:
# WTForms is a flexible forms validation and rendering library for Python web development. 
# It can work with whatever web framework and template engine you choose. 
# It supports data validation, CSRF protection, internationalization (I18N), and more. 
# There are various community libraries that provide closer integration with popular frameworks.
# 关于Flask_wtf：
# http://www.pythondoc.com/flask-wtf/




