#!/usr/bin/env python
# aptinstall.py

import apt
import sys
import yaml
from tqdm import tqdm


def get_config():
    with open('config.yaml', 'r') as file:
        app_config = yaml.safe_load(file)
    return app_config

def open_apt():
    cache = apt.cache.Cache()
    cache.update()
    cache.open()

def install_apt_pkg(pkg_name):
    pkg = cache[pkg_name]
    if pkg.is_installed:
        print ("{pkg_name} already installed".format(pkg_name=pkg_name))
    else:
        pkg.mark_install()

        try:
           cache.commit()
        except Exception as arg:
            print() >> sys.stderr, "Sorry, package installation failed [{err}]".format(err=str(arg))


def main():
    app_config = get_config()
    packages = app_config['packages']
    for package in packages:
        print("going to install:" + package)
    

if __name__ == "__main__":
    sys.exit(main())
