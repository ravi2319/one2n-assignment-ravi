import boto3.session
from flask import Flask, abort
import boto3
import sys

my_session = boto3.session.Session(profile_name='default')
client = my_session.client('s3')
paginator = client.get_paginator('list_objects_v2')
app = Flask(__name__)

@app.route("/", methods = ['GET'])
def main_path():
    return "<h1>Hit list-bucket-content to list the bucket content<h1>"

@app.route("/list-bucket-content/", methods = ['GET'])
@app.route("/list-bucket-content/<path:subpath>", methods = ['GET'])
def base(subpath=''):
    if subpath and not subpath.endswith('/'):
        subpath += '/'
        
    request = paginator.paginate(
        Bucket = 'one2n-assignment-ravi-1',
        Prefix = subpath,
        Delimiter = '/',
    )
    
    result_list = []
    for page in request:
        if page['KeyCount'] == 0:
            abort(404)
        if page.get("Contents") is not None:
            for prefix in page.get("Contents"):
                key = prefix.get("Key").removeprefix(subpath)
                if key == "":
                    continue
                result_list.append(key)
                
        if page.get("CommonPrefixes") is not None:
            for prefix in page.get("CommonPrefixes"):
                test = prefix.get("Prefix").removeprefix(subpath)
                result_list.append(test)

    result = {}
    result['content'] = result_list
    return result

@app.errorhandler(404)
def handle_404(error):
    err = {
        "message": "Page Not Found, the requested directory does no exist!"
    }
    return err, 404

@app.errorhandler(500)
def handle_500(error):
    err = {
        "message": "Internal Server Error"
    }
    return err, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)