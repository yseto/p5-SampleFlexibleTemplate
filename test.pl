#!/usr/bin/env perl

use strict;
use warnings;
use lib "lib/";
use SampleFlexibleTemplate;

my $hoge = SampleFlexibleTemplate->new(profile => 'SampleFlexibleTemplate::Profile', cache_dir => "cache/");
$hoge->add_module('SampleFlexibleTemplate::Module::Blog');
$hoge->add_module('SampleFlexibleTemplate::Module::Entry');
$hoge->add_module('SampleFlexibleTemplate::Module::NextEntry');
$hoge->add_module('SampleFlexibleTemplate::Module::EntryTitle');
$hoge->add_module('SampleFlexibleTemplate::Module::EntryText');

package entry {
    sub new {
        my ($class, %attr) = @_;
        bless \%attr, $class;
    }
    sub title { shift->{title} }
    sub text { shift->{text} }
    sub next { shift->{next} }
}

my $entry2 = entry->new(title => "http://example.com/index?aaa=bbb&ccc=ddd", text => "body2....", next => undef);
my $entry1 = entry->new(title => "entry1", text => "body1....", next => $entry2);

package blog {
    sub new { bless {}, shift }
    sub entries {
        [ $entry1, $entry2 ]
    }
};

my $blog = blog->new;

my %vars = (
    blogs => sub { [ $blog, ] },
);
print $hoge->render("tx.txt", %vars);
print $hoge->render("tx.txt", %vars);
print $hoge->render("tx.txt", %vars);
print $hoge->render("tx.txt", %vars);

