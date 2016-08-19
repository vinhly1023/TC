This document is to setup MySQL for Test Central.

# Setup of MySQL Labs 5.7.12 w/ JSON support using docker Virtual-Box container

###I. Snapshot Database
From Windows CMD

    cd C:
    cd \dev\sqaauto-testcentral
    rake db:snapshot

###II. Shutdown local MySQL server
1. Stop any local MySQL container
2. From Windows CMD, expose MySQL to localhost - verify no other listners on MySQL port 3306

        netstat -a -n | findstr 3306

###III. Setup MySQL Labs 5.7.12 on Windows [reference]( http://mysqlserverteam.com/getting-started-with-mysql-json-on-windows)
1. Download and install docker for Windows
2. Run "Docker Quickstart Terminal" from Windows Start Menu
3. From Docker window, install and run mysql container (replace [PASSWORD] with root mysql password)

        docker run --restart=on-failure:5 -p 3306:3306 --name ml -e MYSQL_ROOT_PASSWORD=[PASSWORD] -d mysql:5.7.12

4. From Docker window, test connection (replace [PASSWORD] with root mysql password)

        docker exec -it ml bash
        mysql -p
        [PASSWORD]
        exit
        exit

5. Configure Docker VM network setting from Open VirtualBox UI => Settings\Network\Port Forwarding
  add rule using the following

        | Name | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
        -------------------------------------------------------------------
        |MySQL | TCP      | 127.0.0.1 | 3306      |           | 3306      |

6. Shutdown Docker VM from VirtualBox UI => Close\ACPI Shutdown


###IV. Starting Docker MySQL container
1. Stop any local MySQL container
2. Run "Docker Quickstart Terminal"
3. From Docker window, start the 'ml' mysql container

        docker start ml

4. From Docker window, verify 'ml' is running

        docker ps

###V. Migrate Database
From Windows CMD

        cd C:
        cd \dev\sqaauto-testcentral
        bundle install
        rake db:create
        rake db:restore
        rake db:migrate

###VI. Done!
Now you have:

1. A running Docker container of MySQL with JSON
2. Test Central db migrated to the Docker MySQL server

### Notes
Before starting the Docker Virtual-Box container, you need to have your local MySQL server off so that network port goes to Docker.

# Add another MySQL docker container container to an existing docker host
Use a different external port and the same IP:

1. Shutdown the Docker VM in VirtualBox
2. Add the new port number (Ex. 3308) to the network config
3. Start Docker (Windows Firewall should prompt, select okay)
4. Start the existing docker containers (i.e. your original MySQL container)
5. Create a new MySQL docker container with the new port mapped to the default MySQL port (Ex. -p 3308:3306)

        docker run --restart=on-failure:5 -p 3308:3306 --name ml-[NEW_NAME] -e MYSQL_ROOT_PASSWORD=[PASSWORD] -d mysql:5.7.12

6. For your TC server set the System Environment variables

        setx RAILS_DB_HOST=[IP here]
        setx RAILS_DB_PORT=3308

7. Start your TC server

# Make MySQL container available for remote access
1. Shutdown the Docker VM in VirtualBox
2. Open the network config and then update the instance's Host IP to 0.0.0.0
3. Start the Docker VM

# Migrate Boot2Docker to DockerToolbox
Since we have used Boot2Docker to deploy MySQL container, please following steps to install DockerToolbox 1.11.0

1. Download [DockerToolbox v1.11.0](https://github.com/docker/toolbox/releases)
2. Backup database(s) by using MySQL Workbench or rake db:snapshot as above snapshot database section
3. Uninstall Boot2Docker... and Oracle VM VirtualBox programs
4. Go to user home folder (Win + R, type %HOMEPATH% or C:\Users\), delete .docker and .VitualBox folders
5. Install DockerToolbox-1.11.0.exe by flowing the Docker Toolbox Setup steps

  `Note: On the Select Components, please uncheck Kitematic for Windows (Alpha) and Git for Windows`

6. Follow "Setup of MySQL Labs 5.7.12 w/ JSON support using docker Virtual-Box container" section above to install MySQL Labs 5.7.12, please ignore unnecessary steps.
7. Follow "Enabling cache on Docker MYSQL instance.docx" to enable MySQL cache