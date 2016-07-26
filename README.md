# portal-build-tool

### What does this script do exactly?

1. Asks if you want to reset branch and pull upstream
2. Adds necessary property files to your repo
3. Builds portal
4. Cleans your mysql database
5. *Optionally*, starts portal after building (Tomcat Only)

Branches currently supported
```
master
7.0.x
ee-7.0.x
ee-6.2.x
```


### Setup

1. Clone portal-build-tool from https://github.com/vicnate5/portal-build-tool
2. Edit the different property files in the */properties* folder.

  These property files are the baseline for the properties that will be added to your repo by the script. Allows you to have a central and safe location for your source properties. Stop fearing the `git clean -fdx`!

3. Open build.sh
4. Edit Environment Variables (mysql login, mysql databases, and portal directories)
5. Save your changes to the script file


### How to Use

1. Open bash terminal (Use GitBash for Windows)
2. Run ``./build.sh {branch} [{app server}] [start]``

###### e.g.
```
./build.sh master tomcat start
./build.sh ee-7.0.x wildfly
./build.sh ee-6.2.x
```

Note: Only {branch} is required. The app server default is Tomcat. And `start` will start the portal automatically after the build is complete. But the command only works on Tomcat
