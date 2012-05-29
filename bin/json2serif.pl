#!/usr/bin/env perl
#
# Biblio CERIF exporter
#
# Patrick Hochstenbach @ ugent dot be
# 2012-05-08
#
use Catmandu;
use IO::File;
use POSIX qw(strftime);

my $infile = shift;
die "usage: $0 file" unless -r $infile;

my $proj_dir = '/Users/hochsten/Dev/CERIF';
die "proj_dir($proj_dir) not found - please correct path in json2serif.pl" unless -d $proj_dir;

chdir $proj_dir;

cerif_process('output/cfResPubl-RES.xml','cfResPubl.tt');
cerif_process('output/cfResPublTitle-LANG.xml','cfResPublTitle.tt');
cerif_process('output/cfResPublSubtitle-LANG.xml','cfResPublSubtitle.tt');
cerif_process('output/cfResPublAbstr-LANG.xml','cfResPublAbstr.tt');
cerif_process('output/cfResPublKeyw-LANG.xml','cfResPublKeyw.tt');
cerif_process('output/cfPers_ResPubl-LINK.xml','cfPers_ResPubl.tt');
cerif_process('output/cfPers-CORE.xml','cfPers.tt');
cerif_process('output/cfPersName-ADD.xml','cfPersName.tt');
cerif_process('output/cfOrgUnit-CORE.xml','cfOrgUnit.tt');
cerif_process('output/cfOrgName-LANG.xml','cfOrgUnitName.tt');
cerif_process('output/cfPers_OrgUnit-LINK.xml','cfPers_OrgUnit.tt');

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
