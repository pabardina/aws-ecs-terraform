import os

from flask import Flask, render_template


app_env = os.getenv('APP_ENV')

app = Flask(__name__)

@app.route('/')
def hello_world():
    return render_template('index.html', app_env=app_env)


if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0')