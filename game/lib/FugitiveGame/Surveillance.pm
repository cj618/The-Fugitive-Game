package FugitiveGame::Surveillance;
use strict;
use warnings;
use FugitiveGame::Util qw(rng_int clamp);
use FugitiveGame::State;

sub generate_signal {
    my ($state, $context) = @_;
    my $meters = $state->{player}{meters};
    my $surv = $state->{surveillance};

    my $stress = $meters->{stress} || 0;
    my $isolation = $meters->{isolation} || 0;
    my $paranoia = $surv->{paranoia} || $meters->{paranoia} || 0;

    my $false_bias = $surv->{false_positive_bias} || 0;
    my $false_chance = clamp(10 + int(($stress + $isolation + $paranoia) / 6) + $false_bias, 5, 90);
    my $roll = rng_int($state, 1, 100);

    my $truth = $roll > $false_chance;
    my $signal_type = $truth ? 'real_trace' : 'tap_like';
    $surv->{last_tap_signal_day} = $state->{player}{day};

    if (!$truth) {
        $surv->{paranoia} = clamp(($surv->{paranoia} || 0) + 3, 0, 100);
        $meters->{paranoia} = $surv->{paranoia};
    }

    FugitiveGame::State::clamp_state($state);

    return {
        signal_type => $signal_type,
        truth => $truth,
        recommended => $truth ? ['lie_low', 'move_location'] : ['check_anomalies', 'lie_low'],
    };
}

1;
