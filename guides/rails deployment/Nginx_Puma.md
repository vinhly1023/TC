# Deploy Test Central with nginx and puma

## I. Nginx configuration

  **1. Ubuntu**

  Install nginx

    apt-get update
    apt-get install nginx

  Remove default site

    sudo rm /etc/nginx/sites-enabled/default

  Create new virtual host config file

    sudo nano /etc/nginx/sites-available/test_central

  `/etc/nginx/sites-available/test_central` content

    upstream puma {
    server unix:///tmp/puma.sock;
    }
    server {
        # SSL configuration
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl on;
        ssl_certificate     /home/test/Desktop/puma/sqaauto_testcentral/ssl/server.crt; # Change this path to your correct sqaauto_testcentral folder
        ssl_certificate_key /home/test/Desktop/puma/sqaauto_testcentral/ssl/server.key; # Change this path to your correct sqaauto_testcentral folder
        root /home/test/Desktop/puma/sqaauto_testcentral/public; # Change this path to your correct sqaauto_testcentral folder
        server_name testcentral;
        client_max_body_size 110M;
		underscores_in_headers on;
      location / {
        proxy_pass http://puma;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 600;
      }
    }

  Next, we enable this configuration by creating a symlink in **/etc/nginx/site-enabled**

    sudo ln -s /etc/nginx/sites-available/test_central /etc/nginx/sites-enabled/

  Then restart nginx server to apply these changes

    sudo service nginx restart

  **2. Windows**

  Download [latest Nginx Stable version](http://nginx.org/en/download.html) for Windows

  Extract nginx*.zip and edit conf/nginx.conf as below

    worker_processes  1;

    error_log  logs/error.log;
    error_log  logs/error.log  notice;
    error_log  logs/error.log  info;

    pid        logs/nginx.pid;

    events {
        worker_connections  1024;
    }

    http {
      upstream puma {
        server 127.0.0.1:9292;
      }
      include       mime.types;
      default_type  application/octet-stream;
      sendfile        on;
      keepalive_timeout  65;
      server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl on;
        ssl_certificate      path\to\ssl\server.crt; # Change this path to your correct sqaauto_testcentral folder
        ssl_certificate_key  path\to\ssl\server.key; # Change this to your correct sqaauto_testcentral folder
        root path\to\public; # Change this path to your correct sqaauto_testcentral folder
        server_name testcentral;
        client_max_body_size 110M;
        underscores_in_headers on;
        location / {
          proxy_pass http://puma; # match the name of upstream directive which is defined in line 1
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_read_timeout 600;
        }
      }
    }

## II. Puma configuration.

  Add gem `puma` to the Gemfile of your Rails application.

    gem 'puma', '2.15.3'

  Go to `sqaauto_testcentral` folder

  Create `config/puma.rb` with following content

    #!/usr/bin/env puma
    rails_env = ENV['RAILS_ENV'] || 'production'
    environment rails_env
    daemonize false
    pidfile 'tmp/puma.pid'
    threads 0, 16
    # For Ubuntu
    bind 'unix:///tmp/puma.sock'

  Start puma

    puma

## III. Run

  **1. Ubuntu**

  Restart nginx

    sudo service nginx restart

  **2. Windows**

  Open cmd, go to nginx extracted folder and type

    start nginx

  Go to [test central](https://localhost) and enjoy!

## Reference

[nginx for Windows](http://nginx.org/en/docs/windows.html)

Nginx on Windows runs as a standard console application (not a service), and it can be managed using the following commands:

`nginx -s stop`	fast shutdown

`nginx -s quit`	graceful shutdown

`nginx -s reload`	changing configuration, starting new worker processes with a new configuration, graceful shutdown of old worker processes

`nginx -s reopen`	re-opening log files
