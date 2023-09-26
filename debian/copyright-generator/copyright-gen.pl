#!/usr/bin/perl

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


use experimental 'smartmatch';

$version = "";
$packaged_by = "Matthias Klose <doko\@ubuntu.com>";

## TODO: Can the script deduce this list?
@excluded_files = (
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
);

## TODO: Can the script deduce this list?
@openjdk_copyrights = (
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
);

## TODO: Can the script deduce this list?
@upstream_authors = (
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
  "Other contributors".
  "See the third party licenses below."
);

@exclude_licenses = ("zlib.md", "pcsclite.md", "giflib.md", "libpng.md", "jpeg.md");

sub print_field {
    $name = $_[0];
    $single_line = $_[1];
    $value = $_[2];

    print "$name:";
    if ($single_line) {
        print " $value\n";
    } else {
        print "\n$value\n"
    }
}

sub print_header_stanza {
    # 0 - format;
    # 1 - files_excluded
    # 4 - source
    # 6 - comment

    print_field("Format", 1, $_[0]);
    print_field("Files-Excluded", 1, $_[1]);
    print_field("Source", 1, $_[2]);
    print_field("Comment", 0, $_[3]);
}

sub print_file_stanza {
   # 0 - Files
   # 1 - Copyrights
   # 2 - License
   # 3 - Comments

   print_field("Files", 1, $_[0]);
   print_field("Copyrights", 0, $_[1]);
   print_field("License", 1, $_[2]);
   if ($_[3]) {
       print_field("Comments", 1, $_[3]);
   }
}

sub generate_excluded_files_str() {
   $excluded_files = "";
   foreach(@excluded_files) { 
     $excluded_files = $excluded_files."\n  $_";
   }
   return $excluded_files;
}

sub generate_comment_str() {
    $comment = "  Upstream Authors: \n";
    $comment = $comment."    OpenJDK: \n";
    foreach(@upstream_authors) {
        $comment = $comment."      $_\n";
    }
    $comment = $comment."  Packaged by:\n";
    $comment = $comment."    $packaged_by\n";
    return $comment; 
}

sub generate_header_stanza {
    $format = "https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/";
    $excluded = generate_excluded_files_str();
    $source = "https://github.com/openjdk/jdk";
    $comment = generate_comment_str();
    print_header_stanza($format, $excluded, $source, $comment);
    
}

my $rootdir = "";
my $srcdir  = "";

sub get_content {
    $path = $_[0];
    $len = `expr \`wc -l $path | cut -d' ' -f1\` - 1`;
    return `cat $path | tail -$len`;
}

sub gen_comment {
    @words = split(' ', $_[0]); 
    $comment = "%% This notice is provided with respect to @words[1],\nwhich may be included with JRE $version, JDK $version and OpenJDK $version\n";
    return $comment;
}

sub gather_licenses {
    my $module = $_[0];
    my $licenses = $_[1];

    my $module_dir = $srcdir."/".$module;
    my @legal_dirs = split(' ', `find $module_dir -name legal | xargs`);

    foreach (@legal_dirs) {
        my $legal_dir = $_;
        my @license_files = split(' ', `ls $_ | xargs`);
        foreach(@license_files) {
            if ($_ ~~ @exclude_licenses) {
                next;
            }
            $path = $legal_dir."/".$_;
            $component_name = `head -1 $path`;
            $licenses = $licenses.gen_comment($component_name);
            $licenses = $licenses."\n--- begin of LICENSE ---\n";
            $licenses = $licenses.get_content($path);
            $licenses = $licenses."--- end of LICENSE ---\n";
            $licenses = $licenses."\n------------------------------------------------------------------------------\n\n";

        }
    }

    # Remove some of the known markdown tags
    $licenses =~ s/<pre>//g;
    $licenses =~ s/<\/pre>//g;
    $licenses =~ s/### //g;
    $licenses =~ s/\`\`\`//g;

    return $licenses;
}

sub generate_copyright {
    system("pull-debian-source openjdk-$_[0] > /dev/null 2>&1");
    $rootdir = `ls -d openjdk-$_[0]*/`;
    chomp($rootdir);  
    $srcdir = $rootdir."/src";

    generate_header_stanza();

    my $licenses = "";
    my $copyrights = "";

    foreach(@openjdk_copyrights) {
        $copyrights = $copyrights."  $_\n";
    }

    $licenses = $licenses."GPL with Classpath exception\n";
    $licenses = $licenses."\n--- begin of LICENSE ---\n\n";
    $licenses = $licenses.`cat $rootdir/LICENSE`;
    $licenses = $licenses."\n--- end of LICENSE ---\n";
    $licenses = $licenses."\n------------------------------------------------------------------------------\n\n";
    $licenses = $licenses."The following licenses for third party code are taken from 'legal` directories \n of modules under src/\n";
    $licenses = $licenses."\n------------------------------------------------------------------------------\n\n";

    my @modules = split(' ', `ls $srcdir | xargs`);
    foreach (@modules) {
        $licenses = gather_licenses($_, $licenses); 
    }

    print_file_stanza("*", $copyrights, $licenses);
    print `cat debian-stanzas`
    
}

$version = $ARGV[0];

if ($#ARGV == -1 || $version == "--help" || $version == "-help" || $version == "help") {
    print "Usage:\ncopyright-gen.pl <version> | sed 's\/^\\s\*\$\/.\/' > copyright\n";
    print "version - 11 | 17 | 21 | 22\n";
} elsif ($version == "11" || $version == "17" || $version == "21" || $version == "22") {
    generate_copyright($version);
} else {
   print "Version not supported.\n";
}
