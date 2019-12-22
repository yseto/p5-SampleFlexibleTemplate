package SampleFlexibleTemplate::Module::NextEntry;

use strict;
use warnings;
use utf8;
use parent qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(type => 'container');
__PACKAGE__->mk_classdata(entity => 'HaveNextEntry');

use Class::Accessor::Lite (
    new => 1,
);

sub open_container {
    my ($self, $args) = @_;
    'if ($entry.next) {';
}

sub close_container { '}' }

sub rewrite_container { ['$entry' => '$entry.next'] }

1;

