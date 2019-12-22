package SampleFlexibleTemplate::Module::EntryTitle;

use strict;
use warnings;
use utf8;
use parent qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(type => 'method');
__PACKAGE__->mk_classdata(entity => 'entryTitle');

use Class::Accessor::Lite (
    new => 1,
);

sub funcname {
    my $self = shift;
    my $args = shift;
    $args ? sprintf('$entry.title(%s)', $args) : '$entry.title';
}

1;
