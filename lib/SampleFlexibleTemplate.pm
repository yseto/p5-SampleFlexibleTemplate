package SampleFlexibleTemplate;

use strict;
use warnings;
use utf8;

use Class::Accessor::Lite (
    new => 1,
    ro => [qw/modules segments container profile _profile rewrite_keyword cache_dir tx/]
);

use File::stat;
use File::Slurp;
use File::Spec::Functions;
use Text::Xslate;

use constant OPEN   => 0;
use constant CLOSE  => 1;

use constant PARSE      => 0;
use constant COMPILE    => 1;

sub add_module {
    my $self = shift;
    my $klass = shift;

    eval "require $klass";

    my $module = $klass->new;

    if ($module->type eq 'container') {
        push @{$self->{container}}, $module;
    } else {
        push @{$self->{modules}},   $module;
    }
}

sub get_profile {
    my $self = shift;
    return $self->{_profile} if $self->{_profile};
    my $module = $self->profile;
    eval "require $module";
    $self->{_profile} = $module->new;
}

sub is_container {
    my $self = shift;
    my $tag = shift;
    grep { $_->entity eq $tag } @{$self->{container}};
}

sub parse {
    my ($self, $text) = @_;
    $self->disassemble(PARSE, $text);
}

sub compile {
    my ($self, $text) = @_;
    $self->disassemble(COMPILE, $text);
}

sub convert_container {
    my ($self, $position, $tag, $args) = @_;
    my ($entity) = grep { $_->entity eq $tag } @{$self->{container}};

    my $p = $self->get_profile;
    unless ($entity) {
        my $prefix = $p->prefix;
        die "invalid: missing module <${prefix}${tag}>";
    }

    my $container = $position == OPEN ?
        'open_container' :
        'close_container';

    my $post_process_list = $p->post_process_list;
    my @disassemble_args = $p->disassemble_args($args);
    my @post_process  = grep { $post_process_list->{$_->[0]}  } @disassemble_args;
    my @function_args = grep { !$post_process_list->{$_->[0]} } @disassemble_args;

    my $main = $entity->$container($p->convert_args(@function_args));
    my $post = $p->post_process_filter($p->convert_args(@post_process));

    if (my $rewrite = $entity->can('rewrite_container')) {
        my $from_to = &$rewrite;
        if ($position == OPEN) {
            $self->{rewrite_keyword} = $from_to;
        }
        if ($position == CLOSE &&
            $self->{rewrite_keyword} &&
            $self->{rewrite_keyword}->[0] eq $from_to->[0]) {

            $self->{rewrite_keyword} = undef;
        }
    }
    return $p->start_bracket . $main . $post . $p->end_bracket;
}

sub convert_methods {
    my ($self, $tag, $args) = @_;
    my ($entity) = grep { $_->entity eq $tag } @{$self->{modules}};

    my $p = $self->get_profile;
    unless ($entity) {
        my $prefix = $p->prefix;
        die "invalid: missing module <${prefix}${tag}>";
    }

    my $post_process_list = $p->post_process_list;
    my @disassemble_args = $p->disassemble_args($args);
    my @post_process  = grep { $post_process_list->{$_->[0]}  } @disassemble_args;
    my @function_args = grep { !$post_process_list->{$_->[0]} } @disassemble_args;

    my $main = $entity->funcname($p->convert_args(@function_args));
    my $post = $p->post_process_filter($p->convert_args(@post_process));

    if ($self->{rewrite_keyword}) {
        my ($from, $to) = @{$self->{rewrite_keyword}};
        $main =~ s/\Q$from\E/$to/g;
    }

    return $p->start_bracket . $main . $post . $p->end_bracket;
}

sub disassemble {
    my ($self, $mode, $text) = @_;

    my $last_pos = 0;
    my @segments;
    my $prefix = $self->get_profile->prefix;
    while ($text =~ m/(<${prefix}(.*?)>)/g) {
        my $tag_all = $1;
        my ($tag, $args) = split /\s+/, $2, 2;
        my $len_head = length($tag_all);

        my $pos = pos($text) - $len_head;
        # put a "string" before tag.
        push @segments, substr $text, $last_pos, ($pos - $last_pos);

        if ($self->is_container($tag)) {
            my $tag_tail = "</${prefix}${tag}>";
            my $len_tail = length($tag_tail);
            if ($text =~ m|$tag_tail|g) {
                my $next_pos = pos($text);
                my $inner_text = substr $text, $pos, ($next_pos - $pos);
                my $head = substr $inner_text, 0,            $len_head;
                my $body = substr $inner_text, $len_head,    -1 * $len_tail;
                my $tail = substr $inner_text, -1 * $len_tail;
                # put a "container"
                push @segments, [
                    ($mode ? $self->convert_container(OPEN, $tag, $args) : $head),
                    $self->disassemble($mode, $body),
                    ($mode ? $self->convert_container(CLOSE, $tag) : $tail),
                ];
                $last_pos = pos($text);
            } else {
                die "invalid: No missing $tag_tail";
            }
        } else {
            my $content = substr $text, $pos, $len_head;
            # put a "tag"
            push @segments, ($mode ? $self->convert_methods($tag, $args) : $content);
            $last_pos = pos($text);
        }
    }
 
    # put a "string" endnd tag to EOT.
    if (length($text) - $last_pos > 0) {
        push @segments, substr $text, $last_pos;
    }
    return @segments;
}

sub render {
    my ($self, $filename, %vars) = @_;

    $self->{tx} //= Text::Xslate->new(
        type => 'text',
        line_start => undef,
        function => {
            post_process => sub {
                $self->get_profile->post_process(@_);
            }
        },
    );
    my $compiled_filename = $self->gen_cache($filename);
    $self->{tx}->render($compiled_filename, \%vars)
}

sub gen_cache {
    my ($self, $filename) = @_;

    my $mtime = stat($filename)->mtime;
    my $cache_filename = catfile($self->cache_dir, "$filename.cache");
    unless (-e $cache_filename && stat($cache_filename)->mtime == $mtime) {
        mkdir $self->cache_dir;
        my $template = read_file($filename);
        write_file($cache_filename, join("", _flat($self->compile($template))));
        utime $mtime, $mtime, $cache_filename;
    }

    return $cache_filename;
}

# https://stackoverflow.com/questions/5166662/perl-what-is-the-easiest-way-to-flatten-a-multidimensional-array
sub _flat {  # no prototype for this one to avoid warnings
    return map { ref eq 'ARRAY' ? _flat(@$_) : $_ } @_;
}

1;
