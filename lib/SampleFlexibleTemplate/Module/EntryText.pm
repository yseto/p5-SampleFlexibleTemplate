package SampleFlexibleTemplate::Module::EntryText;

use strict;
use warnings;
use utf8;
use parent qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(type => 'method');
__PACKAGE__->mk_classdata(entity => 'entryText');

use Class::Accessor::Lite (
    new => 1,
);

sub funcname {
    my $self = shift;
    my $args = shift;
    $args ? sprintf('$entry.text(%s)', $args) : '$entry.text';
}

1;
