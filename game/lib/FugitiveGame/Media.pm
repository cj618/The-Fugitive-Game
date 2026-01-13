package FugitiveGame::Media;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp rng_int);
use FugitiveGame::State;

sub update_media {
    my ($state) = @_;
    my $meters = $state->{player}{meters};
    my $media = $state->{media};

    my $pressure = $meters->{law_pressure} || 0;
    my $underground = $meters->{reputation_underground} || 0;
    my $media_rep = $meters->{reputation_media} || 0;

    $media->{momentum} += int(($pressure + $media_rep) / 40);
    $media->{accuracy} += int($underground / 50) - 1;
    $media->{demonization} += int($media_rep / 45);

    $media->{simplification} += int($media->{momentum} / 30) - int($media->{accuracy} / 60);
    $media->{feedback_loop} += int(($media->{simplification} + $media->{demonization}) / 50);

    my $feedback_boost = int(($media->{feedback_loop} || 0) / 20);
    $meters->{law_pressure} += $feedback_boost if $feedback_boost > 0;

    FugitiveGame::State::clamp_state($state);
}

sub pick_headlines {
    my ($state, $headlines) = @_;
    my $momentum = $state->{media}{momentum} || 0;
    my $max = $momentum >= 40 ? 2 : $momentum >= 20 ? 1 : 0;
    return [] if $max == 0;

    my @pool = grep { ($_->{act} || 1) == ($state->{story}{act} || 1) } @{$headlines || []};
    return [] unless @pool;

    my @picked;
    while (@picked < $max && @pool) {
        my $index = rng_int($state, 1, scalar(@pool)) - 1;
        push @picked, splice(@pool, $index, 1);
    }
    return \@picked;
}

1;
