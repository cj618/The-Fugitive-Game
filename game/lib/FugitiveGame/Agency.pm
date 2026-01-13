package FugitiveGame::Agency;
use strict;
use warnings;
use FugitiveGame::Util qw(rng_int clamp log_line);
use FugitiveGame::State;

sub apply_effects {
    my ($state, $effects) = @_;
    for my $agency (keys %{$effects || {}}) {
        next unless $state->{agencies}{$agency};
        for my $key (qw(pressure coordination delay)) {
            next unless defined $effects->{$agency}{$key};
            $state->{agencies}{$agency}{$key} += $effects->{$agency}{$key};
        }
    }
}

sub apply_slot {
    my ($state) = @_;
    my $stall = 0;
    my $spike = 0;

    for my $agency (values %{$state->{agencies} || {}}) {
        $agency->{pressure} = clamp($agency->{pressure}, 0, 100);
        $agency->{coordination} = clamp($agency->{coordination}, 0, 100);
        $agency->{delay} = clamp($agency->{delay}, 0, 100);

        if ($agency->{coordination} < 40) {
            my $roll = rng_int($state, 1, 100);
            if ($roll <= 15) {
                $stall = 1;
            } elsif ($roll >= 85) {
                $spike = 1;
            }
        }
    }

    my $pressure_sum = 0;
    my $delay_sum = 0;
    for my $agency (values %{$state->{agencies} || {}}) {
        $pressure_sum += $agency->{pressure} || 0;
        $delay_sum += $agency->{delay} || 0;
    }

    my $adjustment = int(($pressure_sum - $delay_sum) / 100);
    $adjustment = 0 if $adjustment < 0;

    if ($stall) {
        $adjustment = int($adjustment / 2);
        log_line($state, 'Agency friction: stall');
    }
    if ($spike) {
        $adjustment += 3;
        log_line($state, 'Agency friction: spike');
    }

    $state->{player}{meters}{law_pressure} += $adjustment if $adjustment;

    FugitiveGame::State::clamp_state($state);
    return { stall => $stall, spike => $spike };
}

1;
