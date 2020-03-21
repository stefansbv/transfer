package App::Transfer::Plugin::row::copy_match_regex;

# ABSTRACT: move filtered with regex

use 5.010001;
use Moose;
use Regexp::Parser;
use namespace::autoclean;

with 'MooX::Log::Any';

sub copy_match_regex {
    my ( $self, $p ) = @_;
    my ($logstr, $text, $valid_regex, $field_src, $field_dst, $attrib)
        = @$p{qw(logstr value valid_regex field_src field_dst attributes)};
    return unless $text;
    my $parser = Regexp::Parser->new;
    if (! $parser->regex($valid_regex) ) {
        my $errmsg = $parser->errmsg;
        $self->log->error("Regexp error: $errmsg");
        return;
    }
    my $rx = $parser->qr;
    my ($extr) = $text =~ /${rx}/;
    my $r  = {};
    my $op = $attrib->{MOVE} ? 'move' : 'copy';
    $r->{$field_src} = $attrib->{MOVE} ? undef : $text;
    $r->{$field_dst} = $extr;
    return $r;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head2 copy_match_regex

Copy the content of the source field matched by the regex to the
destination field.

Example recipe configuration:

Transformation step (row):

  <step>
    type                = copy
    valid_regex         = "(\d{2})\-\d{3}"
    field_src           = field1
    method              = copy_match_regex
    field_dst           = field2
    attributes          = COPY | REPLACENULL
  </step>

=cut
