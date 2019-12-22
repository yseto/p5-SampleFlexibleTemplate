package SampleFlexibleTemplate::Module::Entry;

use strict;
use warnings;
use utf8;
use parent qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(type => 'container');
__PACKAGE__->mk_classdata(entity => 'entries');

use Class::Accessor::Lite (
    new => 1,
);

sub open_container {
    my ($self, $args) = @_;
    sprintf 'for $blog.entries(%s) -> $entry {', ($args || "");
}

sub close_container { '}' }

1;
