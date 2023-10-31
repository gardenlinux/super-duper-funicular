#!/usr/bin/python3

# This script needs to be run from the `debian/copyright-generator` directory.

# This is an initial version of a script that generates the copyrights file
# for the openjdk-XX packages. A lot of information is still hard-coded,
# which means the script needs to be improved.
#
# For instance, it must be possible to parse all the copyright headers from
# all the source files and deduce a list of "Upstream Authors". It must
# also be possible to deduce the smallest yet complete list of copyrights.
# For now, we have these hard-coded in the "copyright-gen/upstream-authors"
# and "copyright-gen/copyrights" file.
#
# Licenses from the legal directories of different modules are gathered and
# dumped under the License field of the first File stanza.
# The debian build does not build native libraries like zlib, pcsclite, giflib
# libpng and libjpeg. These are excluded. There's scope for improvement here too.
# The script must be able to look into "debian/rules" and deduce these exclusions.

import os
import sys

version = "";
packaged_by = "Matthias Klose <doko\@ubuntu.com>";
common_licenses = {};

## TODO: Can the script deduce this list?
excluded_files = [
  ".github/*",
  ".gitattributes",
  "src/java.base/share/native/libzip/zlib/*",
  "src/java.desktop/share/native/libsplashscreen/giflib/*",
  "src/java.desktop/share/native/libsplashscreen/libpng/*",
  "src/java.smartcardio/unix/native/libj2pcsc/MUSCLE/*",
  "src/java.desktop/share/native/libjavajpeg/jc*",
  "src/java.desktop/share/native/libjavajpeg/jd*",
  "src/java.desktop/share/native/libjavajpeg/je*",
  "src/java.desktop/share/native/libjavajpeg/jf*",
  "src/java.desktop/share/native/libjavajpeg/ji*.c",
  "src/java.desktop/share/native/libjavajpeg/jm*",
  "src/java.desktop/share/native/libjavajpeg/jpegi*",
  "src/java.desktop/share/native/libjavajpeg/jpeglib.h",
  "src/java.desktop/share/native/libjavajpeg/jq*",
  "src/java.desktop/share/native/libjavajpeg/jv*",
  "src/java.desktop/share/native/libjavajpeg/ju*",
  "src/java.desktop/share/native/libjavajpeg/README"
]

## TODO: Can the script deduce this list?
openjdk_copyrights = [
  "Copyright (c) 1996-2023 Oracle and/or its affiliates.",
  "Copyright (c) 1996-2003 Sun Microsystems, Inc.",
  "Copyright (c) 2009-2012 Red Hat, Inc.",
  "Copyright (c) 2012-2022 SAP SE.",
  "Copyright (c) 2020-2021 Azul Systems, Inc.",
  "Copyright (c) 1999-2022 The Apache Software Foundation.",
  "Copyright (c) 2020-2021 Microsoft Corporation",
  "Copyright (c) 2009-2022 Google LLC",
  "Copyright (c) 2020-2021 Amazon.com, Inc",
  "Copyright (c) 2021 Alibaba Group Holding Limited",
  "Copyright (c) 2019-2021 Huawei Technologies Co. Ltd.",
  "Copyright (c) 2021-2023 BELLSOFT",
  "Copyright (c) 2022-23 THL A29 Limited, a Tencent company.",
  "Copyright (c) 2021-2023, Arm Limited.",
  "Copyright (C) 2014-2017 by Vitaly Puzrin and Andrei Tuputcyn.",
  "Copyright (c) 2017 Instituto de Pesquisas Eldorado.",
  "Copyright (c) 1999-2007  Brian Paul.",
  "Copyright (c) 2018-2019 Adobe Inc.",
  "Copyright 2006-2014 Adobe Systems Incorporated.",
  "Copyright 1994-2011  Hewlett-Packard Co.",
  "Portions Copyright (c) 2011-2014 IBM Corporation",
  "Portions Copyright (c) 1995  Colin Plumb",
  "Portions Copyright (c) 1997-2003 Eastman Kodak Company",
  "See other third party notices under the License section"
]

## TODO: Can the script deduce this list?
upstream_authors = [ 
  "Oracle and/or its affiliates",
  "Sun Microsystems, Inc",
  "Red Hat, Inc",
  "SAP SE",
  "Azul Systems, Inc",
  "Apache Software Foundation",
  "Microsoft Corporation",
  "Intel Corportation",
  "IBM Corporation",
  "Google LLC",
  "Amazon.com, Inc",
  "Other contributors",
  "See the third party licenses below."
]

exclude_licenses = ["zlib.md", "pcsclite.md", "giflib.md", "libpng.md", "jpeg.md"]

