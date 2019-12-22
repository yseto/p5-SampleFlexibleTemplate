package SampleFlexibleTemplate::Module::Blog;

use strict;
use warnings;
use utf8;
use parent qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(type => 'container');
__PACKAGE__->mk_classdata(entity => 'blog');

use Class::Accessor::Lite (
    new => 1,
);

sub open_container {
    my ($self, $args) = @_;
    sprintf 'for $blogs(%s) -> $blog {', ($args || "");
}

sub close_container { '}' }

1;
