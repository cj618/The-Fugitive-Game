package FugitiveGame::Util;
use strict;
use warnings;
use Time::Piece;
use File::Spec;
use Exporter 'import';

our @EXPORT_OK = qw(clamp timestamp rng_int log_line build_path);

sub clamp {
    my ($value, $min, $max) = @_;
    return $min if $value < $min;
    return $max if $value > $max;
    return $value;
}

sub timestamp {
    my $t = localtime;
    return $t->strftime('%Y%m%d_%H%M%S');
}

sub rng_int {
    my ($state, $min, $max) = @_;
    my $seed = $state->{player}{rng}{seed};
    $seed = (1103515245 * $seed + 12345) % 2147483648;
    $state->{player}{rng}{seed} = $seed;
    my $range = $max - $min + 1;
    return $min + ($seed % $range);
}

sub log_line {
    my ($state, $line) = @_;
    return unless $state->{log_file};
    open my $fh, '>>', $state->{log_file} or return;
    print {$fh} $line, "\n";
    close $fh;
}

sub build_path {
    return File::Spec->catfile(@_);
}

1;
