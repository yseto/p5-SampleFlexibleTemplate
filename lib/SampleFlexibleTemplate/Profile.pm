package SampleFlexibleTemplate::Profile;

use strict;
use warnings;
use utf8;

sub new { bless {}, shift; }

sub prefix { 'MODULE:' }

sub start_bracket { '<: ' }
sub end_bracket { ' :>' }

sub disassemble_args {
    my $self = shift;
    my $args_string = shift;

    return unless $args_string;

    my @args;
    while ($args_string =~ m/(\w+)="(.*?)"/g) {
        push @args, [$1, $2];
    }
    return @args;
}

sub convert_args {
    my $self = shift;
    my @disassemble_args = @_;

    join(", ", map { sprintf('%s => "%s"', $_->[0], $_->[1]) } @disassemble_args);
}

sub post_process_list {
    my @functions = qw/
        encode_html
        uri_escape
    /;
    my %hash = map { $_ => 1 } @functions;
    \%hash;
}

use URI::Escape ();
sub uri_escape {
    URI::Escape::uri_escape(shift);
}

use HTML::Entities;
sub encode_html {
    decode_entities(shift);
}

sub post_process_filter {
    my ($self, $args) = @_;   
    return "" unless $args;
    sprintf " | post_process(%s)", $args;
}

sub post_process {
    my ($self, @args) = @_;
    return sub {
        my ($str) = @_;
        while (my ($k, $v) = splice @args, 0, 2) {
            if (my $f = $self->can($k)) {
                $str = $f->($str);
            }
        }
        return $str;
    }
}

1;
