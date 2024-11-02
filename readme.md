# One2N Hiring Assignment - Ravi Rana

- Write an http service in any programming language, which should expose an endpoint
- Write a Terraform layout to provision infrastructure on AWS and deploy the above code.

## Application Details and Assumptions Made

### TechStack

- Language Used: Python  
- Framework: Flask
- Web Server: Nginx

### About the Application

The application in written in python using flask for the sake of simplicity.  
The application is hosted over an ec2 instance which is publicaly available on port 80.

### About the deployment

The application is written with flask framework which is being served by the gunicorn WSGI, implemented as a Linux service, which binds a linux socket for the server.  
The application is served by nginx web server over port 80.

### Steps to run the application

#### For Local Development
For local development, pull the code from the git repository (which is publicaly available)  
Make sure the following dependencies are met:  
 
 - Python > 3.9
 - pip3
 - AWS CLI
 
To install python and pip in a linux based system, you can use the package manager, I have used Amazon Linux 2 for the development on which you can run:  
`sudo yum install python3`  
`sudo yum install python3-pip`

#### Important
Comfigure appropriate profile in your `~/.aws/credentials` file, this application uses default profile to authenticate with AWS, you can configure it using:  
`aws configure --profile default`  
Enter the relevant details like AWS Access Key Id, Value and optionally default region and output format.  
Note: If you want to use another profile instead of the deafult one, modify profile name in line 6 of `app/server.py`:  
`my_session = boto3.session.Session(profile_name='<YOURPROFILENAME>')`

It is recommended to create a virtual environment to run the code, to create a virtual environment, run the below commands:  
`python3 -m venv env`  
`source env/bin/activate`

To install all these dependencies run the below command:  
`pip3 install -r requirements.txt`

To run the flask server locally use the following command:  
`flask --app one2n-assignment-ravi/app/server.py run`

Note: Append the appropriate path

The webserver will be accessible to you on the below URL:
`http://127.0.0.1:5000`  

##### Setting up Gunicorn WSGI
To setup gunicorn WSGI, run the following command:  
`gunicorn --bind 0.0.0.0:5000 wsgi:app`

#### For Production
To run the application in production (EC2 Instance), follow the below steps:

Install the dependencies and prepare the environment as mentioned above.  

Attach an IAM role to the EC2 instance which have necessary permissions to access the objects of the s3 bucket.
Add the appropraite profile to the `~/.aws/credentials` file, we will be using the credentials from the instance metadata to authenticate with AWS.
Modify the credentials file as follows:  
`vi ~/.aws/credentials`  

Paste the following content:  
```
[profile default]
role_arn = arn:aws:iam::123456789012:role/rolename
credential_source = Ec2InstanceMetadata
region = region
```

Install nginx, it can be done using the package manager for your linux distribution:  
`sudo yum install nginx`  

Start and enable the service to run at boot:  
`sudo systemctl start nginx`  
`sudo systemctl enable nginx`

Create service for your application: You can use the `s3flask.service` file as a template to create a systemd service for your application, change the `WorkingDirectory`, `Environment` and `ExecStart` values with the relevant paths for your environment.  

Create the file with the appropriate name, like `s3server.service` and copy the file to `/etc/systemd/system/`  
`cp s3server.service /etc/systemd/system/s3server.service`  

Now, start and enable the service (so that it can run at boot):  
`sudo systemctl start s3server`  
`sudo systemctl enable s3server`

After the service is successfully created and started, it uses linux sockets for efficient communication with the nginx server, now we will configure the nginx server to access the web server.  

Create a new nginx configuration file in the `/etc/nginx/conf.d` directory, let's name it `s3server.conf`, you can use the configuration template from `nginx-conf.conf` file just append the appropriate path in the `proxy_path`:  
`cp nginx-conf.conf /etc/nginx/conf.d/s3server.conf`

Check the validity of the configuration using the following command:  
`sudo nginx -t`

If the configuration is successfully validated, restart the nginx server:  
`sudo systemctl restart nginx`

Your application will be available at:  
`http://{YOUR_IP_ADDRESS}`

### Assumptions Made
#### Security
In order to secure the contents of the S3 buckets to be accessible only by the S3 bucket, I am using EC2 instance profile, i.e. an IAM role attached to the EC2 instance which only have the required least privilged permissions.
#### Pagination
As we are using AWS API for getting the objects, the output is paginated to list maximum of 100 objects in an API call, to mitigate this I am using paginator to list all available objects in a single call.
#### Authentication with AWS
For authenticating with AWS, I am using EC2InstanceMetadata to get credentials from the IAM role attached to avoid harcoded credentials.
#### Deployment
I have created a golden AMI with the desired configuration and I am using that to provision the EC2 instance using terraform.
S3 bucket is not managed by terraform, as it I needed to configure the application code which contains the name of the s3 bucket. 