def print_field(name, single_line, value):
  print(name + ": ", end="")
  if (single_line):
    print(value)
  else:
    print("\n" + value)

def print_header_stanza(format, files_excluded, source, comment):
  print_field("Format", True, format)
  print_field("Files-Excluded", False, files_excluded)
  print_field("Source", True, source)
  print_field("Comment", True, comment)
  print() # an empty line

def print_file_stanza(files, copyrights, license, comments):
  print_field("Files", True, files)
  print_field("Copyrights", False, copyrights)
  print_field("License", True, license) 
  if (comments is not None and len(comments) != 0):
    print_field("Comments", True, comments)
  print() # an empty line

def generate_excluded_files_str():
  return "  " + "\n  ".join(excluded_files)

def generate_comment_str():
  upstream_authors_str = "\n      ".join(upstream_authors)
  return f"""
  Upstream Authors:
    OpenJDK:
      {upstream_authors_str}
    Packaged by:
      {packaged_by}"""
    
def generate_header_stanza():
  format = "https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
  excluded = generate_excluded_files_str()
  source = "https://github.com/openjdk/jdk"
  comment = generate_comment_str()
  print_header_stanza(format, excluded, source, comment)

def get_content(path):
  lines = []
  with open(path, 'r') as file:
    for line in file:
      lines.append(line
        .replace("### ","")
        .replace("```", "")
        .replace("<pre>", "")
        .replace("</pre>", ""))

  return lines[0], "".join(lines[1:])
  

def fill_with_dots(text):
  lines = text.split("\n")
  out = []
  for line in lines:
    if line.strip() == "":
      line = "."
    out.append(line)
  return "\n".join(out)

def gen_comment(component):
    return f"""%% This notice is provided with respect to {component},
which may be included with JRE {version}, JDK {version} and OpenJDK {version}"""

def gen_license_text(license):
  component, content = get_content(license)
  component = component.split("## ")[1].rstrip("\n");
  return f"""
{gen_comment(component)}

--- begin of LICENSE ---
{content}
--- end of LICENSE ---

------------------------------------------------------------------------------"""

    
def get_legal_dirs(path):
  legal_dirs = []
  for root, dirs, files in os.walk(path):
    if "legal" in dirs and (root.endswith("share") or root.endswith("unix")):
      legal_dirs.append(os.path.join(root, "legal"))
  return legal_dirs

def gather_licenses(module):
  legal_dirs = get_legal_dirs(module)
  licenses_text = ""
  for dir in legal_dirs:
    licenses = os.scandir(dir)
    for license in licenses:
      if not license.name in exclude_licenses:
        licenses_text += gen_license_text(license.path)
  return licenses_text

def gather_modules_licenses(srcdir):
  licenses = ""
  modules = os.scandir(srcdir)
  for module in modules:
    licenses += gather_licenses(module)
  return licenses

def find_directory(prefix):
  for file in os.scandir():
    if file.is_dir() and file.name.startswith(prefix):
      return file.path
      
def generate_copyright():
  os.system(f"pull-debian-source openjdk-{version} > /dev/null 2>&1")
  rootdir = find_directory(f"openjdk-{version}")
  srcdir = f"{rootdir}/src"; 

  os.system(f"/bin/sh strip-common-licenses.sh {rootdir} {version}")
  generate_header_stanza();

  licenses = f""" GPL with Classpath exception

--- begin of LICENSE ---

{open(rootdir + "/LICENSE").read()}
--- end of LICENSE ---

------------------------------------------------------------------------------
The following licenses for third party code are taken from 'legal' \ndirectories of modules under src/
------------------------------------------------------------------------------
{gather_modules_licenses(srcdir)}"""

  print_file_stanza("*", " \n".join(openjdk_copyrights), fill_with_dots(licenses), "")
  if (version != "11"):
    print(open("bundled-stanzas").read())
  print(open("debian-stanzas").read())

  # clean-up
  os.system(f"rm -rf {rootdir} *.debian.tar.xz *.orig.tar.xz *.dsc *googletest.tar.xz");
    

def main():
  global version

  if (len(sys.argv) >= 1):
    version = sys.argv[1]

  if version == "" or version == "--help" or version == "-help" or version == "help":
    print("Usage:\ncopyright-gen.py <version> > ../copyright")
    print("version - 11 | 17 | 21 | 22")
    print("Note: this script must be run from the `debian/copyright-generator` directory")
  elif version == "11" or version == "17" or version == "21" or version == "22":
    generate_copyright()
  else:
    print("Version not supported.")

if __name__ == "__main__":
  main()    
