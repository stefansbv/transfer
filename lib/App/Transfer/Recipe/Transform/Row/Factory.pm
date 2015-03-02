package App::Transfer::Recipe::Transform::Row::Factory;

# ABSTRACT: Row step factory

use MooseX::AbstractFactory;

implementation_class_via
    sub { 'App::Transfer::Recipe::Transform::Row::' . ucfirst shift };

1;
