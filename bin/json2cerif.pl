#!/usr/bin/env perl
#
# Biblio CERIF exporter
#
# Patrick Hochstenbach @ ugent dot be
# Nicolas Steenlant @ ugent dot be
# 2012-05-29
#
use Catmandu;
use IO::File;
use File::Temp;
use Getopt::Long;
use POSIX qw(strftime);
use File::Spec::Functions qw(catdir);
use File::Basename qw(dirname);
use Cwd qw(realpath);

my $proj_dir = realpath(catdir(dirname(__FILE__), '..'));

GetOptions("d=s"=> \$proj_dir);

my $infile = shift;
my $outfile = shift || "CERIF.zip";

die usage() unless -r $infile;

die usage()."\nproject_directory '$proj_dir' not found" unless -d $proj_dir;

my $temp = File::Temp->newdir;

cerif_process($temp . '/cfResPubl-RES.xml','cfResPubl.tt');
cerif_process($temp . '/cfResPublTitle-LANG.xml','cfResPublTitle.tt');
cerif_process($temp . '/cfResPublSubtitle-LANG.xml','cfResPublSubtitle.tt');
cerif_process($temp . '/cfResPublAbstr-LANG.xml','cfResPublAbstr.tt');
cerif_process($temp . '/cfResPublKeyw-LANG.xml','cfResPublKeyw.tt');
cerif_process($temp . '/cfPers_ResPubl-LINK.xml','cfPers_ResPubl.tt');
cerif_process($temp . '/cfPers-CORE.xml','cfPers.tt');
cerif_process($temp . '/cfPersName-ADD.xml','cfPersName.tt');
cerif_process($temp . '/cfOrgUnit-CORE.xml','cfOrgUnit.tt');
cerif_process($temp . '/cfOrgName-LANG.xml','cfOrgUnitName.tt');
cerif_process($temp . '/cfPers_OrgUnit-LINK.xml','cfPers_OrgUnit.tt');

unlink $outfile;
system("zip -q -j -r $outfile $temp/*.xml");

sub cerif_open {
    my ($name) = @_;

    print STDERR "Creating $name...\n";
    my $fh     = IO::File->new;
    $fh->open("> $name");

    my $source = 'biblio.ugent.be';
    my $date = strftime "%Y-%m-%d" , localtime time;
    $fh->print(<<EOF);
<?xml version="1.0" encoding="UTF-8"?>
<CERIF
 xsi:schemaLocation="urn:xmlns:org:eurocris:cerif-1.4-0 http://www.eurocris.org/Uploads/Web%20pages/CERIF-1.4/CERIF_1.4_0.xsd"
 xmlns="urn:xmlns:org:eurocris:cerif-1.4-0"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 release="2008-1.4"
 date="$date"
 sourceDatabase="$source"
>
EOF
    return $fh;
}

sub cerif_process {
    my ($output,$template) = @_;

    my $fh = cerif_open($output);

    my $memory = {};
    Catmandu->exporter('Template', file => $fh , template => "$proj_dir/templates/$template")
            ->add_many(Catmandu->importer('JSON', file => $infile)->tap(sub {
            my $obj = $_[0];
            $obj->{memory} = $memory;
            $obj->{id} = $obj->{_id};
            }));

    cerif_close($fh);
}

sub cerif_close {
    my ($fh) = @_;
    $fh->print(<<EOF);
</CERIF>
EOF
    $fh->close();
}

sub usage {
    "usage: $0 [-d project_directory] file [outfile]";
}

