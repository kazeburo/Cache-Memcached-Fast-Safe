package Cache::Memcached::Fast::Safe;

use strict;
use warnings;
use Cache::Memcached::Fast 0.19;
use URI::Escape::XS qw/uri_escape/;
use Digest::SHA qw/sha1_hex/;
use parent qw/Cache::Memcached::Fast/;
use POSIX::AtFork;
use Scalar::Util qw/weaken/;

our $VERSION = '0.02';
our $SANITIZE_METHOD = sub {
    my $key = shift;
    $key = uri_escape($key,"\x00-\x20\x7f-\xff");
    if ( length $key > 200 ) {
        $key = sha1_hex($key);
    }
    $key;
};

sub new {
    my $class = shift;
    my %args = ref $_[0] ? %{$_[0]} : @_;
    my $mem = $class->SUPER::new(\%args);
    # fork safe
    my $mem2 = $mem;
    POSIX::AtFork->add_to_child(sub {
        eval { $mem2->disconnect_all };
    });
    weaken($mem2);
    $mem;
}

for my $method ( qw/set cas add replace append prepend incr decr delete/ ) {
    no strict 'refs';
    my $super = 'SUPER::'.$method;
    *{$method} = sub {
        my $self = shift;
        my $key = shift;
        $self->$super($SANITIZE_METHOD->($key), @_);
    };
}
for my $method (qw/set_multi  cas_multi add_multi replace_multi append_multi prepend_multi incr_multi decr_multi delete_multi/ ) {
    no strict 'refs';
    my $super = 'SUPER::'.$method;
    *{$method} = sub {
        my $self = shift;
        my @request = @_;
        my @request_keys;
        my %sanitized_keys;
        my @sanitized_request;
        for my $keyval (@request) {
            my $key;
            my $sanitized_key;
            my $sanitized_keyval;
            if ( ref $keyval ) {
                my @keyval = @$keyval;
                $key = shift @keyval;
                $sanitized_key = $SANITIZE_METHOD->($key);
                $sanitized_keyval = [$sanitized_key, @keyval];
            }
            else {
                $key = $keyval;
                $sanitized_key = $SANITIZE_METHOD->($key);
                $sanitized_keyval = $sanitized_key
            }
            $sanitized_keys{$sanitized_key} = $key;
            push @request_keys, $key;
            push @sanitized_request, $sanitized_keyval;
        }
        my $sanitized_result = $self->$super(@sanitized_request);
        my %result;
        for my $key ( keys %$sanitized_result ) {
            $result{$sanitized_keys{$key}} = $sanitized_result->{$key};
        }
        if ( wantarray ) {
            my @result;
            for my $key ( @request_keys ) {
                push @result, $result{$key};
            }
            return @result;
        }
        \%result;
    }
}

*remove = \&delete;

for my $method (qw/get gets/) {
    no strict 'refs';
    my $super = 'SUPER::'.$method;
    *{$method} = sub {
        my $self = shift;
        my $key = shift;
        $self->$super($SANITIZE_METHOD->($key));
    };
}
for my $method (qw/get_multi gets_multi/) {
    no strict 'refs';
    my $super = 'SUPER::'.$method;
    *{$method} = sub {
        my $self = shift;
        my @request;
        my %sanitized_keys;
        for my $key (@_) {
            my $sanitized_key = $SANITIZE_METHOD->($key);
            $sanitized_keys{$sanitized_key} = $key;
            push @request, $sanitized_key;
        }
        return {} if ! @request;
        my $sanitized_result = $self->$super(@request);
        my %result;
        for my $key ( keys %$sanitized_result ) {
            $result{$sanitized_keys{$key}} = $sanitized_result->{$key};
        }
        \%result;
    }
}


1;

__END__

=head1 NAME

Cache::Memcached::Fast::Safe - Cache::Memcached::Fast with sanitizing keys and fork-safe

=head1 SYNOPSIS

  use Cache::Memcached::Fast::Safe;
  
  my $memd = Cache::Memcached::Fast::Safe->new({
    servers => [..]
  });
  
  #This module supports all method that Cache::Memcached::Fast has.

=head1 DESCRIPTION

Cache::Memcached::Fast::Safe is subclass of L<Cache::Memcached::Fast>.
Cache::Memcached::Fast::Safe sanitizes all requested keys for against 
memcached injection problem. and call disconnect_all automatically after fork 
for fork-safe.

=head1 CUSTOMIZE Sanitizer

This module allow to change sanitizing behavior through $Cache::Memcached::Fast::Safe::SANITIZE_METHOD.
Default sanitizer is

  local $Cache::Memcached::Fast::Safe::SANITIZE_METHOD = sub {
      my $key = shift;
      $key = uri_escape($key,"\x00-\x20\x7f-\xff");
      if ( length $key > 200 ) {
          $key = sha1_hex($key);
      }
      $key;
  };

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Cache::Memcached::Fast>, L<http://gihyo.jp/dev/feature/01/memcached_advanced/0002> (Japanese)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
