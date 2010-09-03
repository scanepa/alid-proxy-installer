#!/usr/bin/env python

"""File downloading from the web.
"""

def download(url):
    """Copy the contents of a file from a given URL
    to a local file.
    """
    import urllib
    webFile = urllib.urlopen(url)
    localFile = open(url.split('/')[-1], 'w')
    localFile.write(webFile.read())
    webFile.close()
    localFile.close()

if __name__ == '__main__':
    download("http://www.shallalist.de/Downloads/shallalist.tar.gz")

    import tarfile
    compressedFile = tarfile.open('shallalist.tar.gz')
    fileList = []
    fileList = compressedFile.getnames()
    compressedFile.extractall()
    # elimino i file non necessari
    fileList.remove("BL/COPYRIGHT")
    fileList.remove("BL/global_usage")
    # creo una lista con i nomi ripuliti di / finali e BL/ all'inizio'
    clienList = []
    for name in fileList:
        clienList.append(name[3:])
    # cerco i nomi di directory con sottodirectory
    clienList.sort()
    daCancellare = []
    for c in clienList:
        if c.endswith("/"):
            if c[:len(c)-1].find("/"):
                if c[:len(c)-1].split("/")[1:] != []:
                    daCancellare.append("".join(c.split("/")[0:1]))
    # remove double values
    ldc = list(set(daCancellare))
    ldc.sort()
    # cancello i nomi delle directory con sotto directory
    for i in ldc:
        if clienList.count(i+"/") >= 1:
            clienList.remove(i+"/")
    configFile = open("squidGuard.conf", "w")
    configFile.writelines("#\n")
    configFile.writelines("# CONFIG FILE FOR SQUIDGUARD CREATED BY AUTOMATIC SCRIPT\n")
    configFile.writelines("#\n")
    configFile.writelines("dbhome /var/lib/squidguard/db\n")
    configFile.writelines("logdir /var/log/squid3\n")
    for c in clienList:
        if c.endswith('/'):
            configFile.writelines("dest " + c[:len(c)-1].replace("/","_") + " {\n")
        if c.endswith("domains"):
            configFile.writelines("\tdomainlist " + c + "\n")
        if c.endswith("urls"):
            configFile.writelines("\turllist " + c + "\n }\n")
    configFile.writelines("acl {\n")
    configFile.writelines("\tdefault {\n")
    configFile.writelines("\t\tpass ")
    for c in clienList:
        if c.endswith('/'):
            #configFile.writelines("!"+ c[:len(c)-1] + " ")
            configFile.writelines("!" + c[:len(c)-1].replace("/","_") + " ")
    configFile.writelines("all\n")
    configFile.writelines("\t\tredirect http://localhost/block.html\n")
    configFile.writelines("\t}\n}\n")
    configFile.close()

    import shutil
    # backup old configfile
    shutil.move("/etc/squid/squidGuard.conf","/etc/squid/squidGuard.conf.orig")
    # moving newly created file to destination
    shutil.move("squidGuard.conf","/etc/squid/squidGuard.conf")
    # moving urls and domains files
    import os
    os.system("rm -rf /var/lib/squidguard/db/")
    os.system("mkdir -p /var/lib/squidguard/db")
    os.system("mv BL/* /var/lib/squidguard/db/" )
    os.system("squidGuard -C all")
    os.system("chown -R proxy.proxy /var/lib/squidguard/db/* ")
    os.system("sudo /etc/init.d/squid3 restart")
