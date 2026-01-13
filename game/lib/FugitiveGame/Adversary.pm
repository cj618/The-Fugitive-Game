package FugitiveGame::Adversary;
use strict;
use warnings;
use FugitiveGame::State;

sub escalate {
    my ($state) = @_;
    my $meters = $state->{player}{meters};
    my $adversary = $state->{adversary};
    my $media = $state->{media};

    $adversary->{awareness} += int($meters->{reputation_underground} / 20);
    $adversary->{pattern_knowledge} += int($meters->{law_pressure} / 25);
    $adversary->{resource_commitment} += int($meters->{reputation_media} / 30);
    $adversary->{technical_focus} += int($meters->{stress} / 30);

    $media->{momentum} += int($meters->{reputation_media} / 20);
    $media->{demonization} += int($meters->{reputation_media} / 30);
    $media->{accuracy} += int($meters->{reputation_underground} / 40) - 1;

    if ($state->{player}{flags}{exposure_event}) {
        $adversary->{awareness} += 8;
        $adversary->{pattern_knowledge} += 6;
        $media->{momentum} += 4;
        $media->{demonization} += 5;
    }

    if ($state->{player}{flags}{lie_low}) {
        $adversary->{pattern_knowledge} -= 2;
        $meters->{isolation} += 3;
    }

    $meters->{law_pressure} = int(($adversary->{awareness} + $adversary->{pattern_knowledge} + $media->{momentum}) / 3);

    FugitiveGame::State::clamp_state($state);
}

1;
