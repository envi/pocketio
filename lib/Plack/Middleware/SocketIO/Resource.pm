package Plack::Middleware::SocketIO::Resource;

use strict;
use warnings;

use Plack::Request;
use Plack::Middleware::SocketIO::Connection;
use Plack::Middleware::SocketIO::Handle;

use Plack::Middleware::SocketIO::JSONPPolling;
use Plack::Middleware::SocketIO::WebSocket;
use Plack::Middleware::SocketIO::XHRMultipart;
use Plack::Middleware::SocketIO::XHRPolling;

sub instance {
    my $class = shift;

    no strict;

    ${"$class\::_instance"} ||= $class->_new_instance(@_);

    return ${"$class\::_instance"};
}

sub _new_instance {
    my $class = shift;

    my $self = bless {@_}, $class;

    $self->{connections} = {};

    return $self;
}

sub connection {
    my $self = shift;
    my ($id) = @_;

    return $self->{connections}->{$id};
}

sub add_connection {
    my $self = shift;

    my $conn = $self->_build_connection(@_);

    $self->{connections}->{$conn->id} = $conn;

    return $conn;
}

sub finalize {
    my $self = shift;
    my ($env, $cb) = @_;

    my ($resource, $type) = $env->{PATH_INFO} =~ m{^/([^\/]+)/([^\/]+)/?};
    return unless $resource && $type;

    my $transport = $self->_build_transport($type, resource => $resource);
    return unless $transport;

    my $req = Plack::Request->new($env);

    return $transport->finalize($req, $cb);
}

sub _build_transport {
    my $self = shift;
    my ($type, @args) = @_;

    my $class;
    if ($type eq 'xhr-multipart') {
        $class = 'XHRMultipart';
    }
    elsif ($type eq 'xhr-polling') {
        $class = 'XHRPolling';
    }
    elsif ($type eq 'jsonp-polling') {
        $class = 'JSONPPolling';
    }
    elsif ($type =~ m/^(?:flash|web)socket$/) {
        $class = 'WebSocket';
    }

    return unless $class;

    $class = "Plack::Middleware::SocketIO::$class";

    return $class->new(@args);
}

sub _build_connection {
    my $self = shift;

    return Plack::Middleware::SocketIO::Connection->new(@_);
}

1;