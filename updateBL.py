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
	# download(http://squidguard.mesd.k12.or.us/blacklists.tgz)

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
	# levo i dupplicati
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
	configFile.writelines("dbhome /usr/local/squidGuard/db\n")
	configFile.writelines("logdir /usr/local/squidGuard/logs\n")
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
					configFile.writelines("!"+ c[:len(c)-1] + " ")
	configFile.writelines("all\n")
	configFile.writelines("\t\tredirect http://localhost/block.html\n")
	configFile.writelines("\t}\n}\n")
	configFile.close()













